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
#import "GameTableViewController.h"
#import "HeaderCollectionReusableView.h"
#import <AFNetworking/AFNetworking.h>
#import "SearchViewController.h"

@interface LibraryViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>

@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *searchBarItem;

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation LibraryViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	_refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshLibraryGames)];
	_cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancelRefresh)];
	
	if ([Tools deviceIsiPad]){
		UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 256, 44)];
		[searchBar setPlaceholder:@"Find Games"];
		[searchBar setDelegate:self];
		_searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
	}
	
	[Tools deviceIsiPad] ? [self.navigationItem setRightBarButtonItems:@[_searchBarItem, _refreshButton] animated:NO] : [self.navigationItem setRightBarButtonItem:_refreshButton animated:NO];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLibraryNotification:) name:@"RefreshLibrary" object:nil];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	
	_fetchedResultsController = [self fetchData];
	
	_guideView = [[NSBundle mainBundle] loadNibNamed:[Tools deviceIsiPad] ? @"iPad" : @"iPhone" owner:self options:nil][1];
	[self.view insertSubview:_guideView aboveSubview:_collectionView];
	[_guideView setFrame:self.view.frame];
	[_guideView setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated{
	if ([Tools deviceIsiPad])
		[(UISearchBar *)_searchBarItem.customView setText:[SessionManager searchQuery]];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] set:kGAIScreenName value:@"Library"];
	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
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

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)fetchData{
	if (!_fetchedResultsController){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"owned = %@", @(YES)];
		_fetchedResultsController = [Game fetchAllGroupedBy:@"libraryPlatform.index" withPredicate:predicate sortedBy:@"libraryPlatform.index,title" ascending:YES];
	}
	return _fetchedResultsController;
}

#pragma mark - CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
	[_guideView setHidden:(_fetchedResultsController.sections.count == 0) ? NO : YES];
	
	return _fetchedResultsController.sections.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
	NSString *sectionName = [_fetchedResultsController.sections[indexPath.section] name];
	Platform *platform = [Platform findFirstByAttribute:@"index" withValue:sectionName];
	
	HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
	[headerView.titleLabel setText:platform.name];
	[headerView.separator setHidden:indexPath.section == 0 ? YES : NO];
	return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [_fetchedResultsController.sections[section] numberOfObjects];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
	switch ([SessionManager gamer].librarySize.integerValue) {
		case 0: return [Tools deviceIsiPad] ? CGSizeMake(83, 91) : CGSizeMake(50, 63);
		case 1: return [Tools deviceIsiPad] ? CGSizeMake(115, 127) : CGSizeMake(66, 83);
		case 2: return [Tools deviceIsiPad] ? CGSizeMake(140, 176) : CGSizeMake(92, 116);
		default: return CGSizeZero;
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [_fetchedResultsController objectAtIndexPath:indexPath];
	UIImage *image = [UIImage imageWithData:game.thumbnailLibrary];
	
	LibraryCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.coverImageView setImage:image];
	[cell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:indexPath];
}

#pragma mark - Networking

- (void)requestInformationForGame:(Game *)game{
	[Tools deviceIsiPad] ? [self.navigationItem setRightBarButtonItems:@[_searchBarItem, _cancelButton] animated:NO] : [self.navigationItem setRightBarButtonItem:_cancelButton animated:YES];
	
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Game", self, ((NSHTTPURLResponse *)response).statusCode);
			
			if ([Networking manager].dataTasks.count == 0)
				[Tools deviceIsiPad] ? [self.navigationItem setRightBarButtonItems:@[_searchBarItem, _refreshButton] animated:NO] : [self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
		}
		else{
			NSLog(@"Success in %@ - Status code: %d - Game - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			[Networking updateGame:game withDataFromJSON:responseObject context:_context];
			
			if (![responseObject[@"status_code"] isEqualToNumber:@(101)]){
				NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
				
				UIImage *coverImage = [UIImage imageWithData:game.coverImage.data];
				CGSize optimalSize = [SessionManager optimalCoverImageSizeForImage:coverImage];
				
				if (!game.thumbnailWishlist || !game.thumbnailLibrary || !game.coverImage.data || ![game.coverImage.url isEqualToString:coverImageURL] || (coverImage.size.width != optimalSize.width || coverImage.size.height != optimalSize.height)){
					[self downloadCoverImageForGame:game];
				}
			}
			
			if ([Networking manager].dataTasks.count == 0)
				[Tools deviceIsiPad] ? [self.navigationItem setRightBarButtonItems:@[_searchBarItem, _refreshButton] animated:NO] : [self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
		}
	}];
	[dataTask resume];
}

- (void)downloadCoverImageForGame:(Game *)game{
	NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:game.coverImage.url]];
	
	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		return [NSURL fileURLWithPath:[NSString stringWithFormat:@"/tmp/%@", request.URL.lastPathComponent]];
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		if (error){
			if ([Networking manager].downloadTasks.count == 0)
				[Tools deviceIsiPad] ? [self.navigationItem setRightBarButtonItems:@[_searchBarItem, _refreshButton] animated:NO] : [self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
		}
		else{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
				[game.coverImage setData:UIImagePNGRepresentation([SessionManager aspectFitImageWithImage:downloadedImage type:GameImageTypeCover])];
				[game setThumbnailWishlist:UIImagePNGRepresentation([SessionManager aspectFitImageWithImage:downloadedImage type:GameImageTypeWishlist])];
				[game setThumbnailLibrary:UIImagePNGRepresentation([SessionManager aspectFitImageWithImage:downloadedImage type:GameImageTypeLibrary])];
				
				[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[_collectionView reloadData];
						
						if ([Networking manager].downloadTasks.count == 0)
							[Tools deviceIsiPad] ? [self.navigationItem setRightBarButtonItems:@[_searchBarItem, _refreshButton] animated:NO] : [self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
					});
				}];
			});
		}
	}];
	[downloadTask resume];
}

#pragma mark - Custom

- (void)refreshLibraryGames{
	// Request info for all games in the Wishlist
	for (NSInteger section = 0; section < _fetchedResultsController.sections.count; section++)
		for (NSInteger row = 0; row < ([_fetchedResultsController.sections[section] numberOfObjects]); row++)
			[self requestInformationForGame:[_fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]]];
}

- (void)cancelRefresh{
	[[Networking manager].operationQueue cancelAllOperations];
}

#pragma mark - Actions

- (void)coverImageDownloadedNotification:(NSNotification *)notification{
	[_collectionView reloadData];
}

- (void)refreshLibraryNotification:(NSNotification *)notification{
	_fetchedResultsController = nil;
	_fetchedResultsController = [self fetchData];
	[_collectionView reloadData];
}

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[self refreshLibraryGames];
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
