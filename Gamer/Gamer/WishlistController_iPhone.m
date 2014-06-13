//
//  WishlistController_iPhone.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
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
#import "Metascore.h"
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
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	self.fetchedResultsController = [self fetchData];
	
	self.imageCache = [NSCache new];
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
	ReleasePeriod *releasePeriod = [ReleasePeriod MR_findFirstByAttribute:@"identifier" withValue:@(sectionName.integerValue) inContext:self.context];
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
	// Set correct separator inset
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
	NSArray *games = [Game MR_findAllWithPredicate:predicate inContext:self.context];
	
	// If no more games in section, hide placeholder so section is removed
	if (games.count == 0) [game.releasePeriod.placeholderGame setHidden:@(YES)];
	
	[self.context MR_saveToPersistentStoreAndWait];
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WishlistCell *customCell = (WishlistCell *)cell;
	
	UIImage *image = [self.imageCache objectForKey:game.imagePath.lastPathComponent];
	
	if (image){
		[customCell.coverImageView setImage:image];
		[customCell.coverImageView setBackgroundColor:[UIColor clearColor]];
	}
	else{
		[customCell.coverImageView setImage:nil];
		[customCell.coverImageView setBackgroundColor:[UIColor clearColor]];
		
		__block UIImage *image = [UIImage imageWithContentsOfFile:game.imagePath];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			CGSize imageSize = [Tools sizeOfImage:image aspectFitToWidth:customCell.coverImageView.frame.size.width];
			
			UIGraphicsBeginImageContext(imageSize);
			[image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
			image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[customCell.coverImageView setImage:image];
				[customCell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
			});
			
			if (image){
				[self.imageCache setObject:image forKey:game.imagePath.lastPathComponent];
			}
		});
	}
	
	[customCell.preorderedIcon setHidden:([game.preordered isEqualToNumber:@(YES)] && [game.released isEqualToNumber:@(NO)]) ? NO : YES];
	
	if (game.selectedRelease){
		[customCell.platformLabel setText:game.selectedRelease.platform.abbreviation];
		[customCell.platformLabel setBackgroundColor:game.selectedRelease.platform.color];
		[customCell.titleLabel setText:game.selectedRelease.title];
		[customCell.dateLabel setText:game.selectedRelease.releaseDateText];
	}
	else{
		Platform *platform = game.selectedPlatforms.allObjects.firstObject;
		[customCell.platformLabel setText:platform.abbreviation];
		[customCell.platformLabel setBackgroundColor:platform.color];
		[customCell.titleLabel setText:game.title];
		[customCell.dateLabel setText:game.releaseDateText];
	}
	
	if (game.selectedMetascore){
		[customCell.metascoreLabel setText:[game.selectedMetascore.criticScore isEqualToNumber:@(0)] ? nil : [NSString stringWithFormat:@"%@", game.selectedMetascore.criticScore]];
		[customCell.metascoreLabel setTextColor:[Networking colorForMetascore:[NSString stringWithFormat:@"%@", game.selectedMetascore.criticScore]]];
	}
	else{
		[customCell.metascoreLabel setText:nil];
		[customCell.metascoreLabel setTextColor:[UIColor clearColor]];
	}
}

#pragma mark - HidingSectionView

- (void)wishlistSectionHeaderView:(WishlistSectionHeaderView *)headerView didTapReleasePeriod:(ReleasePeriod *)releasePeriod{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod = %@ AND location = %@ AND identifier != nil", releasePeriod, @(GameLocationWishlist)];
	NSArray *games = [Game MR_findAllWithPredicate:predicate inContext:self.context];
	
	// Switch hidden property of all games in section
	for (Game *game in games)
		[game setHidden:@(!headerView.hidden)];
	
	[self.context MR_saveToPersistentStoreAndWait];
}

#pragma mark - Networking

