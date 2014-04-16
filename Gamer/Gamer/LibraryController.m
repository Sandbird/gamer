//
//  LibraryController.m
//  Gamer
//
//  Created by Caio Mello on 24/07/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "LibraryController.h"
#import "LibraryCollectionCell.h"
#import "Game.h"
#import "Platform.h"
#import "Genre.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "SimilarGame.h"
#import "Region.h"
#import "Release.h"
#import "GameController.h"
#import "HeaderCollectionReusableView.h"
#import <AFNetworking/AFNetworking.h>
#import "SearchController_iPad.h"
#import "LibraryFilterView.h"
#import "Platform+Library.h"

typedef NS_ENUM(NSInteger, LibraryFilter){
	LibraryFilterTitle,
	LibraryFilterPlatform,
	LibraryFilterReleaseYear,
	LibraryFilterMetascore
};

@interface LibraryController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIActionSheetDelegate, LibraryFilterViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *refreshBarButton;
@property (nonatomic, strong) UIBarButtonItem *searchBarItem;

@property (nonatomic, strong) UIBarButtonItem *sortBarButton;
@property (nonatomic, strong) UIBarButtonItem *filterBarButton;
@property (nonatomic, strong) UIBarButtonItem *cancelBarButton;

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, strong) LibraryFilterView *filterView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, assign) LibraryFilter filter;

@property (nonatomic, strong) NSCache *imageCache;

@property (nonatomic, assign) NSInteger numberOfRunningTasks;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation LibraryController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	// UI setup
	if ([Tools deviceIsiPad]){
		_refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshLibraryGames)];
		
		UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 256, 44)];
		[searchBar setPlaceholder:@"Find Games"];
		[searchBar setDelegate:self];
		_searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
		
		[self.navigationItem setRightBarButtonItems:@[_searchBarItem, _refreshBarButton] animated:NO];
		
		_sortBarButton = [[UIBarButtonItem alloc] initWithTitle:@"   Sort  " style:UIBarButtonItemStylePlain target:self action:@selector(showSortOptions)];
		_filterBarButton = [[UIBarButtonItem alloc] initWithTitle:@"      Filter     " style:UIBarButtonItemStylePlain target:self action:@selector(showFilterOptions)];
		_cancelBarButton = [[UIBarButtonItem alloc] initWithTitle:@"    Cancel   " style:UIBarButtonItemStylePlain target:self action:@selector(cancelBarButtonAction)];
		
		[self.navigationItem setLeftBarButtonItems:@[_sortBarButton, _filterBarButton] animated:NO];
	}
	else{
		UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, -50, 0, 0)];
		[_collectionView addSubview:refreshView];
		
		_refreshControl = [UIRefreshControl new];
		[_refreshControl setTintColor:[UIColor lightGrayColor]];
		[_refreshControl addTarget:self action:@selector(refreshLibraryGames) forControlEvents:UIControlEventValueChanged];
		[refreshView addSubview:_refreshControl];
		
		_filterView = [[LibraryFilterView alloc] initWithFrame:CGRectMake(0, -50, 320, 50)];
		[_filterView setDelegate:self];
		[_collectionView addSubview:_filterView];
		
		[_collectionView setContentInset:UIEdgeInsetsMake(50, 0, 0, 0)];
	}
	
	// Other stuff
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLibraryNotification:) name:@"RefreshLibrary" object:nil];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	_filter = LibraryFilterPlatform;
	
	[self loadDataSource];
	
	_imageCache = [NSCache new];
	
	_guideView = [[NSBundle mainBundle] loadNibNamed:[Tools deviceIsiPad] ? @"iPad" : @"iPhone" owner:self options:nil][1];
	[self.view insertSubview:_guideView aboveSubview:_collectionView];
	[_guideView setFrame:self.view.frame];
	[_guideView setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated{
	if ([Tools deviceIsiPad])
		[(UISearchBar *)_searchBarItem.customView setText:[Session searchQuery]];
}

- (void)viewDidAppear:(BOOL)animated{
	[_refreshControl endRefreshing];
}

- (void)viewDidLayoutSubviews{
	if ([Tools deviceIsiPad])
		[_guideView setCenter:self.view.center];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - SearchBar

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
	SearchController_iPad *searchViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SearchViewController"];
	[self.navigationController pushViewController:searchViewController animated:NO];
	return NO;
}

#pragma mark - CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
	[_guideView setHidden:([Game MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"location = %@", @(GameLocationLibrary)]] == 0) ? NO : YES];
	
	return _dataSource.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
