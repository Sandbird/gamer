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
#import "ReleasePeriod.h"
#import "GameController.h"
#import "HeaderCollectionReusableView.h"
#import <AFNetworking/AFNetworking.h>
#import "SearchController_iPad.h"
#import "LibrarySortFilterView.h"
#import "Platform+Library.h"
#import "NSArray+Split.h"

typedef NS_ENUM(NSInteger, LibrarySort){
	LibrarySortTitle = 0,
	LibrarySortReleaseYear = 1,
	LibrarySortRating = 2,
	LibrarySortMetascore = 3,
	LibrarySortPlatform = 4
};

typedef NS_ENUM(NSInteger, LibraryFilter){
	LibraryFilterFinished = 5,
	LibraryFilterUnfinished = 6,
	LibraryFilterRetail = 7,
	LibraryFilterDigital = 8,
	LibraryFilterLent = 9,
	LibraryFilterBorrowed = 10,
	LibraryFilterRented = 11,
	LibraryFilterNone = 12
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

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation LibraryController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	// UI setup
	if ([Tools deviceIsiPad]){
		self.refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshLibraryGames)];
		
		UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 256, 44)];
		[searchBar setPlaceholder:@"Find Games"];
		[searchBar setDelegate:self];
		self.searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
		
		[self.navigationItem setRightBarButtonItems:@[self.searchBarItem, self.refreshBarButton] animated:NO];
		
		self.sortBarButton = [[UIBarButtonItem alloc] initWithTitle:@"   Sort  " style:UIBarButtonItemStylePlain target:self action:@selector(showSortOptions)];
		self.filterBarButton = [[UIBarButtonItem alloc] initWithTitle:@"      Filter     " style:UIBarButtonItemStylePlain target:self action:@selector(showFilterOptions)];
		self.cancelBarButton = [[UIBarButtonItem alloc] initWithTitle:@"    Cancel   " style:UIBarButtonItemStylePlain target:self action:@selector(cancelBarButtonAction)];
		
		[self.navigationItem setLeftBarButtonItems:@[self.sortBarButton, self.filterBarButton] animated:NO];
	}
	else{
		UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, -50, 0, 0)];
		[self.collectionView addSubview:refreshView];
		
		self.refreshControl = [UIRefreshControl new];
		[self.refreshControl setTintColor:[UIColor lightGrayColor]];
		[self.refreshControl addTarget:self action:@selector(refreshLibraryGames) forControlEvents:UIControlEventValueChanged];
		[refreshView addSubview:self.refreshControl];
		
		self.filterView = [[LibrarySortFilterView alloc] initWithFrame:CGRectMake(0, -50, 320, 50)];
		[self.filterView setDelegate:self];
		[self.collectionView addSubview:self.filterView];
		
		[self.collectionView setContentInset:UIEdgeInsetsMake(50, 0, 0, 0)];
	}
	
	// Other stuff
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLibraryNotification:) name:@"RefreshLibrary" object:nil];
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	self.sortOrFilter = LibrarySortPlatform;
	
	[self loadDataSource];
	
	self.imageCache = [NSCache new];
	
	self.guideView = [[NSBundle mainBundle] loadNibNamed:[Tools deviceIsiPad] ? @"iPad" : @"iPhone" owner:self options:nil][ViewIndexLibraryGuideView];
	[self.view insertSubview:self.guideView aboveSubview:self.collectionView];
	[self.guideView setFrame:self.view.frame];
	[self.guideView setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	
	if ([Tools deviceIsiPad])
		[(UISearchBar *)self.searchBarItem.customView setText:[Session searchQuery]];
}

- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	
	[self.refreshControl endRefreshing];
}

- (void)viewDidLayoutSubviews{
	[super viewDidLayoutSubviews];
	
	if ([Tools deviceIsiPad])
		[self.guideView setCenter:self.view.center];
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

#pragma mark - CollectionViewLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
	switch ([Session gamer].librarySize.integerValue) {
		case LibrarySizeSmall: return [Tools deviceIsiPhone] ? CGSizeMake(40, 50) : CGSizeMake(83, 91);
		case LibrarySizeMedium: return [Tools deviceIsiPhone] ? CGSizeMake(50, 63) : CGSizeMake(115, 127);
		case LibrarySizeLarge: return [Tools deviceIsiPhone] ? CGSizeMake(66, 83) : CGSizeMake(140, 176);
		default: return CGSizeZero;
	}
}

