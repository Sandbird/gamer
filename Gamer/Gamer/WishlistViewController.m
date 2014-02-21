//
//  WishlistCollectionViewController.m
//  Gamer
//
//  Created by Caio Mello on 26/08/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "WishlistViewController.h"
#import "Game.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "ReleasePeriod.h"
#import "ReleaseDate.h"
#import "CoverImage.h"
#import "SimilarGame.h"
#import "GameTableViewController.h"
#import "WishlistCollectionCell.h"
#import "HeaderCollectionReusableView.h"
#import <AFNetworking/AFNetworking.h>
#import "SearchViewController.h"

@interface WishlistViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *searchBarItem;

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) NSCache *imageCache;

@property (nonatomic, assign) NSInteger numberOfRunningTasks;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation WishlistViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[Session setup];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	_refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshWishlistGames)];
	
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 256, 44)];
	[searchBar setPlaceholder:@"Find Games"];
	[searchBar setDelegate:self];
	_searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
	
	[self.navigationItem setRightBarButtonItems:@[_searchBarItem, _refreshButton] animated:NO];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWishlistNotification:) name:@"RefreshWishlist" object:nil];
	
	_context = [NSManagedObjectContext defaultContext];
	
	_fetchedResultsController = [self fetchData];
	
	_imageCache = [NSCache new];
	
	// Add guide view to the view
	_guideView = [[NSBundle mainBundle] loadNibNamed:[Tools deviceIsiPad] ? @"iPad" : @"iPhone" owner:self options:nil][0];
	[self.view insertSubview:_guideView aboveSubview:_collectionView];
	[_guideView setFrame:self.view.frame];
	[_guideView setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated{
	[(UISearchBar *)_searchBarItem.customView setText:[Session searchQuery]];
}

- (void)viewDidAppear:(BOOL)animated{
	[[Session tracker] set:kGAIScreenName value:@"Wishlist"];
	[[Session tracker] send:[[GAIDictionaryBuilder createAppView] build]];
	
	[self updateGameReleasePeriods];
}

- (void)viewDidLayoutSubviews{
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
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"wanted = %@", @(YES)];
		_fetchedResultsController = [Game fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:predicate sortedBy:@"releasePeriod.identifier,releaseDate.date,title" ascending:YES];
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
	ReleasePeriod *releasePeriod = [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(sectionName.integerValue) inContext:_context];
	
	HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
	[headerView.titleLabel setText:releasePeriod.name];
	[headerView.separator setHidden:indexPath.section == 0 ? YES : NO];
	return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [_fetchedResultsController.sections[section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [_fetchedResultsController objectAtIndexPath:indexPath];
	
	WishlistCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	
	UIImage *image = [_imageCache objectForKey:game.thumbnailName];
	
	if (image){
		[cell.coverImageView setImage:image];
		[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
	}
	else{
		[cell.coverImageView setImage:nil];
		[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			UIImage *image = [UIImage imageWithData:game.thumbnailWishlist];
			
			UIGraphicsBeginImageContext(image.size);
			[image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
			image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[cell.coverImageView setImage:image];
				[cell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
			});
			
			if (image){
				[_imageCache setObject:image forKey:game.thumbnailName];
			}
		});
	}
	
	[cell.titleLabel setText:(game.identifier) ? game.title : nil];
	[cell.dateLabel setText:game.releaseDateText];
	[cell.platformLabel setText:game.wishlistPlatform.abbreviation];
	[cell.platformLabel setBackgroundColor:game.wishlistPlatform.color];
	[cell.preorderedIcon setHidden:([game.preordered isEqualToNumber:@(YES)] && [game.released isEqualToNumber:@(NO)]) ? NO : YES];
	
	if ([game.released isEqualToNumber:@(YES)] && game.wishlistMetascore.length > 0 && game.wishlistMetascorePlatform == game.wishlistPlatform){
		[cell.metascoreLabel setHidden:NO];
		[cell.metascoreLabel setText:game.wishlistMetascore];
		[cell.metascoreLabel setTextColor:[Networking colorForMetascore:game.wishlistMetascore]];
	}
	else
		[cell.metascoreLabel setHidden:YES];
	
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
				[_refreshButton setEnabled:YES];
				[self updateGameReleasePeriods];
			}
		}
		else{
			NSLog(@"Success in %@ - Status code: %d - Game - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			_numberOfRunningTasks--;
			
			[Networking updateGame:game withDataFromJSON:responseObject context:_context];
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				if (![responseObject[@"status_code"] isEqualToNumber:@(101)]){
					NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
					
					UIImage *thumbnail = [UIImage imageWithData:game.thumbnailWishlist];
					CGSize optimalSize = [Session optimalCoverImageSizeForImage:thumbnail type:GameImageTypeWishlist];
					
					if (!game.thumbnailWishlist || !game.thumbnailLibrary || !game.coverImage.data || ![game.coverImage.url isEqualToString:coverImageURL] || (thumbnail.size.width != optimalSize.width || thumbnail.size.height != optimalSize.height)){
						[self downloadCoverImageForGame:game];
					}
				}
			});
			
			if ([game.released isEqualToNumber:@(YES)])
				[self requestMetascoreForGame:game];
			
			if (_numberOfRunningTasks == 0){
				[_refreshButton setEnabled:YES];
				[self updateGameReleasePeriods];
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
		}
		else{
			NSLog(@"Success in %@ - Status code: %d - Thumbnail - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
				[game.coverImage setData:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeCover])];
				[game setThumbnailWishlist:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeWishlist])];
				[game setThumbnailLibrary:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeLibrary])];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
						[_collectionView reloadData];
					}];
				});
			});
		}
	}];
	[downloadTask resume];
}

