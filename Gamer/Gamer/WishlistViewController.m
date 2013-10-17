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

@interface WishlistViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation WishlistViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	_refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshWishlistGames)];
	_cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancelRefresh)];
	
	[self.navigationItem setRightBarButtonItem:_refreshButton];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWishlistCollectionNotification:) name:@"RefreshWishlistCollection" object:nil];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	_operationQueue = [[NSOperationQueue alloc] init];
	[_operationQueue setMaxConcurrentOperationCount:1];
	
	_fetchedResultsController = [self fetchData];
	
	// Add guide view to the view
	_guideView = [[NSBundle mainBundle] loadNibNamed:[Tools deviceIsiPad] ? @"iPad" : @"iPhone" owner:self options:nil][0];
	[self.view insertSubview:_guideView aboveSubview:_collectionView];
	[_guideView setFrame:self.view.frame];
	[_guideView setHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] set:kGAIScreenName value:@"Wishlist"];
	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
	
	[self updateGameReleasePeriods];
}

- (void)viewDidLayoutSubviews{
	[_guideView setCenter:self.view.center];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
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
	ReleasePeriod *releasePeriod = [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(sectionName.integerValue)];
	
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
	[cell.titleLabel setText:(game.identifier) ? game.title : nil];
	[cell.dateLabel setText:game.releaseDateText];
	[cell.coverImageView setImage:[UIImage imageWithData:game.thumbnailWishlist]];
	[cell.coverImageView setBackgroundColor:cell.coverImageView.image ? [UIColor clearColor] : [UIColor darkGrayColor]];
	[cell.platformLabel setText:game.wishlistPlatform.abbreviation];
	[cell.platformLabel setBackgroundColor:game.wishlistPlatform.color];
	[cell.preorderedIcon setHidden:!game.preordered.boolValue];
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:indexPath];
}

#pragma mark - Networking

- (void)requestInformationForGame:(Game *)game{
	[self.navigationItem setRightBarButtonItem:_cancelButton animated:YES];
	
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Game - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		[Networking updateGame:game withDataFromJSON:JSON context:_context];
		
		if (![JSON[@"status_code"] isEqualToNumber:@(101)]){
			NSString *coverImageURL = (JSON[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:JSON[@"results"][@"image"][@"super_url"]] : nil;
			if (!game.thumbnailWishlist || !game.thumbnailLibrary || !game.coverImage.data || ![game.coverImage.url isEqualToString:coverImageURL])
				[self downloadCoverImageForGame:game];
		}
		
		if (_operationQueue.operationCount == 0){
			[self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
			[self updateGameReleasePeriods];
		}
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Game", self, response.statusCode);
		
		if (_operationQueue.operationCount == 0){
			[self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
			[self updateGameReleasePeriods];
		}
	}];
	[_operationQueue addOperation:operation];
}

- (void)downloadCoverImageForGame:(Game *)game{
	NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:game.coverImage.url]];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:^UIImage *(UIImage *image) {
		if (image.size.width > image.size.height){
			[game.coverImage setData:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:[Tools deviceIsiPad] ? 300 : 280])];
			[game setThumbnailWishlist:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:[Tools deviceIsiPad] ? 135 : 50])];
			[game setThumbnailLibrary:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:[Tools deviceIsiPad] ? 140 : 92])];
		}
		else{
			[game.coverImage setData:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:[Tools deviceIsiPad] ? 300 : 200])];
			[game setThumbnailWishlist:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:[Tools deviceIsiPad] ? 170 : 50])];
			[game setThumbnailLibrary:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:[Tools deviceIsiPad] ? 176 : 116])];
		}
		return nil;
	} success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[_collectionView reloadData];
			
			if (_operationQueue.operationCount == 0)
				[self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
		}];
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
		if (_operationQueue.operationCount == 0)
			[self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
	}];
	[_operationQueue addOperation:operation];
}

#pragma mark - Custom

- (void)updateGameReleasePeriods{
	// Set release period for all games in Wishlist
	NSArray *games = [Game findAllWithPredicate:[NSPredicate predicateWithFormat:@"wanted = %@", @(YES)]];
	for (Game *game in games)
		[game setReleasePeriod:[Networking releasePeriodForReleaseDate:game.releaseDate]];
	
	[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		// Show section if it has any games
		NSArray *releasePeriods = [ReleasePeriod findAll];
		
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
	// Request info for all games in the Wishlist
	for (NSInteger section = 0; section < _fetchedResultsController.sections.count; section++)
		for (NSInteger row = 0; row < ([_fetchedResultsController.sections[section] numberOfObjects]); row++)
			[self requestInformationForGame:[_fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]]];
}

- (void)cancelRefresh{
	[_operationQueue cancelAllOperations];
}

#pragma mark - Actions

- (void)coverImageDownloadedNotification:(NSNotification *)notification{
	[_collectionView reloadData];
}

- (void)refreshWishlistCollectionNotification:(NSNotification *)notification{
	_fetchedResultsController = nil;
	_fetchedResultsController = [self fetchData];
	[_collectionView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		// Pop other tabs when opening game details
		for (UIViewController *viewController in self.tabBarController.viewControllers){
			[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
		}
		
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[_fetchedResultsController objectAtIndexPath:sender]];
	}
}

@end
