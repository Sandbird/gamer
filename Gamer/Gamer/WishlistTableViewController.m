//
//  WishlistTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "WishlistTableViewController.h"
#import "WishlistCell.h"
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
#import "WishlistSectionHeaderView.h"
#import <AFNetworking/AFNetworking.h>

@interface WishlistTableViewController () <FetchedTableViewDelegate, WishlistSectionHeaderViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation WishlistTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[SessionManager setup];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	_refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshWishlistGames)];
	_cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancelRefresh)];
	
	[self.navigationItem setRightBarButtonItem:_refreshButton];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWishlistNotification:) name:@"RefreshWishlistTable" object:nil];
	
	[self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
	
	_context = [NSManagedObjectContext defaultContext];
	
	self.fetchedResultsController = [self fetchData];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] set:kGAIScreenName value:@"Wishlist"];
	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
	
	[self updateGameReleasePeriods];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)fetchData{
	if (!self.fetchedResultsController){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hidden = %@ AND (wanted = %@ OR identifier = nil)", @(NO), @(YES)];
		self.fetchedResultsController = [Game fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:predicate sortedBy:@"releasePeriod.identifier,releaseDate.date,title" ascending:YES delegate:self];
	}
	
	return self.fetchedResultsController;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	// Show guide view if table empty
	if (self.fetchedResultsController.sections.count == 0){
		UIView *view = [[NSBundle mainBundle] loadNibNamed:@"iPhone" owner:self options:nil][0];
		[tableView setBackgroundView:view];
	}
	else
		[tableView setBackgroundView:nil];
	
    return self.fetchedResultsController.sections.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
	NSString *sectionName = [self.fetchedResultsController.sections[section] name];
	ReleasePeriod *releasePeriod = [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(sectionName.integerValue) inContext:_context];
	
	WishlistSectionHeaderView *headerView = [[WishlistSectionHeaderView alloc] initWithReleasePeriod:releasePeriod];
	[headerView setDelegate:self];
	
	return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	return (game.identifier) ? tableView.rowHeight : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    WishlistCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	BOOL lastRow = (indexPath.row >= ([tableView numberOfRowsInSection:indexPath.section] - 2)) ? YES : NO;
	[cell setSeparatorInset:UIEdgeInsetsMake(0, (lastRow ? (tableView.frame.size.width * 2) : 68), 0, 0)];
	
	[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[game setWanted:@(NO)];
	[game setWishlistPlatform:nil];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND wanted = %@", game.releasePeriod.identifier, @(YES)];
	NSArray *games = [Game findAllWithPredicate:predicate inContext:_context];
	
	// If no more games in section, hide placeholder so section is removed
	if (games.count == 0) [game.releasePeriod.placeholderGame setHidden:@(YES)];
	
	[_context saveToPersistentStoreAndWait];
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WishlistCell *customCell = (WishlistCell *)cell;
	[customCell.titleLabel setText:(game.identifier) ? game.title : nil];
	[customCell.dateLabel setText:game.releaseDateText];
	[customCell.coverImageView setImage:[UIImage imageWithData:game.thumbnailWishlist]];
	[customCell.coverImageView setBackgroundColor:customCell.coverImageView.image ? [UIColor clearColor] : [UIColor darkGrayColor]];
	[customCell.preorderedIcon setHidden:([game.preordered isEqualToNumber:@(YES)] && [game.released isEqualToNumber:@(NO)]) ? NO : YES];
	[customCell.platformLabel setText:game.wishlistPlatform.abbreviation];
	[customCell.platformLabel setBackgroundColor:game.wishlistPlatform.color];
	
	if ([game.released isEqualToNumber:@(YES)] && game.wishlistMetascore.length > 0 && game.wishlistMetascorePlatform == game.wishlistPlatform){
		[customCell.metascoreLabel setHidden:NO];
		[customCell.metascoreLabel setText:game.wishlistMetascore];
		[customCell.metascoreLabel setTextColor:[Networking colorForMetascore:game.wishlistMetascore]];
	}
	else
		[customCell.metascoreLabel setHidden:YES];
}

#pragma mark - HidingSectionView

- (void)wishlistSectionHeaderView:(WishlistSectionHeaderView *)headerView didTapReleasePeriod:(ReleasePeriod *)releasePeriod{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND wanted = %@", releasePeriod.identifier, @(YES)];
	NSArray *games = [Game findAllWithPredicate:predicate inContext:_context];
	
	// Switch hidden property of all games in section
	for (Game *game in games)
		[game setHidden:@(!game.hidden.boolValue)];
	
	[_context saveToPersistentStoreAndWait];
}

#pragma mark - Networking

- (void)requestInformationForGame:(Game *)game{
	[self.navigationItem setRightBarButtonItem:_cancelButton animated:YES];
	
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Game", self, ((NSHTTPURLResponse *)response).statusCode);
			
			if ([Networking manager].dataTasks.count == 0){
				[self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
				[self updateGameReleasePeriods];
			}
		}
		else{
			NSLog(@"Success in %@ - Status code: %d - Game - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			//		NSLog(@"%@", JSON);
			
			[Networking updateGame:game withDataFromJSON:responseObject context:_context];
			
			if (![responseObject[@"status_code"] isEqualToNumber:@(101)]){
				NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
				
				UIImage *coverImage = [UIImage imageWithData:game.coverImage.data];
				CGSize optimalSize = [SessionManager optimalCoverImageSizeForImage:coverImage];
				
				if (!game.thumbnailWishlist || !game.thumbnailLibrary || !game.coverImage.data || ![game.coverImage.url isEqualToString:coverImageURL] || (coverImage.size.width != optimalSize.width || coverImage.size.height != optimalSize.height)){
					[self downloadCoverImageForGame:game];
				}
			}
			
			if ([game.released isEqualToNumber:@(YES)])
				[self requestMetascoreForGame:game];
			
			if ([Networking manager].dataTasks.count == 0){
				[self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
				[self updateGameReleasePeriods];
			}
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
			if ([Networking manager].downloadTasks.count == 0){
				[self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
			}
		}
		else{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
				[game.coverImage setData:UIImagePNGRepresentation([SessionManager aspectFitImageWithImage:downloadedImage type:GameImageTypeCover])];
				[game setThumbnailWishlist:UIImagePNGRepresentation([SessionManager aspectFitImageWithImage:downloadedImage type:GameImageTypeWishlist])];
				[game setThumbnailLibrary:UIImagePNGRepresentation([SessionManager aspectFitImageWithImage:downloadedImage type:GameImageTypeLibrary])];
				
				[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					dispatch_async(dispatch_get_main_queue(), ^{
						if ([Networking manager].downloadTasks.count == 0){
							[self.navigationItem setRightBarButtonItem:_refreshButton animated:YES];
						}
					});
				}];
			});
		}
	}];
	[downloadTask resume];
}