- (void)requestGame:(Game *)game{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes,images,videos"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Game", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Game - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				[Networking updateGameInfoWithGame:game JSON:responseObject context:self.context];
				
				NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
				
				UIImage *coverImage = [UIImage imageWithContentsOfFile:game.imagePath];
				
				if (!coverImage || !game.imagePath || ![game.imageURL isEqualToString:coverImageURL]){
					[self downloadCoverImageWithURL:coverImageURL game:game];
				}
				
				[self requestReleasesForGame:game];
				
				if ([game.releasePeriod.identifier compare:@(ReleasePeriodIdentifierThisWeek)] <= NSOrderedSame){
					if (game.selectedMetascore){
						[self requestMetascoreForGame:game platform:game.selectedMetascore.platform];
					}
					else{
						NSSortDescriptor *groupSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES];
						NSSortDescriptor *indexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
						NSArray *orderedPlatforms = [game.selectedPlatforms sortedArrayUsingDescriptors:@[groupSortDescriptor, indexSortDescriptor]];
						
						[self requestMetascoreForGame:game platform:orderedPlatforms.firstObject];
					}
				}
			}
		}
		
		self.numberOfRunningTasks--;
		
		if (self.numberOfRunningTasks == 0){
			[self.refreshControl endRefreshing];
			[self updateGameReleasePeriods];
		}
	}];
	[dataTask resume];
	self.numberOfRunningTasks++;
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
			[game setImageURL:URLString];
			[self.context MR_saveToPersistentStoreAndWait];
		}
	}];
	[downloadTask resume];
}

- (void)requestReleasesForGame:(Game *)game{
	NSURLRequest *request = [Networking requestForReleasesWithGameIdentifier:game.identifier fields:@"id,name,platform,region,release_date,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Releases", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Releases - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			[game setReleases:nil];
			
			[Networking updateGameReleasesWithGame:game JSON:responseObject context:self.context];
			
			[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				if (!game.selectedRelease){
					Platform *firstSelectedPlatform = [self orderedSelectedPlatformsFromGame:game].firstObject;
					for (Release *release in game.releases){
						// If game not added, release region is selected region, release platform is in selectable platforms
						if (release.platform == firstSelectedPlatform && release.region == [Session gamer].region){
							[game setSelectedRelease:release];
							[game setReleasePeriod:[Networking releasePeriodForGameOrRelease:release context:self.context]];
							
							[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
								[self updateGameReleasePeriods];
							}];
						}
					}
				}
			}];
		}
		
		self.numberOfRunningTasks--;
		
		if (self.numberOfRunningTasks == 0){
			[self.refreshControl endRefreshing];
			[self updateGameReleasePeriods];
		}
	}];
	[dataTask resume];
	self.numberOfRunningTasks++;
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
			
			[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[self.tableView reloadRowsAtIndexPaths:@[[self.fetchedResultsController indexPathForObject:game]] withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView beginUpdates];
				[self.tableView endUpdates];
			}];
		}
	}];
	[dataTask resume];
}

#pragma mark - Custom

- (void)updateGameReleasePeriods{
	// Set release period for all games in Wishlist
	NSArray *games = [Game MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"location = %@ AND identifier != nil", @(GameLocationWishlist)] inContext:self.context];
	for (Game *game in games){
		[game setReleasePeriod:[Networking releasePeriodForGameOrRelease:(game.selectedRelease ? game.selectedRelease : game) context:self.context]];
	}
	
	[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		// Show section if it has  any games
		NSArray *releasePeriods = [ReleasePeriod MR_findAllInContext:self.context];
		
		for (ReleasePeriod *releasePeriod in releasePeriods){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod = %@ AND location = %@ AND identifier != nil", releasePeriod, @(GameLocationWishlist)];
			NSInteger gamesCount = [Game MR_countOfEntitiesWithPredicate:predicate];
			[releasePeriod.placeholderGame setHidden:(gamesCount > 0) ? @(NO) : @(YES)];
		}
		
		[self.context MR_saveToPersistentStoreAndWait];
	}];
}

- (void)refreshWishlist{
	// Pop all tabs (in case an opened game is deleted)
	for (UIViewController *viewController in self.tabBarController.viewControllers){
		[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
	}
	
	if ([Session lastRefreshWasNotToday]){
		[[Session gamer] setLastRefresh:[NSDate date]];
		[self.context MR_saveToPersistentStoreAndWait];
		
		self.numberOfRunningTasks = 0;
		
		// Request info for all games in the Wishlist
		for (NSInteger section = 0; section < self.fetchedResultsController.sections.count; section++){
			for (NSInteger row = 0; row < [self.fetchedResultsController.sections[section] numberOfObjects]; row++){
				Game *game = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
				if (game.identifier) [self requestGame:game];
			}
		}
	}
	else{
		[self.refreshControl endRefreshing];
	}
}

- (NSArray *)orderedSelectedPlatformsFromGame:(Game *)game{
	NSSortDescriptor *groupSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES];
	NSSortDescriptor *indexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
	return [game.selectedPlatforms.allObjects sortedArrayUsingDescriptors:@[groupSortDescriptor, indexSortDescriptor]];
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