//	NSString *sectionName = [_fetchedResultsController.sections[indexPath.section] name];
//	
//	Game *game = [_fetchedResultsController objectAtIndexPath:indexPath];
//	
//	NSString *headerTitle;
//	
//	switch (_filter) {
//		case LibraryFilterTitle: headerTitle = sectionName; break;
//		case LibraryFilterPlatform: headerTitle = game.libraryPlatform.name; break;
//		case LibraryFilterReleaseYear: headerTitle = game.releaseDate.year.stringValue; break;
//		case LibraryFilterMetascore: headerTitle = game.metascore.length > 0 ? game.metascore : @"Unavailable"; break;
//		default: break;
//	}
//	
//	if ([headerTitle isEqualToString:@"2050"])
//		headerTitle = @"Unknown";
//
	
	HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
	[headerView.titleLabel setText:_dataSource[indexPath.section][@"platform"][@"name"]];
	[headerView.separator setHidden:indexPath.section == 0 ? YES : NO];
	return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [_dataSource[section][@"platform"][@"games"] count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
	switch ([Session gamer].librarySize.integerValue) {
		case LibrarySizeSmall: return [Tools deviceIsiPhone] ? CGSizeMake(40, 50) : CGSizeMake(83, 91);
		case LibrarySizeMedium: return [Tools deviceIsiPhone] ? CGSizeMake(50, 63) : CGSizeMake(115, 127);
		case LibrarySizeLarge: return [Tools deviceIsiPhone] ? CGSizeMake(66, 83) : CGSizeMake(140, 176);
		default: return CGSizeZero;
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = _dataSource[indexPath.section][@"platform"][@"games"][indexPath.row];
	
	LibraryCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.coverImageView setBackgroundColor:[UIColor darkGrayColor]];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		UIImage *image = [_imageCache objectForKey:game.imagePath.lastPathComponent];
		
		if (image){
			dispatch_async(dispatch_get_main_queue(), ^{
				[cell.coverImageView setImage:image];
				[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
			});
		}
		else{
			dispatch_async(dispatch_get_main_queue(), ^{
				[cell.coverImageView setImage:nil];
				[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
			});
			
			UIImage *image = [UIImage imageWithContentsOfFile:game.imagePath];
			
			CGSize cellSize = [Tools deviceIsiPhone] ? CGSizeMake(66, 83) : CGSizeMake(140, 176);
			
			CGSize imageSize = image.size.width > image.size.height ? [Tools sizeOfImage:image aspectFitToWidth:cellSize.width] : [Tools sizeOfImage:image aspectFitToHeight:cellSize.height];
			
			UIGraphicsBeginImageContext(imageSize);
			[image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
			image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[cell.coverImageView setImage:image];
				[cell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
			});
			
			if (image){
				[_imageCache setObject:image forKey:game.imagePath.lastPathComponent];
			}
		}
	});
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:indexPath];
}

#pragma mark - Networking

- (void)requestGame:(Game *)game{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes,releases"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Game", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			_numberOfRunningTasks--;
			
			if (_numberOfRunningTasks == 0){
				[_refreshBarButton setEnabled:YES];
				[_refreshControl endRefreshing];
			}
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Game - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			_numberOfRunningTasks--;
			
			[Networking updateGame:game withDataFromJSON:responseObject context:_context];
			
			if (responseObject[@"results"] != [NSNull null]){
				NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
				
				UIImage *coverImage = [UIImage imageWithContentsOfFile:game.imagePath];
				
				if (!coverImage || !game.imagePath || ![game.imageURL isEqualToString:coverImageURL]){
					[self downloadCoverImageWithURL:coverImageURL game:game];
				}
			}
			
			for (Release *release in game.releases){
				[self requestRelease:release];
			}
			
			if (_numberOfRunningTasks == 0){
				[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					[_refreshBarButton setEnabled:YES];
					[_refreshControl endRefreshing];
					[_collectionView reloadData];
				}];
			}
		}
	}];
	[dataTask resume];
	_numberOfRunningTasks++;
}

- (void)downloadCoverImageWithURL:(NSString *)URLString game:(Game *)game{
	if (!URLString) return;
	
	NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
	
	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [Tools imagesDirectory], request.URL.lastPathComponent]];
		return fileURL;
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Cover Image", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Cover Image - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			[game setImagePath:[NSString stringWithFormat:@"%@/%@", [Tools imagesDirectory], request.URL.lastPathComponent]];
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[_collectionView reloadData];
			}];
		}
	}];
	[downloadTask resume];
}

