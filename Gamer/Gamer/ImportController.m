//
//  ImportController.m
//  Gamer
//
//  Created by Caio Mello on 26/02/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "ImportController.h"
#import "ImportCell.h"
#import "Game.h"
#import "Platform.h"
#import "Release.h"
#import "Region.h"

@interface ImportController ()

@property (nonatomic, strong) NSMutableArray *importedWishlistGames;
@property (nonatomic, strong) NSMutableArray *importedLibraryGames;

@property (nonatomic, assign) NSInteger numberOfRunningTasks;

@property (nonatomic, strong) NSCache *imageCache;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation ImportController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	self.imageCache = [NSCache new];
	
	NSDictionary *importedDictionary = [NSJSONSerialization JSONObjectWithData:self.backupData options:0 error:nil];
	NSLog(@"%@", importedDictionary);
	
	if (importedDictionary[@"games"] != [NSNull null]){
		self.importedWishlistGames = [[NSMutableArray alloc] initWithCapacity:[importedDictionary[@"games"] count]];
		self.importedLibraryGames = [[NSMutableArray alloc] initWithCapacity:[importedDictionary[@"games"] count]];
		
		for (NSDictionary *dictionary in importedDictionary[@"games"]){
			NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
			Game *game = [Game MR_findFirstByAttribute:@"identifier" withValue:identifier inContext:self.context];
			if (!game) game = [Game MR_createInContext:self.context];
			[game setIdentifier:identifier];
			[game setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"title"]]];
			[game setFinished:[Tools booleanNumberFromSourceIfNotNull:dictionary[@"finished"] withDefault:NO]];
			[game setDigital:[Tools booleanNumberFromSourceIfNotNull:dictionary[@"digital"] withDefault:NO]];
			[game setLent:[Tools booleanNumberFromSourceIfNotNull:dictionary[@"lent"] withDefault:NO]];
			[game setPreordered:[Tools booleanNumberFromSourceIfNotNull:dictionary[@"preordered"] withDefault:NO]];
			[game setLocation:[Tools integerNumberFromSourceIfNotNull:dictionary[@"location"]]];
			[game setBorrowed:[Tools integerNumberFromSourceIfNotNull:dictionary[@"borrowed"]]];
			[game setPersonalRating:[Tools integerNumberFromSourceIfNotNull:dictionary[@"personalRating"]]];
			[game setNotes:[Tools stringFromSourceIfNotNull:dictionary[@"notes"]]];
			if ([game.notes isEqualToString:@"(null)"]) [game setNotes:nil];
			
			if ([game.location isEqualToNumber:@(GameLocationWishlist)])
				[self.importedWishlistGames addObject:game];
			else if ([game.location isEqualToNumber:@(GameLocationLibrary)])
				[self.importedLibraryGames addObject:game];
			
			if (dictionary[@"selectedPlatforms"] != [NSNull null]){
				NSMutableArray *selectedPlatforms = [[NSMutableArray alloc] initWithCapacity:[dictionary[@"selectedPlatforms"] count]];
				for (NSDictionary *platformDictionary in dictionary[@"selectedPlatforms"]){
					Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:platformDictionary[@"id"] inContext:self.context];
					[selectedPlatforms addObject:platform];
				}
				
				[game setSelectedPlatforms:[NSSet setWithArray:selectedPlatforms]];
			}
			
			NSNumber *releaseIdentifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"selectedRelease"]];
			Release *release = [Release MR_findFirstByAttribute:@"identifier" withValue:releaseIdentifier inContext:self.context];
			if (!release) release = [Release MR_createInContext:self.context];
			[release setIdentifier:releaseIdentifier];
			
			[game setSelectedRelease:release];
			
			// If game not in database, download
			if (!game.releaseDate)
				[self requestGame:game];
		}
		
		NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
		self.importedWishlistGames = [self.importedWishlistGames sortedArrayUsingDescriptors:@[titleSortDescriptor]].mutableCopy;
		self.importedLibraryGames = [self.importedLibraryGames sortedArrayUsingDescriptors:@[titleSortDescriptor]].mutableCopy;
	}
	
