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
#import <AFNetworking/AFNetworking.h>
#import "BlurHeaderView.h"
#import "NSArray+Split.h"

@interface WishlistController_iPhone () <FetchedTableViewDelegate>

@property (nonatomic, strong) NSCache *imageCache;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation WishlistController_iPhone

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWishlistNotification:) name:@"RefreshWishlist" object:nil];
	
	[self.refreshControl setTintColor:[UIColor lightGrayColor]];
	
//	[self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	self.fetchedResultsController = [self fetchData];
	
	self.imageCache = [NSCache new];
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	
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
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inWishlist = %@", @(YES), @(NO)];
		self.fetchedResultsController = [Game MR_fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:predicate sortedBy:@"releasePeriod.identifier,releaseDate,title" ascending:YES delegate:self];
	}
	
	return self.fetchedResultsController;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	// Show guide view if table empty
	if (self.fetchedResultsController.sections.count == 0){
		UIView *view = [[NSBundle mainBundle] loadNibNamed:@"iPhone" owner:self options:nil][ViewIndexWishlistGuideView];
		[tableView setBackgroundView:view];
	}
	else
		[tableView setBackgroundView:nil];
	
	return self.fetchedResultsController.sections.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
	NSString *sectionName = [self.fetchedResultsController.sections[section] name];
	ReleasePeriod *releasePeriod = [ReleasePeriod MR_findFirstByAttribute:@"identifier" withValue:@(sectionName.integerValue) inContext:self.context];
	BlurHeaderView *headerView = [[BlurHeaderView alloc] initWithTitle:releasePeriod.name leftMargin:tableView.separatorInset.left];
	return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	WishlistCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
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
	[game setInWishlist:@(NO)];
	[game setWishlistPlatform:nil];
	[self.context MR_saveToPersistentStoreWithCompletion:nil];
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
				
				if (image){
					[self.imageCache setObject:image forKey:game.imagePath.lastPathComponent];
				}
			});
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
		Platform *platform = game.wishlistPlatform;
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
	
	// Hide/show cell separator
	BOOL lastRow = (indexPath.row >= ([self.tableView numberOfRowsInSection:indexPath.section] - 1)) ? YES : NO;
	[customCell.separatorView setHidden:lastRow];
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
					
					if ([game.releasePeriod.identifier compare:@(ReleasePeriodIdentifierThisWeek)] <= NSOrderedSame){
						if (game.selectedMetascore){
							[self requestMetascoreForGame:game platform:game.selectedMetascore.platform];
						}
						else{
							[self requestMetascoreForGame:game platform:game.wishlistPlatform];
						}
					}
				}
			}
		}
		
		[self.refreshControl endRefreshing];
		[self updateGameReleasePeriods];
		[self refreshWishlistSelectedReleases];
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
					[self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
				});
			});
		}
	}];
	[downloadTask resume];
}

- (void)requestReleases:(NSArray *)releases{
	NSArray *identifiers = [releases valueForKey:@"identifier"];
	
	NSURLRequest *request = [Networking requestForReleasesWithIdentifiers:identifiers fields:@"id,name,platform,region,release_date,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Releases", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Releases - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				for (NSDictionary *dictionary in responseObject[@"results"]){
					NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
					Release *release = [releases filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]].firstObject;
					
					Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:dictionary[@"platform"][@"id"] inContext:self.context];
					if (platform){
						[Networking updateRelease:release withResults:dictionary context:self.context];
					}
					else{
						[release MR_deleteInContext:self.context];
					}
				}
			}
		}
		
		[self.refreshControl endRefreshing];
		[self updateGameReleasePeriods];
	}];
	[dataTask resume];
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
	NSArray *games = [Game MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"inWishlist = %@ AND identifier != nil", @(YES)] inContext:self.context];
	for (Game *game in games){
		[game setReleasePeriod:[Networking releasePeriodForGameOrRelease:(game.selectedRelease ? game.selectedRelease : game) context:self.context]];
	}
	
	[self.context MR_saveToPersistentStoreWithCompletion:nil];
}

- (void)refreshWishlistGames{
	// Pop all tabs (in case an opened game is deleted)
	for (UIViewController *viewController in self.tabBarController.viewControllers){
		[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
	}
	
	NSArray *splitArray = [NSArray splitArray:self.fetchedResultsController.fetchedObjects componentsPerSegment:100];
	for (NSArray *array in splitArray){
		[self requestGames:array];
	}
}

- (void)refreshWishlistSelectedReleases{
	NSArray *selectedReleases = [self.fetchedResultsController.fetchedObjects valueForKey:@"selectedRelease"];
	
	NSArray *splitReleases = [NSArray splitArray:selectedReleases componentsPerSegment:100];
	for (NSArray *releases in splitReleases){
		[self requestReleases:releases];
	}
}

#pragma mark - Actions

- (IBAction)refreshControlValueChangedAction:(UIRefreshControl *)sender{
	[self refreshWishlistGames];
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