#pragma mark - CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
	[self.guideView setHidden:([Game MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"inLibrary = %@", @(YES)]] == 0) ? NO : YES];
	
	if (self.sortOrFilter == LibrarySortPlatform){
		return self.dataSource.count;
	}
	else if (self.sortFilterDataSource.fetchedObjects.count > 0){
		return self.sortFilterDataSource.sections.count;
	}
	else{
		return 0;
	}
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
	NSInteger gameCount = (self.sortOrFilter == LibrarySortPlatform) ? [self.dataSource[indexPath.section][@"platform"][@"games"] count] : [self.sortFilterDataSource.sections[indexPath.section] numberOfObjects];
	
	if (self.sortOrFilter == LibrarySortPlatform){
		HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
		[headerView.titleLabel setText:self.dataSource[indexPath.section][@"platform"][@"name"]];
		[headerView.countLabel setText:[NSString stringWithFormat:gameCount > 1 ? @"%ld games" : @"%ld game", (long)gameCount]];
		return headerView;
	}
	else{
		NSString *sectionName = [self.sortFilterDataSource.sections[indexPath.section] name];
		
		Game *game = [self.sortFilterDataSource objectAtIndexPath:indexPath];
		
		NSString *headerTitle;
		
		switch (self.sortOrFilter) {
			case LibrarySortTitle: headerTitle = sectionName; break;
			case LibrarySortReleaseYear: headerTitle = [game.releaseYear isEqualToNumber:@(2050)] ? @"Unknown" : game.releaseYear.stringValue; break;
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
			case LibrarySortMetascore: headerTitle = (!game.selectedMetascore || [game.selectedMetascore.criticScore isEqualToNumber:@(0)]) ? @"Unavailable" : [NSString stringWithFormat:@"%@", game.selectedMetascore.criticScore]; break;
			case LibraryFilterFinished: headerTitle = @"Finished"; break;
			case LibraryFilterUnfinished: headerTitle = @"Unfinished"; break;
			case LibraryFilterRetail: headerTitle = @"Retail"; break;
			case LibraryFilterDigital: headerTitle = @"Digital"; break;
			case LibraryFilterLent: headerTitle = @"Lent"; break;
			case LibraryFilterBorrowed: headerTitle = @"Borrowed"; break;
			case LibraryFilterRented: headerTitle = @"Rented"; break;
			default: break;
		}
		
		HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
		[headerView.titleLabel setText:headerTitle];
		[headerView.countLabel setText:[NSString stringWithFormat:gameCount > 1 ? @"%ld games" : @"%ld game", (long)gameCount]];
		return headerView;
	}
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return (self.sortOrFilter == LibrarySortPlatform) ? [self.dataSource[section][@"platform"][@"games"] count] : [self.sortFilterDataSource.sections[section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = (self.sortOrFilter == LibrarySortPlatform) ? self.dataSource[indexPath.section][@"platform"][@"games"][indexPath.row] : [self.sortFilterDataSource objectAtIndexPath:indexPath];
	
	LibraryCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	
	UIImage *image = [self.imageCache objectForKey:game.imagePath.lastPathComponent];
	
	if (image){
		[cell.coverImageView setImage:image];
		[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
	}
	else{
		[cell.coverImageView setImage:nil];
		
		__block UIImage *image = [UIImage imageWithContentsOfFile:game.imagePath];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			CGSize cellSize = [Tools deviceIsiPhone] ? CGSizeMake(66, 83) : CGSizeMake(140, 176);
			
			CGSize imageSize = image.size.width > image.size.height ? [Tools sizeOfImage:image aspectFitToWidth:cellSize.width] : [Tools sizeOfImage:image aspectFitToHeight:cellSize.height];
			
			UIGraphicsBeginImageContext(imageSize);
			[image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
			image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[cell.coverImageView setImage:image];
				[cell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
				
				if (image){
					[self.imageCache setObject:image forKey:game.imagePath.lastPathComponent];
				}
			});
		});
	}
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:indexPath];
}

