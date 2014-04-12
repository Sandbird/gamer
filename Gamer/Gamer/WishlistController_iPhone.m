//
//  WishlistController_iPhone.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "WishlistController_iPhone.h"
#import "WishlistCell.h"
#import "Game.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "ReleasePeriod.h"
#import "SimilarGame.h"
#import "Release.h"
#import "GameController.h"
#import "WishlistSectionHeaderView.h"
#import <AFNetworking/AFNetworking.h>

@interface WishlistController_iPhone () <FetchedTableViewDelegate, WishlistSectionHeaderViewDelegate>

@property (nonatomic, strong) NSCache *imageCache;

@property (nonatomic, assign) NSInteger numberOfRunningTasks;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation WishlistController_iPhone

- (void)viewDidLoad{
    [super viewDidLoad];
	
//	[Session setup];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWishlistNotification:) name:@"RefreshWishlist" object:nil];
	
	[self.refreshControl setTintColor:[UIColor lightGrayColor]];
	
	[self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	self.fetchedResultsController = [self fetchData];
	
	_imageCache = [NSCache new];
}

- (void)viewWillAppear:(BOOL)animated{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
	
	[self updateGameReleasePeriods];
	
	[self.refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)fetchData{
	if (!self.fetchedResultsController){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hidden = %@ AND location = %@", @(NO), @(GameLocationWishlist)];
		self.fetchedResultsController = [Game MR_fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:predicate sortedBy:@"releasePeriod.identifier,releaseDate,title" ascending:YES delegate:self];
	}
	
	return self.fetchedResultsController;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	// Show guide view if table empty
	if (self.fetchedResultsController.sections.count == 0){
		UIView *view = [[NSBundle mainBundle] loadNibNamed:@"iPhone" owner:self options:nil].firstObject;
		[tableView setBackgroundView:view];
	}
	else
		[tableView setBackgroundView:nil];
	
	return self.fetchedResultsController.sections.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
	NSString *sectionName = [self.fetchedResultsController.sections[section] name];
	ReleasePeriod *releasePeriod = [ReleasePeriod MR_findFirstByAttribute:@"identifier" withValue:@(sectionName.integerValue) inContext:_context];
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
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[game setLocation:@(GameLocationNone)];
	[game setSelectedPlatforms:nil];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod = %@ AND location = %@", game.releasePeriod, @(GameLocationWishlist)];
	NSArray *games = [Game MR_findAllWithPredicate:predicate inContext:_context];
	
	// If no more games in section, hide placeholder so section is removed
	if (games.count == 0) [game.releasePeriod.placeholderGame setHidden:@(YES)];
	
	[_context MR_saveToPersistentStoreAndWait];
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WishlistCell *customCell = (WishlistCell *)cell;
	
	UIImage *image = [_imageCache objectForKey:game.imagePath.lastPathComponent];
	
	if (image){
		[customCell.coverImageView setImage:image];
		[customCell.coverImageView setBackgroundColor:[UIColor clearColor]];
	}
	else{
		[customCell.coverImageView setImage:nil];
		[customCell.coverImageView setBackgroundColor:[UIColor clearColor]];
		
		UIImage *image = [UIImage imageWithContentsOfFile:game.imagePath];
		
		UIGraphicsBeginImageContext(image.size);
		[image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		[customCell.coverImageView setImage:image];
		[customCell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
		
		if (image){
			[_imageCache setObject:image forKey:game.imagePath.lastPathComponent];
		}
	}
	
	[customCell.titleLabel setText:(game.identifier) ? game.title : nil];
	[customCell.dateLabel setText:game.selectedRelease ? game.selectedRelease.releaseDateText : game.releaseDateText];
	[customCell.preorderedIcon setHidden:([game.preordered isEqualToNumber:@(YES)] && [game.released isEqualToNumber:@(NO)]) ? NO : YES];
	
	if (game.selectedPlatforms.count == 1){
		Platform *platform = game.selectedPlatforms.allObjects.firstObject;
		[customCell.platformLabel setText:platform.abbreviation];
		[customCell.platformLabel setBackgroundColor:platform.color];
	}
	else{
		[customCell.platformLabel setText:nil];
		[customCell.platformLabel setBackgroundColor:[UIColor clearColor]];
	}
	
//	if ([game.released isEqualToNumber:@(YES)] && game.wishlistMetascore.length > 0 && game.wishlistMetascorePlatform == game.wishlistPlatform){
//		[customCell.metascoreLabel setHidden:NO];
//		[customCell.metascoreLabel setText:game.wishlistMetascore];
//		[customCell.metascoreLabel setTextColor:[Networking colorForMetascore:game.wishlistMetascore]];
//	}
//	else
//		[customCell.metascoreLabel setHidden:YES];
}

#pragma mark - HidingSectionView

- (void)wishlistSectionHeaderView:(WishlistSectionHeaderView *)headerView didTapReleasePeriod:(ReleasePeriod *)releasePeriod{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod = %@ AND location = %@ AND identifier != nil", releasePeriod, @(GameLocationWishlist)];
	NSArray *games = [Game MR_findAllWithPredicate:predicate inContext:_context];
	
	// Switch hidden property of all games in section
	for (Game *game in games)
		[game setHidden:@(!headerView.hidden)];
	
	[_context MR_saveToPersistentStoreAndWait];
}

#pragma mark - Networking

- (void)requestInformationForGame:(Game *)game{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes,releases"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Game", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			_numberOfRunningTasks--;
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Game - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			_numberOfRunningTasks--;
			
			[Networking updateGame:game withDataFromJSON:responseObject context:_context];
			
//			if (![responseObject[@"status_code"] isEqualToNumber:@(101)]){
//				NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
//				
//				UIImage *thumbnail = [UIImage imageWithData:game.thumbnailWishlist];
//				CGSize optimalSize = [Session optimalCoverImageSizeForImage:thumbnail type:GameImageTypeWishlist];
//				
//				if (!game.thumbnailWishlist || !game.thumbnailLibrary || !game.coverImage.data || ![game.coverImage.url isEqualToString:coverImageURL] || (thumbnail.size.width != optimalSize.width || thumbnail.size.height != optimalSize.height)){
//					[self downloadCoverImageForGame:game];
//				}
//			}
//			
//			if ([game.released isEqualToNumber:@(YES)])
//				[self requestMetascoreForGame:game];
		}
		
		if (_numberOfRunningTasks == 0){
			[self.refreshControl endRefreshing];
			[self updateGameReleasePeriods];
		}
	}];
	[dataTask resume];
	_numberOfRunningTasks++;
}

//- (void)downloadCoverImageForGame:(Game *)game{
//	if (!game.coverImage.url) return;
//	
//	NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:game.coverImage.url]];
//	
//	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
//		NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject, request.URL.lastPathComponent]];
//		return fileURL;
//	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//		if (error){
//			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Thumbnail", self, (long)((NSHTTPURLResponse *)response).statusCode);
//		}
//		else{
//			NSLog(@"Success in %@ - Status code: %ld - Thumbnail - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			
//			UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
//			[game.coverImage setData:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeCover])];
//			[game setThumbnailWishlist:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeWishlist])];
//			[game setThumbnailLibrary:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeLibrary])];
//			
//			[_context MR_saveToPersistentStoreAndWait];
//		}
//	}];
//	[downloadTask resume];
//}

//- (void)requestMetascoreForGame:(Game *)game{
//	NSURLRequest *request = [Networking requestForMetascoreForGameWithTitle:game.title platform:game.wishlistPlatform];
//	
//	if (request.URL){
//		NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
//			NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject, request.URL.lastPathComponent]];
//			return fileURL;
//		} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//			if (error){
//				NSLog(@"Failure in %@ - Metascore", self);
//			}
//			else{
//				NSLog(@"Success in %@ - Metascore - %@", self, request.URL);
//				
//				NSString *HTML = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:filePath] encoding:NSUTF8StringEncoding];
//				
//				[game setMetacriticURL:request.URL.absoluteString];
//				
//				if (HTML){
//					NSString *metascore = [Networking retrieveMetascoreFromHTML:HTML];
//					if (metascore.length > 0 && [[NSScanner scannerWithString:metascore] scanInteger:nil]){
//						[game setWishlistMetascore:metascore];
//						[game setWishlistMetascorePlatform:game.wishlistPlatform];
//					}
//					else{
//						[game setWishlistMetascore:nil];
//						[game setWishlistMetascorePlatform:nil];
//					}
//				}
//				[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
//					[self.tableView reloadData];
//				}];
//			}
//		}];
//		[downloadTask resume];
//	}
//}

#pragma mark - Custom

- (void)updateGameReleasePeriods{
	// Set release period for all games in Wishlist
	NSArray *games = [Game MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"location = %@ AND identifier != nil", @(GameLocationWishlist)] inContext:_context];
	for (Game *game in games){
		if (game.selectedRelease)
			[game setReleasePeriod:[Networking releasePeriodForGameOrRelease:game.selectedRelease context:_context]];
		else
			[game setReleasePeriod:[Networking releasePeriodForGameOrRelease:game context:_context]];
	}
	
	[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		// Show section if it has  any games
		NSArray *releasePeriods = [ReleasePeriod MR_findAllInContext:_context];
		
		for (ReleasePeriod *releasePeriod in releasePeriods){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod = %@ AND location = %@ AND identifier != nil", releasePeriod, @(GameLocationWishlist)];
			NSInteger gamesCount = [Game MR_countOfEntitiesWithPredicate:predicate];
			[releasePeriod.placeholderGame setHidden:(gamesCount > 0) ? @(NO) : @(YES)];
		}
		
		[_context MR_saveToPersistentStoreAndWait];
	}];
}

- (void)refreshWishlist{
	// Pop all tabs (in case an opened game is deleted)
	for (UIViewController *viewController in self.tabBarController.viewControllers){
		[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
	}
	
	_numberOfRunningTasks = 0;
	
	// Request info for all games in the Wishlist
	for (NSInteger section = 0; section < self.fetchedResultsController.sections.count; section++){
		for (NSInteger row = 0; row < [self.fetchedResultsController.sections[section] numberOfObjects]; row++){
			Game *game = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
			if (game.identifier) [self requestInformationForGame:game];
		}
	}
}

#pragma mark - Actions

- (IBAction)refreshControlValueChangedAction:(UIRefreshControl *)sender{
	[self refreshWishlist];
}

- (void)coverImageDownloadedNotification:(NSNotification *)notification{
	[self.tableView reloadData];
}

- (void)refreshWishlistNotification:(NSNotification *)notification{
	[self updateGameReleasePeriods];
	[self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		// Pop other tabs when opening game details
		for (UIViewController *viewController in self.tabBarController.viewControllers){
			[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
		}
		
		GameController *destination = [segue destinationViewController];
		[destination setGame:[self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
	}
}

@end