- (void)requestRelease:(Release *)release{
	NSURLRequest *request = [Networking requestForReleaseWithIdentifier:release.identifier fields:@"platform,region,release_date,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Release", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Release - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			//			NSLog(@"%@", responseObject);
			
			NSDictionary *results = responseObject[@"results"];
			
			Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:results[@"platform"][@"id"] inContext:_context];
			
			if (platform){
				[release setPlatform:platform];
				[release setRegion:[Region MR_findFirstByAttribute:@"identifier" withValue:results[@"region"][@"id"] inContext:_context]];
				
				NSString *releaseDate = [Tools stringFromSourceIfNotNull:results[@"release_date"]];
				NSInteger expectedReleaseDay = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_day"]].integerValue;
				NSInteger expectedReleaseMonth = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_month"]].integerValue;
				NSInteger expectedReleaseQuarter = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_quarter"]].integerValue;
				NSInteger expectedReleaseYear = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_year"]].integerValue;
				
				[Networking setReleaseDateForGameOrRelease:release dateString:releaseDate expectedReleaseDay:expectedReleaseDay expectedReleaseMonth:expectedReleaseMonth expectedReleaseQuarter:expectedReleaseQuarter expectedReleaseYear:expectedReleaseYear];
				
				if (results[@"image"] != [NSNull null])
					[release setImageURL:[Tools stringFromSourceIfNotNull:results[@"image"][@"thumb_url"]]];
			}
			else{
				[release MR_deleteInContext:_context];
			}
		}
	}];
	[dataTask resume];
}

#pragma mark - LibraryFilterView

- (void)libraryFilterView:(LibraryFilterView *)filterView didPressSortButton:(UIButton *)button{
	[self showSortOptions];
}

- (void)libraryFilterView:(LibraryFilterView *)filterView didPressFilterButton:(UIButton *)button{
	[self showFilterOptions];
}

- (void)libraryFilterView:(LibraryFilterView *)filterView didPressCancelButton:(UIButton *)button{
	[_filterView resetAnimated:YES];
	
	_filter = LibraryFilterPlatform;
	
//	_fetchedResultsController = nil;
//	_fetchedResultsController = [Game MR_fetchAllGroupedBy:nil withPredicate:[NSPredicate predicateWithFormat:@"location = %@", @(GameLocationLibrary)] sortedBy:@"title" ascending:YES inContext:_context];
//	[_collectionView reloadData];
}

#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex){
		if (actionSheet.tag == 1){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"location = %@", @(GameLocationLibrary)];
			
			// Sort
			switch (buttonIndex) {
				case 0:
					// Title
					[self fetchGamesWithFilter:LibraryFilterTitle group:@"title.stringGroupByFirstInitial" predicate:predicate sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Sorted by title" animated:YES];
					break;
				case 1:
					// Year of release
					[self fetchGamesWithFilter:LibraryFilterReleaseYear group:@"releaseDate.year" predicate:predicate sort:@"releaseDate.year,title" ascending:NO];
					[_filterView showStatusWithTitle:@"Sorted by year of release" animated:YES];
					break;
				case 2:
					// Metascore
					[self fetchGamesWithFilter:LibraryFilterMetascore group:@"metascore" predicate:predicate sort:@"metascore,title" ascending:NO];
					[_filterView showStatusWithTitle:@"Sorted by Metascore" animated:YES];
					break;
				default: break;
			}
		}
		else{
			// Filter
			switch (buttonIndex) {
				case 0:
					// Finished
					[self fetchGamesWithFilter:LibraryFilterPlatform group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND finished = %@", @(GameLocationLibrary), @(YES)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing finished games" animated:YES];
					break;
				case 1:
					// Unfinished
					[self fetchGamesWithFilter:LibraryFilterPlatform group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND finished = %@", @(GameLocationLibrary), @(NO)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing unfinished games" animated:YES];
					break;
				case 2:
					// Digital
					[self fetchGamesWithFilter:LibraryFilterPlatform group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND digital = %@", @(GameLocationLibrary), @(YES)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing digital games" animated:YES];
					break;
				case 3:
					// Retail
					[self fetchGamesWithFilter:LibraryFilterPlatform group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND digital = %@", @(GameLocationLibrary), @(NO)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing retail games" animated:YES];
					break;
				case 4:
					// Lent
					[self fetchGamesWithFilter:LibraryFilterPlatform group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND lent = %@", @(GameLocationLibrary), @(YES)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing lent games" animated:YES];
					break;
				default: break;
			}
		}
		
		if ([Tools deviceIsiPad]){
			[self.navigationItem setLeftBarButtonItems:@[_sortBarButton, _filterBarButton, _cancelBarButton] animated:YES];
		}
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[_filterView.sortButton setHighlighted:NO];
		[_filterView.filterButton setHighlighted:NO];
	});

	[self.navigationController.navigationBar setUserInteractionEnabled:YES];
}