#pragma mark - Networking

- (void)requestGames:(NSArray *)games{
	NSArray *identifiers = [games valueForKey:@"identifier"];
	
	NSURLRequest *request = [Networking requestForGamesWithIdentifiers:identifiers fields:@"deck,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,id,image,name,original_release_date,platforms"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Games", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Games - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				for (NSDictionary *dictionary in responseObject[@"results"]){
					NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
					Game *game = [games filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]].firstObject;
					
					[Networking updateGame:game withResults:dictionary context:self.context];
					
					NSString *coverImageURL = (dictionary[@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:dictionary[@"image"][@"super_url"]] : nil;
					
					UIImage *coverImage = [UIImage imageWithContentsOfFile:game.imagePath];
					
					if (!coverImage || !game.imagePath || ![game.imageURL isEqualToString:coverImageURL]){
						[self downloadCoverImageWithURL:coverImageURL game:game];
					}
					
					if (!game.selectedMetascore){
						NSSortDescriptor *groupSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES];
						NSSortDescriptor *indexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
						NSArray *orderedPlatforms = [game.libraryPlatforms.allObjects sortedArrayUsingDescriptors:@[groupSortDescriptor, indexSortDescriptor]];
						
						[self requestMetascoreForGame:game platform:orderedPlatforms.firstObject];
					}
				}
			}
		}
		
		[self.refreshBarButton setEnabled:YES];
		[self.refreshControl endRefreshing];
		
		[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self.collectionView reloadData];
		}];
	}];
	[dataTask resume];
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
			
			NSString *path = [NSString stringWithFormat:@"%@/%@", [Tools imagesDirectory], request.URL.lastPathComponent];
			
			__block UIImage *image = [UIImage imageWithContentsOfFile:path];
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
				CGSize coverImageSize = [Session coverImageSize];
				
				CGSize imageSize = image.size.width > image.size.height ? [Tools sizeOfImage:image aspectFitToWidth:coverImageSize.width] : [Tools sizeOfImage:image aspectFitToHeight:coverImageSize.height];
				
				UIGraphicsBeginImageContext(imageSize);
				[image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
				image = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();
				
				NSData *imageData = UIImagePNGRepresentation(image);
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[imageData writeToFile:path atomically:YES];
					
					[game setImagePath:path];
					[game setImageURL:URLString];
					
					[self.collectionView reloadData];
				});
			});
		}
	}];
	[downloadTask resume];
}

- (void)requestMetascoreForGame:(Game *)game platform:(Platform *)platform{
	NSURLRequest *request = [Networking requestForMetascoreWithGame:game platform:platform];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Metascore", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Metascore - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"result"] isKindOfClass:[NSNumber class]])
				return;
			
			NSDictionary *results = responseObject[@"result"];
			
			NSString *metacriticURL = [Tools stringFromSourceIfNotNull:results[@"url"]];
			
			Metascore *metascore = [Metascore MR_findFirstByAttribute:@"metacriticURL" withValue:metacriticURL inContext:self.context];
			if (!metascore) metascore = [Metascore MR_createInContext:self.context];
			[metascore setCriticScore:[Tools integerNumberFromSourceIfNotNull:results[@"score"]]];
			[metascore setUserScore:[Tools decimalNumberFromSourceIfNotNull:results[@"userscore"]]];
			[metascore setMetacriticURL:metacriticURL];
			[metascore setPlatform:platform];
			[game addMetascoresObject:metascore];
			[game setSelectedMetascore:metascore];
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
	[self.filterView resetAnimated:YES];
	
	self.sortOrFilter = LibrarySortPlatform;
	
	self.sortFilterDataSource = nil;
	[self.collectionView reloadData];
}

