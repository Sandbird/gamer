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
#import "Region.h"
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
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"location = %@ AND hidden = %@", @(GameLocationWishlist), @(NO)];
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
	[self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	BOOL lastRow = (indexPath.row >= ([tableView numberOfRowsInSection:indexPath.section] - 2)) ? YES : NO;
	[cell setSeparatorInset:UIEdgeInsetsMake(0, (lastRow ? (tableView.frame.size.width * 2) : 68), 0, 0)];
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
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		UIImage *image = [_imageCache objectForKey:game.imagePath.lastPathComponent];
		
		if (image){
			dispatch_async(dispatch_get_main_queue(), ^{
				[customCell.coverImageView setImage:image];
				[customCell.coverImageView setBackgroundColor:[UIColor clearColor]];
			});
		}
		else{
			dispatch_async(dispatch_get_main_queue(), ^{
				[customCell.coverImageView setImage:nil];
				[customCell.coverImageView setBackgroundColor:[UIColor clearColor]];
			});
			
			UIImage *image = [UIImage imageWithContentsOfFile:game.imagePath];
			
			UIGraphicsBeginImageContext(image.size);
			[image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
			image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[customCell.coverImageView setImage:image];
				[customCell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
			});
			
			if (image){
				[_imageCache setObject:image forKey:game.imagePath.lastPathComponent];
			}
		}
	});
	
//	[customCell.titleLabel setText:(game.identifier) ? game.title : nil];
	[customCell.titleLabel setText:game.title];
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
		[customCell.metascoreLabel setHidden:YES];
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

- (void)requestGame:(Game *)game{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes,releases"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Game", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			_numberOfRunningTasks--;
			
			if (_numberOfRunningTasks == 0){
				[self.refreshControl endRefreshing];
				[self updateGameReleasePeriods];
			}
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Game - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
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
			[_context MR_saveToPersistentStoreAndWait];
		}
	}];
	[downloadTask resume];
}

- (void)requestRelease:(Release *)release{
	NSURLRequest *request = [Networking requestForReleaseWithIdentifier:release.identifier fields:@"platform,region,release_date,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Release", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			_numberOfRunningTasks--;
			
			if (_numberOfRunningTasks == 0){
				[self.refreshControl endRefreshing];
				[self updateGameReleasePeriods];
			}
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Release - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			//			NSLog(@"%@", responseObject);
			
			_numberOfRunningTasks--;
			
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
			
			if (_numberOfRunningTasks == 0){
				[self.refreshControl endRefreshing];
				[self updateGameReleasePeriods];
			}
		}
	}];
	[dataTask resume];
	_numberOfRunningTasks++;
}

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
		[game setReleasePeriod:[Networking releasePeriodForGameOrRelease:(game.selectedRelease ? game.selectedRelease : game) context:_context]];
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
			if (game.identifier) [self requestGame:game];
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
