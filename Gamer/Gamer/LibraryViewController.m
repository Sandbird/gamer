//
//  LibraryCollectionViewController.m
//  Gamer
//
//  Created by Caio Mello on 24/07/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "LibraryViewController.h"
#import "LibraryCollectionCell.h"
#import "Game.h"
#import "Platform.h"
#import "CoverImage.h"
#import "Genre.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "SimilarGame.h"
#import "ReleaseDate.h"
#import "GameTableViewController.h"
#import "HeaderCollectionReusableView.h"
#import <AFNetworking/AFNetworking.h>
#import "SearchViewController.h"
#import "LibraryFilterView.h"

typedef NS_ENUM(NSInteger, LibraryFilter){
	LibraryFilterTitle,
	LibraryFilterPlatform,
	LibraryFilterReleaseYear,
	LibraryFilterMetascore
};

@interface LibraryViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIActionSheetDelegate, LibraryFilterViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *refreshBarButton;
@property (nonatomic, strong) UIBarButtonItem *searchBarItem;

@property (nonatomic, strong) UIBarButtonItem *sortBarButton;
@property (nonatomic, strong) UIBarButtonItem *filterBarButton;
@property (nonatomic, strong) UIBarButtonItem *cancelBarButton;

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, strong) LibraryFilterView *filterView;

@property (nonatomic, assign) LibraryFilter filter;

@property (nonatomic, strong) NSCache *imageCache;

@property (nonatomic, assign) NSInteger numberOfRunningTasks;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation LibraryViewController

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
	
	_fetchedResultsController = [Game MR_fetchAllGroupedBy:@"libraryPlatform.index" withPredicate:[NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"libraryPlatform.index,title" ascending:YES inContext:_context];
	
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
	SearchViewController *searchViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SearchViewController"];
	[self.navigationController pushViewController:searchViewController animated:NO];
	return NO;
}

#pragma mark - CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
	[_guideView setHidden:([Game MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"owned = %@", @(YES)]] == 0) ? NO : YES];
	
	return _fetchedResultsController.sections.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
	NSString *sectionName = [_fetchedResultsController.sections[indexPath.section] name];
	
	Game *game = [_fetchedResultsController objectAtIndexPath:indexPath];
	
	NSString *headerTitle;
	
	switch (_filter) {
		case LibraryFilterTitle: headerTitle = sectionName; break;
		case LibraryFilterPlatform: headerTitle = game.libraryPlatform.name; break;
		case LibraryFilterReleaseYear: headerTitle = game.releaseDate.year.stringValue; break;
		case LibraryFilterMetascore: headerTitle = game.metascore.length > 0 ? game.metascore : @"Unavailable"; break;
		default: break;
	}
	
	if ([headerTitle isEqualToString:@"2050"])
		headerTitle = @"Unknown";
	
	HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
	[headerView.titleLabel setText:headerTitle];
	[headerView.separator setHidden:indexPath.section == 0 ? YES : NO];
	return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [_fetchedResultsController.sections[section] numberOfObjects];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
	switch ([Session gamer].librarySize.integerValue) {
		case 0: return [Tools deviceIsiPhone] ? CGSizeMake(40, 50) : CGSizeMake(83, 91);
		case 1: return [Tools deviceIsiPhone] ? CGSizeMake(50, 63) : CGSizeMake(115, 127);
		case 2: return [Tools deviceIsiPhone] ? CGSizeMake(66, 83) : CGSizeMake(140, 176);
		default: return CGSizeZero;
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [_fetchedResultsController objectAtIndexPath:indexPath];
	
	LibraryCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	
	UIImage *image = [_imageCache objectForKey:game.thumbnailName];
	
	if (image){
		[cell.coverImageView setImage:image];
		[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
	}
	else{
		[cell.coverImageView setImage:nil];
		[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
		
		UIImage *image = [UIImage imageWithData:game.thumbnailLibrary];
		
		UIGraphicsBeginImageContext(image.size);
		[image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		[cell.coverImageView setImage:image];
		[cell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
		
		if (image){
			[_imageCache setObject:image forKey:game.thumbnailName];
		}
	}
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:indexPath];
}

#pragma mark - Networking

- (void)requestInformationForGame:(Game *)game{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Game", self, ((NSHTTPURLResponse *)response).statusCode);
			
			_numberOfRunningTasks--;
			
			if (_numberOfRunningTasks == 0){
				[_refreshBarButton setEnabled:YES];
				[_refreshControl endRefreshing];
			}
		}
		else{
			NSLog(@"Success in %@ - Status code: %d - Game - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			_numberOfRunningTasks--;
			
			[Networking updateGame:game withDataFromJSON:responseObject context:_context];
			
			if (_numberOfRunningTasks == 0){
				[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					[_collectionView reloadData];
					
					BOOL imagesDownloaded = NO;
					
					for (NSInteger section = 0; section < _fetchedResultsController.sections.count; section++){
						for (NSInteger row = 0; row < ([_fetchedResultsController.sections[section] numberOfObjects]); row++){
							Game *fetchedGame = [_fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
							
							UIImage *thumbnail = [UIImage imageWithData:fetchedGame.thumbnailLibrary];
							CGSize optimalSize = [Session optimalCoverImageSizeForImage:thumbnail type:GameImageTypeLibrary];
							
							if (!fetchedGame.thumbnailWishlist || !fetchedGame.thumbnailLibrary || !fetchedGame.coverImage.data || (thumbnail.size.width != optimalSize.width || thumbnail.size.height != optimalSize.height)){
								imagesDownloaded = YES;
								[self downloadCoverImageForGame:fetchedGame];
							}
							
							if (section == _fetchedResultsController.sections.count - 1 && row == [_fetchedResultsController.sections[section] numberOfObjects] - 1 && imagesDownloaded == NO){
								[_refreshBarButton setEnabled:YES];
								[_refreshControl endRefreshing];
							}
						}
					}
				}];
			}
		}
	}];
	[dataTask resume];
	_numberOfRunningTasks++;
}

- (void)downloadCoverImageForGame:(Game *)game{
	if (!game.coverImage.url) return;
	
	NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:game.coverImage.url]];
	
	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), request.URL.lastPathComponent]];
		[[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
		return fileURL;
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Thumbnail", self, ((NSHTTPURLResponse *)response).statusCode);
			_numberOfRunningTasks--;
		}
		else{
			NSLog(@"Success in %@ - Status code: %d - Thumbnail - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			_numberOfRunningTasks--;
			
			UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
			[game.coverImage setData:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeCover])];
			[game setThumbnailWishlist:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeWishlist])];
			[game setThumbnailLibrary:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeLibrary])];
			
			if (_numberOfRunningTasks == 0){
				[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					[_collectionView reloadData];
					[_refreshBarButton setEnabled:YES];
					[_refreshControl endRefreshing];
				}];
			}
		}
	}];
	[downloadTask resume];
	_numberOfRunningTasks++;
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
	
	_fetchedResultsController = nil;
	_fetchedResultsController = [Game MR_fetchAllGroupedBy:@"libraryPlatform.index" withPredicate:[NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"libraryPlatform.index,title" ascending:YES inContext:_context];
	[_collectionView reloadData];
}