#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex){
		if (actionSheet.tag == 1){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inLibrary = %@", @(YES)];
			
			// Sort
			switch (buttonIndex) {
				case LibrarySortTitle:
					[self fetchGameswithSortOrFilter:LibrarySortTitle group:@"title.stringGroupByFirstInitial" predicate:predicate sort:@"title" ascending:YES];
					[self.filterView showStatusWithTitle:@"Sorted by title" animated:YES];
					break;
				case LibrarySortReleaseYear:
					[self fetchGameswithSortOrFilter:LibrarySortReleaseYear group:@"releaseYear" predicate:predicate sort:@"releaseYear,title" ascending:NO];
					[self.filterView showStatusWithTitle:@"Sorted by year of release" animated:YES];
					break;
				case LibrarySortRating:
					[self fetchGameswithSortOrFilter:LibrarySortRating group:@"personalRating" predicate:predicate sort:@"personalRating,title" ascending:NO];
					[self.filterView showStatusWithTitle:@"Sorted by rating" animated:YES];
					break;
				case LibrarySortMetascore:
					[self fetchGameswithSortOrFilter:LibrarySortMetascore group:@"selectedMetascore.criticScore" predicate:predicate sort:@"selectedMetascore.criticScore,title" ascending:NO];
					[self.filterView showStatusWithTitle:@"Sorted by Metascore" animated:YES];
					break;
				default:
					break;
			}
		}
		else{
			// Filter
			switch (buttonIndex + 5) {
				case LibraryFilterFinished:
					[self fetchGameswithSortOrFilter:LibraryFilterFinished group:nil predicate:[NSPredicate predicateWithFormat:@"inLibrary = %@ AND finished = %@", @(YES), @(YES)] sort:@"title" ascending:YES];
					[self.filterView showStatusWithTitle:@"Showing finished games" animated:YES];
					break;
				case LibraryFilterUnfinished:
					[self fetchGameswithSortOrFilter:LibraryFilterUnfinished group:nil predicate:[NSPredicate predicateWithFormat:@"inLibrary = %@ AND finished = %@", @(YES), @(NO)] sort:@"title" ascending:YES];
					[self.filterView showStatusWithTitle:@"Showing unfinished games" animated:YES];
					break;
				case LibraryFilterRetail:
					[self fetchGameswithSortOrFilter:LibraryFilterRetail group:nil predicate:[NSPredicate predicateWithFormat:@"inLibrary = %@ AND digital = %@", @(YES), @(NO)] sort:@"title" ascending:YES];
					[self.filterView showStatusWithTitle:@"Showing retail games" animated:YES];
					break;
				case LibraryFilterDigital:
					[self fetchGameswithSortOrFilter:LibraryFilterDigital group:nil predicate:[NSPredicate predicateWithFormat:@"inLibrary = %@ AND digital = %@", @(YES), @(YES)] sort:@"title" ascending:YES];
					[self.filterView showStatusWithTitle:@"Showing digital games" animated:YES];
					break;
				case LibraryFilterLent:
					[self fetchGameswithSortOrFilter:LibraryFilterLent group:nil predicate:[NSPredicate predicateWithFormat:@"inLibrary = %@ AND lent = %@", @(YES), @(YES)] sort:@"title" ascending:YES];
					[self.filterView showStatusWithTitle:@"Showing lent games" animated:YES];
					break;
				case LibraryFilterBorrowed:
					[self fetchGameswithSortOrFilter:LibraryFilterBorrowed group:nil predicate:[NSPredicate predicateWithFormat:@"inLibrary = %@ AND borrowed = %@", @(YES), @(YES)] sort:@"title" ascending:YES];
					[self.filterView showStatusWithTitle:@"Showing borrowed games" animated:YES];
					break;
				case LibraryFilterRented:
					[self fetchGameswithSortOrFilter:LibraryFilterRented group:nil predicate:[NSPredicate predicateWithFormat:@"inLibrary = %@ AND rented = %@", @(YES), @(YES)] sort:@"title" ascending:YES];
					[self.filterView showStatusWithTitle:@"Showing rented games" animated:YES];
					break;
				default:
					break;
			}
		}
		
		if ([Tools deviceIsiPad]){
			[self.navigationItem setLeftBarButtonItems:@[self.sortBarButton, self.filterBarButton, self.cancelBarButton] animated:YES];
		}
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.filterView.sortButton setHighlighted:NO];
		[self.filterView.filterButton setHighlighted:NO];
	});

	[self enableNavigationBarItems];
}