- (void)requestMetascoreForGame:(Game *)game{
	NSURLRequest *request = [Networking requestForMetascoreForGameWithTitle:game.title platform:game.wishlistPlatform];
	
	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		return [NSURL fileURLWithPath:[NSString stringWithFormat:@"/tmp/%@", request.URL.lastPathComponent]];
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		if (error){
			NSLog(@"Failure in %@ - Metascore", self);
		}
		else{
			NSLog(@"Success in %@ - Metascore - %@", self, request.URL);
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
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
				[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					dispatch_async(dispatch_get_main_queue(), ^{
						if ([Networking manager].downloadTasks.count == 0){
							[self.tableView reloadData];
						}
					});
				}];
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
		// Show section if it has  any games
		NSArray *releasePeriods = [ReleasePeriod findAllInContext:_context];
		
		for (ReleasePeriod *releasePeriod in releasePeriods){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND wanted = %@", releasePeriod.identifier, @(YES)];
			NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
			[releasePeriod.placeholderGame setHidden:(gamesCount > 0) ? @(NO) : @(YES)];
		}
		
		[_context saveToPersistentStoreAndWait];
	}];
}

- (void)refreshWishlistGames{
	dispatch_async(dispatch_get_main_queue(), ^{
		[Game deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier != nil AND wanted = %@ AND owned = %@", @(NO), @(NO)]];
		[_context saveToPersistentStoreAndWait];
	});
	
	// Request info for all games in the Wishlist
	for (NSInteger section = 0; section < self.fetchedResultsController.sections.count; section++)
		for (NSInteger row = 0; row < [self.fetchedResultsController.sections[section] numberOfObjects]; row++){
			Game *game = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
			if (game.identifier) [self requestInformationForGame:game];
		}
}

- (void)cancelRefresh{
	[[Networking manager].operationQueue cancelAllOperations];
}

#pragma mark - Actions

- (void)coverImageDownloadedNotification:(NSNotification *)notification{
	[self.tableView reloadData];
}

- (void)refreshWishlistNotification:(NSNotification *)notification{
	[self updateGameReleasePeriods];
	
//	self.fetchedResultsController = nil;
//	self.fetchedResultsController = [self fetchData];
	[self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		// Pop other tabs when opening game details
		for (UIViewController *viewController in self.tabBarController.viewControllers){
			[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
		}
		
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
	}
}

@end
