//
//  LibraryController.m
//  Gamer
//
//  Created by Caio Mello on 24/07/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
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
#import "Metascore.h"
#import "GameController.h"
#import "HeaderCollectionReusableView.h"
#import <AFNetworking/AFNetworking.h>
#import "SearchController_iPad.h"
#import "LibrarySortFilterView.h"
#import "Platform+Library.h"

typedef NS_ENUM(NSInteger, LibrarySort){
	LibrarySortTitle,
	LibrarySortReleaseYear,
	LibrarySortRating,
//	LibrarySortMetascore,
	LibrarySortPlatform
};

typedef NS_ENUM(NSInteger, LibraryFilter){
	LibraryFilterFinished,
	LibraryFilterUnfinished,
	LibraryFilterRetail,
	LibraryFilterDigital,
	LibraryFilterLent,
	LibraryFilterBorrowed,
	LibraryFilterNone
};

@interface LibraryController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIActionSheetDelegate, LibrarySortFilterViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *refreshBarButton;
@property (nonatomic, strong) UIBarButtonItem *searchBarItem;

@property (nonatomic, strong) UIBarButtonItem *sortBarButton;
@property (nonatomic, strong) UIBarButtonItem *filterBarButton;
@property (nonatomic, strong) UIBarButtonItem *cancelBarButton;

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, strong) LibrarySortFilterView *filterView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong) NSFetchedResultsController *sortFilterDataSource;

@property (nonatomic, assign) NSInteger sortOrFilter;

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
		
		_filterView = [[LibrarySortFilterView alloc] initWithFrame:CGRectMake(0, -50, 320, 50)];
		[_filterView setDelegate:self];
		[_collectionView addSubview:_filterView];
		
		[_collectionView setContentInset:UIEdgeInsetsMake(50, 0, 0, 0)];
	}
	
	// Other stuff
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLibraryNotification:) name:@"RefreshLibrary" object:nil];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	_sortOrFilter = LibrarySortPlatform;
	
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
	
	return (_sortOrFilter == LibrarySortPlatform) ? _dataSource.count : _sortFilterDataSource.sections.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
	if (_sortOrFilter == LibrarySortPlatform){
		HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
		[headerView.titleLabel setText:_dataSource[indexPath.section][@"platform"][@"name"]];
		[headerView.separator setHidden:indexPath.section == 0 ? YES : NO];
		return headerView;
	}
	else{
		
		NSString *sectionName = [_sortFilterDataSource.sections[indexPath.section] name];
		
		Game *game = [_sortFilterDataSource objectAtIndexPath:indexPath];
		
		NSString *headerTitle;
		
		switch (_sortOrFilter) {
			case LibrarySortTitle: headerTitle = sectionName; break;
			case LibrarySortReleaseYear: headerTitle = game.releaseYear.stringValue; break;
			case LibrarySortRating:{
				switch (game.personalRating.integerValue) {
					case 5: headerTitle = @"★★★★★"; break;
					case 4: headerTitle = @"★★★★"; break;
					case 3: headerTitle = @"★★★"; break;
					case 2: headerTitle = @"★★"; break;
					case 1: headerTitle = @"★"; break;
					case 0: headerTitle = @"No Rating"; break;
					default: break;
				}
				break;
			}
//			case LibrarySortMetascore: headerTitle = game.metascore.length > 0 ? game.metascore : @"Unavailable"; break;
			default: break;
		}
		
		if ([headerTitle isEqualToString:@"2050"])
			headerTitle = @"Unknown";
		
		HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
		[headerView.titleLabel setText:headerTitle];
		[headerView.separator setHidden:indexPath.section == 0 ? YES : NO];
		return headerView;
	}
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return (_sortOrFilter == LibrarySortPlatform) ? [_dataSource[section][@"platform"][@"games"] count] : [_sortFilterDataSource.sections[section] numberOfObjects];
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
	Game *game = (_sortOrFilter == LibrarySortPlatform) ? _dataSource[indexPath.section][@"platform"][@"games"][indexPath.row] : [_sortFilterDataSource objectAtIndexPath:indexPath];
	
	LibraryCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.coverImageView setBackgroundColor:[UIColor darkGrayColor]];
	
	UIImage *image = [_imageCache objectForKey:game.imagePath.lastPathComponent];
	
	if (image){
		[cell.coverImageView setImage:image];
		[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
	}
	else{
		[cell.coverImageView setImage:nil];
		[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
			
		});
	}
	
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

#pragma mark - LibrarySortFilterView

- (void)librarySortFilterView:(LibrarySortFilterView *)filterView didPressSortButton:(UIButton *)button{
	[self showSortOptions];
}

- (void)librarySortFilterView:(LibrarySortFilterView *)filterView didPressFilterButton:(UIButton *)button{
	[self showFilterOptions];
}

- (void)librarySortFilterView:(LibrarySortFilterView *)filterView didPressCancelButton:(UIButton *)button{
	[_filterView resetAnimated:YES];
	
	_sortOrFilter = LibrarySortPlatform;
	
	_sortFilterDataSource = nil;
//	_sortFilterDataSource = [Game MR_fetchAllGroupedBy:nil withPredicate:[NSPredicate predicateWithFormat:@"location = %@", @(GameLocationLibrary)] sortedBy:@"title" ascending:YES inContext:_context];
	[_collectionView reloadData];
}