#pragma mark - Custom

- (void)loadDataSource{
	NSArray *platforms = [Platform MR_findAllSortedBy:@"group,index" ascending:YES withPredicate:nil inContext:self.context];
	
	self.dataSource = [[NSMutableArray alloc] initWithCapacity:platforms.count];
	
	for (Platform *platform in platforms){
		if (platform.containsLibraryGames){
			NSArray *games = platform.sortedLibraryGames;
			
			[self.dataSource addObject:@{@"platform":@{@"id":platform.identifier,
													   @"name":platform.name,
													   @"games":games}}];
		}
	}
}

- (void)fetchGameswithSortOrFilter:(NSInteger)filter group:(NSString *)group predicate:(NSPredicate *)predicate sort:(NSString *)sort ascending:(BOOL)ascending{
	self.sortOrFilter = filter;
	
	self.sortFilterDataSource = nil;
	self.sortFilterDataSource = [Game MR_fetchAllGroupedBy:group withPredicate:predicate sortedBy:sort ascending:ascending inContext:self.context];
	[self.collectionView reloadData];
}

- (void)refreshLibraryGames{
	NSArray *platformGames = [self.dataSource valueForKeyPath:@"platform.games"];
	
	if (platformGames.count > 0){
		[self.refreshBarButton setEnabled:NO];
	}
	
	NSMutableArray *games = [[NSMutableArray alloc] init];
	for (NSArray *array in platformGames){
		[games addObjectsFromArray:array];
	}
	
	NSArray *splitArray = [NSArray splitArray:games componentsPerSegment:100];
	
	for (NSArray *array in splitArray){
		[self requestGames:array];
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
	
	[self disableNavigationBarItems];
}

- (void)showFilterOptions{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Show only" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Finished", @"Unfinished", @"Retail", @"Digital", @"Lent", @"Borrowed", @"Rented", nil];
	[actionSheet setTag:2];
	
	if ([Tools deviceIsiPhone])
		[actionSheet showInView:self.view.window];
	else
		[actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItems[1] animated:YES];
	
	[self disableNavigationBarItems];
}

- (void)disableNavigationBarItems{
	[self.sortBarButton setEnabled:NO];
	[self.filterBarButton setEnabled:NO];
	[self.cancelBarButton setEnabled:NO];
	[self.refreshBarButton setEnabled:NO];
	[self.searchBarItem setEnabled:NO];
}

- (void)enableNavigationBarItems{
	[self.sortBarButton setEnabled:YES];
	[self.filterBarButton setEnabled:YES];
	[self.cancelBarButton setEnabled:YES];
	[self.refreshBarButton setEnabled:YES];
	[self.searchBarItem setEnabled:YES];
}

#pragma mark - Actions

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[self refreshLibraryGames];
}

- (void)cancelBarButtonAction{
	[self.navigationItem setLeftBarButtonItems:@[self.sortBarButton, self.filterBarButton] animated:YES];
	
	self.sortOrFilter = LibrarySortPlatform;
	
//	[self loadDataSource];
	[self.collectionView reloadData];
}

- (void)coverImageDownloadedNotification:(NSNotification *)notification{
	[self.collectionView reloadData];
}

- (void)refreshLibraryNotification:(NSNotification *)notification{
	if ([Tools deviceIsiPad]){
		[self.navigationItem setLeftBarButtonItems:@[self.sortBarButton, self.filterBarButton] animated:NO];
	}
	
	[self.filterView resetAnimated:YES];
	
	self.sortOrFilter = LibrarySortPlatform;
	
	[self loadDataSource];
	[self.collectionView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	NSIndexPath *indexPath = sender;
	Game *game = (self.sortOrFilter == LibrarySortPlatform) ? self.dataSource[indexPath.section][@"platform"][@"games"][indexPath.row] : [self.sortFilterDataSource objectAtIndexPath:indexPath];
	
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