- (void)requestMetascoreForGame:(Game *)game{
	NSURLRequest *request = [Networking requestForMetascoreForGameWithTitle:game.title platform:game.wishlistPlatform];
	
	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), request.URL.lastPathComponent]];
		[[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
		return fileURL;
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		if (error){
			NSLog(@"Failure in %@ - Metascore", self);
		}
		else{
			NSLog(@"Success in %@ - Metascore - %@", self, request.URL);
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				NSString *HTML = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:filePath] encoding:NSUTF8StringEncoding];
				
				[game setMetacriticURL:request.URL.absoluteString];
				
				if (HTML){
					NSString *metascore = [Networking retrieveMetascoreFromHTML:HTML];
					if (metascore.length > 0 && [[NSScanner scannerWithString:metascore] scanInteger:nil]){
						[game setWishlistMetascore:metascore];
						[game setWishlistMetascorePlatform:game.wishlistPlatform];
					}
					else{
						[game setWishlistMetascore:nil];
						[game setWishlistMetascorePlatform:nil];
					}
				}
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
						[_collectionView reloadData];
					}];
				});
			});
		}
	}];
	[downloadTask resume];
}

#pragma mark - Custom

- (void)updateGameReleasePeriods{
	// Set release period for all games in Wishlist
	NSArray *games = [Game findAllWithPredicate:[NSPredicate predicateWithFormat:@"wanted = %@", @(YES)] inContext:_context];
	for (Game *game in games)
		[game setReleasePeriod:[Networking releasePeriodForReleaseDate:game.releaseDate context:_context]];
	
	[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		// Show section if it has any games
		NSArray *releasePeriods = [ReleasePeriod findAllInContext:_context];
		
		for (ReleasePeriod *releasePeriod in releasePeriods){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND wanted = %@", releasePeriod.identifier, @(YES)];
			NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
			[releasePeriod.placeholderGame setHidden:(gamesCount > 0) ? @(NO) : @(YES)];
		}
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			_fetchedResultsController = nil;
			_fetchedResultsController = [self fetchData];
			[_collectionView reloadData];
		}];
	}];
}

- (void)refreshWishlistGames{
	dispatch_async(dispatch_get_main_queue(), ^{
		[Game deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier != nil AND wanted = %@ AND owned = %@", @(NO), @(NO)]];
		[_context saveToPersistentStoreAndWait];
	});
	
	if (_fetchedResultsController.fetchedObjects.count > 0){
		[_refreshButton setEnabled:NO];
	}
	
	_numberOfRunningTasks = 0;
	
	// Request info for all games in the Wishlist
	for (NSInteger section = 0; section < _fetchedResultsController.sections.count; section++)
		for (NSInteger row = 0; row < ([_fetchedResultsController.sections[section] numberOfObjects]); row++)
			[self requestInformationForGame:[_fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]]];
}

#pragma mark - Actions

- (void)coverImageDownloadedNotification:(NSNotification *)notification{
	[_collectionView reloadData];
}

- (void)refreshWishlistNotification:(NSNotification *)notification{
	[self updateGameReleasePeriods];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		UINavigationController *navigationController = segue.destinationViewController;
		GameTableViewController *destination = (GameTableViewController *)navigationController.topViewController;
		[destination setGame:[_fetchedResultsController objectAtIndexPath:sender]];
	}
}

@end