//	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section) {
		case 0: return @"Wishlist";
		case 1: return @"Library";
		default: return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case 0: return self.importedWishlistGames.count;
		case 1: return self.importedLibraryGames.count;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = indexPath.section == 0 ? self.importedWishlistGames[indexPath.row] : self.importedLibraryGames[indexPath.row];
	
	ImportCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:game.title];
	
	UIImage *image = [self.imageCache objectForKey:game.imagePath.lastPathComponent];
	
	if (image){
		[cell.coverImageView setImage:image];
		[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
	}
	else{
		[cell.coverImageView setImage:nil];
		[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
		
		__block UIImage *image = [UIImage imageWithContentsOfFile:game.imagePath];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			CGSize imageSize = [Tools sizeOfImage:image aspectFitToWidth:cell.coverImageView.frame.size.width];
			
			UIGraphicsBeginImageContext(imageSize);
			[image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
			image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[cell.coverImageView setImage:image];
				[cell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
			});
			
			if (image){
				[self.imageCache setObject:image forKey:game.imagePath.lastPathComponent];
			}
		});
	}
	
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
	[cell setAccessoryType:game.releaseDate ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
	
	return cell;
}

#pragma mark - Networking

- (void)requestGame:(Game *)game{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes,images,videos"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Game", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			self.numberOfRunningTasks--;
			
			if (self.numberOfRunningTasks == 0){
				[self.navigationItem.rightBarButtonItem setEnabled:YES];
				
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Some games might not have downloaded properly" message:@"You can save the import and just refresh your wishlist or library later to complete the download" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alertView show];
			}
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Game - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			self.numberOfRunningTasks--;
			
			[Networking updateGameInfoWithGame:game JSON:responseObject context:self.context];
			
			NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
			
			UIImage *coverImage = [UIImage imageWithContentsOfFile:game.imagePath];
			
			if (!coverImage || !game.imagePath || ![game.imageURL isEqualToString:coverImageURL]){
				[self downloadCoverImageWithURL:coverImageURL game:game];
			}
			
			[self requestReleasesForGame:game];
			
			if (self.numberOfRunningTasks == 0){
				[self.navigationItem.rightBarButtonItem setEnabled:YES];
			}
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
			
			self.numberOfRunningTasks--;
			
			if (self.numberOfRunningTasks == 0){
				[self.navigationItem.rightBarButtonItem setEnabled:YES];
				
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Some games might not have downloaded properly" message:@"You can save the import and just refresh your wishlist or library later to complete the download" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alertView show];
			}
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Cover Image - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			self.numberOfRunningTasks--;
			
			[game setImagePath:[NSString stringWithFormat:@"%@/%@", [Tools imagesDirectory], request.URL.lastPathComponent]];
			[game setImageURL:URLString];
			
			[self.tableView reloadData];
			
			if (self.numberOfRunningTasks == 0){
				[self.navigationItem.rightBarButtonItem setEnabled:YES];
			}
		}
	}];
	[downloadTask resume];
	self.numberOfRunningTasks++;
}

- (void)requestReleasesForGame:(Game *)game{
	NSURLRequest *request = [Networking requestForReleasesWithGameIdentifier:game.identifier fields:@"id,name,platform,region,release_date,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Releases", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			self.numberOfRunningTasks--;
			
			if (self.numberOfRunningTasks == 0){
				[self.navigationItem.rightBarButtonItem setEnabled:YES];
				
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Some games might not have downloaded properly" message:@"You can save the import and just refresh your wishlist or library later to complete the download" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alertView show];
			}
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Releases - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			self.numberOfRunningTasks--;
			
			[game setReleases:nil];
			
			[Networking updateGameReleasesWithGame:game JSON:responseObject context:self.context];
			
			if (!game.selectedRelease){
				Platform *firstSelectedPlatform = [self orderedSelectedPlatformsFromGame:game].firstObject;
				for (Release *release in game.releases){
					// If game not added, release region is selected region, release platform is in selectable platforms
					if (release.platform == firstSelectedPlatform && release.region == [Session gamer].region){
						[game setSelectedRelease:release];
						[game setReleasePeriod:[Networking releasePeriodForGameOrRelease:release context:self.context]];
					}
				}
			}
			
			if (self.numberOfRunningTasks == 0){
				[self.navigationItem.rightBarButtonItem setEnabled:YES];
			}
		}
	}];
	[dataTask resume];
	self.numberOfRunningTasks++;
}

#pragma mark - Custom

- (NSArray *)orderedSelectedPlatformsFromGame:(Game *)game{
	NSSortDescriptor *groupSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES];
	NSSortDescriptor *indexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
	return [game.selectedPlatforms.allObjects sortedArrayUsingDescriptors:@[groupSortDescriptor, indexSortDescriptor]];
}

#pragma mark - Actions

- (IBAction)cancelBarButtonAction:(UIBarButtonItem *)sender{
	[self.context rollback];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveBarButtonAction:(UIBarButtonItem *)sender{
	[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
		[self dismissViewControllerAnimated:YES completion:nil];
	}];
}

@end