#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex){
		if (actionSheet.tag == 1){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"location = %@", @(GameLocationLibrary)];
			
			// Sort
			switch (buttonIndex) {
				case LibrarySortTitle:
					[self fetchGameswithSortOrFilter:LibrarySortTitle group:@"title.stringGroupByFirstInitial" predicate:predicate sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Sorted by title" animated:YES];
					break;
				case LibrarySortReleaseYear:
					[self fetchGameswithSortOrFilter:LibrarySortReleaseYear group:@"releaseYear" predicate:predicate sort:@"releaseYear,title" ascending:NO];
					[_filterView showStatusWithTitle:@"Sorted by year of release" animated:YES];
					break;
				case LibrarySortRating:
					[self fetchGameswithSortOrFilter:LibrarySortRating group:@"personalRating" predicate:predicate sort:@"personalRating,title" ascending:NO];
					[_filterView showStatusWithTitle:@"Sorted by rating" animated:YES];
					break;
//				case LibrarySortMetascore:
//					[self fetchGameswithSortOrFilter:LibrarySortMetascore group:@"metascore" predicate:predicate sort:@"metascore,title" ascending:NO];
//					[_filterView showStatusWithTitle:@"Sorted by Metascore" animated:YES];
//					break;
				default:
					break;
			}
		}
		else{
			// Filter
			switch (buttonIndex) {
				case LibraryFilterFinished:
					[self fetchGameswithSortOrFilter:LibraryFilterNone group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND finished = %@", @(GameLocationLibrary), @(YES)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing finished games" animated:YES];
					break;
				case LibraryFilterUnfinished:
					[self fetchGameswithSortOrFilter:LibraryFilterNone group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND finished = %@", @(GameLocationLibrary), @(NO)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing unfinished games" animated:YES];
					break;
				case LibraryFilterRetail:
					[self fetchGameswithSortOrFilter:LibraryFilterNone group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND digital = %@", @(GameLocationLibrary), @(NO)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing retail games" animated:YES];
					break;
				case LibraryFilterDigital:
					[self fetchGameswithSortOrFilter:LibraryFilterNone group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND digital = %@", @(GameLocationLibrary), @(YES)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing digital games" animated:YES];
					break;
				case LibraryFilterLent:
					[self fetchGameswithSortOrFilter:LibraryFilterNone group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND lent = %@", @(GameLocationLibrary), @(YES)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing lent games" animated:YES];
					break;
				case LibraryFilterBorrowed:
					[self fetchGameswithSortOrFilter:LibraryFilterNone group:nil predicate:[NSPredicate predicateWithFormat:@"location = %@ AND borrowed = %@", @(GameLocationLibrary), @(YES)] sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing borrowed games" animated:YES];
					break;
				default:
					break;
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
	
	NSArray *platforms = [Platform MR_findAllSortedBy:@"group,index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self IN %@", [Session gamer].platforms] inContext:_context];
	
	for (Platform *platform in platforms){
		if (platform.containsLibraryGames){
			NSArray *games = platform.sortedLibraryGames;
			
			[_dataSource addObject:@{@"platform":@{@"id":platform.identifier,
												   @"name":platform.name,
												   @"games":games}}];
		}
	}
	
	// Cache images
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		for (NSDictionary *dictionary in _dataSource){
			for (Game *game in dictionary[@"platform"][@"games"]){
				UIImage *image = [UIImage imageWithContentsOfFile:game.imagePath];
				
				CGSize cellSize = [Tools deviceIsiPhone] ? CGSizeMake(66, 83) : CGSizeMake(140, 176);
				
				CGSize imageSize = image.size.width > image.size.height ? [Tools sizeOfImage:image aspectFitToWidth:cellSize.width] : [Tools sizeOfImage:image aspectFitToHeight:cellSize.height];
				
				UIGraphicsBeginImageContext(imageSize);
				[image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
				image = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();
				
				if (image){
					[_imageCache setObject:image forKey:game.imagePath.lastPathComponent];
				}
			}
		}
	});
}

- (void)fetchGameswithSortOrFilter:(NSInteger)filter group:(NSString *)group predicate:(NSPredicate *)predicate sort:(NSString *)sort ascending:(BOOL)ascending{
	_sortOrFilter = filter;
	
	_sortFilterDataSource = nil;
	_sortFilterDataSource = [Game MR_fetchAllGroupedBy:group withPredicate:predicate sortedBy:sort ascending:ascending inContext:_context];
	[_collectionView reloadData];
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
	
	actionSheet = [[UIActionSheet alloc] initWithTitle:@"Sort by" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Title", @"Year of Release", @"Rating", @"Metascore", nil];
	[actionSheet setTag:1];
	
	if ([Tools deviceIsiPhone])
		[actionSheet showInView:self.view.window];
	else
		[actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItems.firstObject animated:YES];
	
	[self.navigationController.navigationBar setUserInteractionEnabled:NO];
}

- (void)showFilterOptions{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Show only" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Finished", @"Unfinished", @"Retail", @"Digital", @"Lent", @"Borrowed", nil];
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
	
	_sortOrFilter = LibrarySortPlatform;
	
//	[self loadDataSource];
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
	
	_sortOrFilter = LibrarySortPlatform;
	
	[self loadDataSource];
	[_collectionView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	NSIndexPath *indexPath = sender;
	Game *game = (_sortOrFilter == LibrarySortPlatform) ? _dataSource[indexPath.section][@"platform"][@"games"][indexPath.row] : [_sortFilterDataSource objectAtIndexPath:indexPath];
	
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