#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex){
		if (actionSheet.tag == 1){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"owned = %@", @(YES)];
			
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
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:[NSPredicate predicateWithFormat:@"owned = %@ AND completed = %@", @(YES), @(YES)] sort:@"libraryPlatform.index,title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing finished games" animated:YES];
					break;
				case 1:
					// Unfinished
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:[NSPredicate predicateWithFormat:@"owned = %@ AND completed = %@", @(YES), @(NO)] sort:@"libraryPlatform.index,title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing unfinished games" animated:YES];
					break;
				case 2:
					// Digital
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:[NSPredicate predicateWithFormat:@"owned = %@ AND digital = %@", @(YES), @(YES)] sort:@"libraryPlatform.index,title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing digital games" animated:YES];
					break;
				case 3:
					// Retail
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:[NSPredicate predicateWithFormat:@"owned = %@ AND digital = %@", @(YES), @(NO)] sort:@"libraryPlatform.index,title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing retail games" animated:YES];
					break;
				case 4:
					// Lent
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:[NSPredicate predicateWithFormat:@"owned = %@ AND loaned = %@", @(YES), @(YES)] sort:@"libraryPlatform.index,title" ascending:YES];
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

- (void)fetchGamesWithFilter:(LibraryFilter)filter group:(NSString *)group predicate:(NSPredicate *)predicate sort:(NSString *)sort ascending:(BOOL)ascending{
	_filter = filter;
	
	_fetchedResultsController = nil;
	_fetchedResultsController = [Game MR_fetchAllGroupedBy:group withPredicate:predicate sortedBy:sort ascending:ascending inContext:_context];
	[_collectionView reloadData];
}

- (void)refreshLibraryGames{
	if (_fetchedResultsController.fetchedObjects.count > 0){
		[_refreshBarButton setEnabled:NO];
	}
	
	_numberOfRunningTasks = 0;
	
	// Request info for all games in the Wishlist
	for (NSInteger section = 0; section < _fetchedResultsController.sections.count; section++)
		for (NSInteger row = 0; row < ([_fetchedResultsController.sections[section] numberOfObjects]); row++)
			[self requestInformationForGame:[_fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]]];
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
	
	_fetchedResultsController = nil;
	_fetchedResultsController = [Game MR_fetchAllGroupedBy:@"libraryPlatform.index" withPredicate:[NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"libraryPlatform.index,title" ascending:YES inContext:_context];
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
	
	_fetchedResultsController = nil;
	_fetchedResultsController = [Game MR_fetchAllGroupedBy:@"libraryPlatform.index" withPredicate:[NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"libraryPlatform.index,title" ascending:YES inContext:_context];
	[_collectionView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		if ([Tools deviceIsiPad]){
			UINavigationController *navigationController = segue.destinationViewController;
			GameTableViewController *destination = (GameTableViewController *)navigationController.topViewController;
			[destination setGame:[_fetchedResultsController objectAtIndexPath:sender]];
		}
		else{
			// Pop other tabs when opening game details
			for (UIViewController *viewController in self.tabBarController.viewControllers){
				[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
			}
			
			GameTableViewController *destination = segue.destinationViewController;
			[destination setGame:[_fetchedResultsController objectAtIndexPath:sender]];
		}
	}
}

@end
