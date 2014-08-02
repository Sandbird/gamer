//
//  WishlistController.m
//  Gamer
//
//  Created by Caio Mello on 02/08/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "WishlistController.h"
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
#import "SearchController_iPad.h"
#import "NSArray+Split.h"
#import "WishlistTableCell.h"
#import "BlurHeaderView.h"

@interface WishlistController () <WishlistTableCellCollectionViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *searchBarItem;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation WishlistController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	self.refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshWishlistGames)];
	
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 256, 44)];
	[searchBar setPlaceholder:@"Find Games"];
	[searchBar setDelegate:self];
	self.searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
	
	[self.navigationItem setRightBarButtonItems:@[self.searchBarItem, self.refreshButton] animated:NO];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWishlistNotification:) name:@"RefreshWishlist" object:nil];
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	self.fetchedResultsController = [self fetchData];
	
//	self.imageCache = [NSCache new];
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	
	[(UISearchBar *)self.searchBarItem.customView setText:[Session searchQuery]];
}

- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	
	[self updateGameReleasePeriods];
}

- (void)viewDidLayoutSubviews{
	[super viewDidLayoutSubviews];
	
	[_guideView setCenter:self.view.center];
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

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)fetchData{
	if (!self.fetchedResultsController){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inWishlist = %@ AND identifier != nil", @(YES)];
		self.fetchedResultsController = [Game MR_fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:predicate sortedBy:@"releasePeriod.identifier,releaseDate,title" ascending:YES];
	}
	return self.fetchedResultsController;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	// Show guide view if table empty
	if (self.fetchedResultsController.sections.count == 0){
		UIView *view = [[NSBundle mainBundle] loadNibNamed:@"iPad" owner:self options:nil][ViewIndexWishlistGuideView];
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
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	NSArray *games = [self.fetchedResultsController.sections[indexPath.section] objects];
	
	WishlistTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell setDelegate:self];
	[cell setGames:games];
	[cell.collectionView reloadData];
	return cell;
}

#pragma mark - WishlistTableCellCollectionView

- (void)wishlistTableCellCollectionView:(UICollectionView *)collectionView didSelectGame:(Game *)game{
	[self performSegueWithIdentifier:@"GameSegue" sender:game];
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
		
		[self.refreshButton setEnabled:YES];
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
					
					[self.tableView reloadData];
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
		
		[self.refreshButton setEnabled:YES];
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
			
			[self.context MR_saveToPersistentStoreWithCompletion:nil];
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
	
	[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		self.fetchedResultsController = nil;
		self.fetchedResultsController = [self fetchData];
		[self.tableView reloadData];
	}];
}

- (void)refreshWishlistGames{
	if (self.fetchedResultsController.fetchedObjects.count > 0){
		[self.refreshButton setEnabled:NO];
	}
	
	NSArray *splitArray = [NSArray splitArray:self.fetchedResultsController.fetchedObjects componentsPerSegment:100];
	for (NSArray *array in splitArray){
		[self requestGames:array];
	}
}

- (void)refreshWishlistSelectedReleases{
	NSMutableArray *selectedReleases = [[NSMutableArray alloc] initWithCapacity:self.fetchedResultsController.fetchedObjects.count];
	
	for (NSInteger section = 0; section < self.fetchedResultsController.sections.count; section++){
		for (NSInteger row = 0; row < [self.fetchedResultsController.sections[section] numberOfObjects]; row++){
			Game *game = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
			
			if (game.selectedRelease)
				[selectedReleases addObject:game.selectedRelease];
		}
	}
	
	NSArray *splitReleases = [NSArray splitArray:selectedReleases componentsPerSegment:100];
	for (NSArray *releases in splitReleases){
		[self requestReleases:releases];
	}
	
	[self requestReleases:selectedReleases];
}

#pragma mark - Actions

- (void)coverImageDownloadedNotification:(NSNotification *)notification{
	[self.tableView reloadData];
}

- (void)refreshWishlistNotification:(NSNotification *)notification{
	[self updateGameReleasePeriods];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		UINavigationController *navigationController = segue.destinationViewController;
		GameController *destination = (GameController *)navigationController.topViewController;
		[destination setGame:sender];
	}
}

@end