#pragma mark - Custom

- (void)loadDataSource{
	_dataSource = [[NSMutableArray alloc] initWithCapacity:[Session gamer].platforms.count];
	
	NSArray *platforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self IN %@", [Session gamer].platforms] inContext:_context];
	
	for (Platform *platform in platforms){
		if (platform.containsLibraryGames){
			NSArray *games = platform.sortedLibraryGames;
			
			[_dataSource addObject:@{@"platform":@{@"id":platform.identifier,
												   @"name":platform.name,
												   @"games":games}}];
			
			// Cache images
//			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//				for (Game *game in games){
//					UIImage *image = [UIImage imageWithContentsOfFile:game.imagePath];
//					
//					CGSize cellSize = [Tools deviceIsiPhone] ? CGSizeMake(66, 83) : CGSizeMake(140, 176);
//					
//					CGSize imageSize = image.size.width > image.size.height ? [Tools sizeOfImage:image aspectFitToWidth:cellSize.width] : [Tools sizeOfImage:image aspectFitToHeight:cellSize.height];
//					
//					UIGraphicsBeginImageContext(imageSize);
//					[image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
//					image = UIGraphicsGetImageFromCurrentImageContext();
//					UIGraphicsEndImageContext();
//					
//					if (image){
//						[_imageCache setObject:image forKey:game.imagePath.lastPathComponent];
//					}
//				}
//			});
		}
	}
}

- (void)fetchGamesWithFilter:(LibraryFilter)filter group:(NSString *)group predicate:(NSPredicate *)predicate sort:(NSString *)sort ascending:(BOOL)ascending{
	_filter = filter;
	
//	_fetchedResultsController = nil;
//	_fetchedResultsController = [Game MR_fetchAllGroupedBy:group withPredicate:predicate sortedBy:sort ascending:ascending inContext:_context];
//	[_collectionView reloadData];
}

- (void)refreshLibraryGames{
//	if (_fetchedResultsController.fetchedObjects.count > 0){
//		[_refreshBarButton setEnabled:NO];
//	}
	
	_numberOfRunningTasks = 0;
	
	// Request info for all games in the Wishlist
	for (NSDictionary *dictionary in _dataSource){
		for (Game *game in dictionary[@"platform"][@"games"]){
			[self requestGame:game];
		}
	}
}

- (void)showSortOptions{
	UIActionSheet *actionSheet;
	
	actionSheet = [[UIActionSheet alloc] initWithTitle:@"Sort by" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Title", @"Year of Release", @"Metascore", nil];
	[actionSheet setTag:1];
	
	if ([Tools deviceIsiPhone])
		[actionSheet showInView:self.view.window];
	else
		[actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItems.firstObject animated:YES];
	
	[self.navigationController.navigationBar setUserInteractionEnabled:NO];
}

- (void)showFilterOptions{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Show only" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Finished", @"Unfinished", @"Digital", @"Retail", @"Lent", nil];
	[actionSheet setTag:2];
	
	if ([Tools deviceIsiPhone])
		[actionSheet showInView:self.view.window];
	else
		[actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItems[1] animated:YES];
	
	[self.navigationController.navigationBar setUserInteractionEnabled:NO];
}

#pragma mark - Actions

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[self refreshLibraryGames];
}

- (void)cancelBarButtonAction{
	[self.navigationItem setLeftBarButtonItems:@[_sortBarButton, _filterBarButton] animated:YES];
	
	_filter = LibraryFilterPlatform;
	
	[self loadDataSource];
	[_collectionView reloadData];
}

- (void)coverImageDownloadedNotification:(NSNotification *)notification{
	[_collectionView reloadData];
}

- (void)refreshLibraryNotification:(NSNotification *)notification{
	if ([Tools deviceIsiPad]){
		[self.navigationItem setLeftBarButtonItems:@[_sortBarButton, _filterBarButton] animated:NO];
	}
	
	[_filterView resetAnimated:YES];
	
	_filter = LibraryFilterPlatform;
	
	[self loadDataSource];
	[_collectionView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	NSIndexPath *indexPath = sender;
	Game *game = _dataSource[indexPath.section][@"platform"][@"games"][indexPath.row];
	
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		if ([Tools deviceIsiPad]){
			UINavigationController *navigationController = segue.destinationViewController;
			GameController *destination = (GameController *)navigationController.topViewController;
			[destination setGame:game];
		}
		else{
			// Pop other tabs when opening game details
			for (UIViewController *viewController in self.tabBarController.viewControllers){
				[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
			}
			
			GameController *destination = segue.destinationViewController;
			[destination setGame:game];
		}
	}
}

@end
