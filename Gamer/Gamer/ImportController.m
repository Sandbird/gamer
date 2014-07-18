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
#import "NSArray+Split.h"

@interface ImportController ()

@property (nonatomic, strong) NSMutableArray *importedGames;

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
		self.importedGames = [[NSMutableArray alloc] initWithCapacity:[importedDictionary[@"games"] count]];
		
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
			[game setBorrowed:[Tools booleanNumberFromSourceIfNotNull:dictionary[@"borrowed"] withDefault:NO]];
			[game setRented:[Tools booleanNumberFromSourceIfNotNull:dictionary[@"rented"] withDefault:NO]];
			[game setPersonalRating:[Tools integerNumberFromSourceIfNotNull:dictionary[@"personalRating"]]];
			[game setNotes:[Tools stringFromSourceIfNotNull:dictionary[@"notes"]]];
			if ([game.notes isEqualToString:@"(null)"]) [game setNotes:nil];
			[game setInWishlist:[Tools booleanNumberFromSourceIfNotNull:dictionary[@"inWishlist"] withDefault:NO]];
			[game setInLibrary:[Tools booleanNumberFromSourceIfNotNull:dictionary[@"inLibrary"] withDefault:NO]];
			
			if (dictionary[@"selectedRelease"] != [NSNull null]){
				if (dictionary[@"selectedRelease"][@"id"] != [NSNull null]){
					Release *release = [Release MR_findFirstByAttribute:@"identifier" withValue:dictionary[@"selectedRelease"][@"id"] inContext:self.context];
					if (!release) [Release MR_createInContext:self.context];
					[release setIdentifier:dictionary[@"selectedRelease"][@"id"]];
					[game setSelectedRelease:release];
				}
			}
			
			// Wishlist platforms
			if (dictionary[@"wishlistPlatform"] != [NSNull null]){
				if (dictionary[@"wishlistPlatform"][@"id"] != [NSNull null]){
					Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:dictionary[@"wishlistPlatform"][@"id"] inContext:self.context];
					[game setWishlistPlatform:platform];
				}
			}
			
			// Library platforms
			if (dictionary[@"libraryPlatforms"] != [NSNull null]){
				NSMutableArray *libraryPlatforms = [[NSMutableArray alloc] initWithCapacity:[dictionary[@"libraryPlatforms"] count]];
				for (NSDictionary *platformDictionary in dictionary[@"libraryPlatforms"]){
					Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:platformDictionary[@"id"] inContext:self.context];
					[libraryPlatforms addObject:platform];
				}
				[game setLibraryPlatforms:[NSSet setWithArray:libraryPlatforms]];
			}
			
			// If backup from older version, get wishlist and library attributes from location and selected platforms
			NSNumber *location = [Tools integerNumberFromSourceIfNotNull:dictionary[@"location"]];
			if (location){
				if (dictionary[@"selectedPlatforms"] != [NSNull null]){
					NSMutableArray *selectedPlatforms = [[NSMutableArray alloc] initWithCapacity:[dictionary[@"selectedPlatforms"] count]];
					for (NSDictionary *platformDictionary in dictionary[@"selectedPlatforms"]){
						Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:platformDictionary[@"id"] inContext:self.context];
						[selectedPlatforms addObject:platform];
					}
					
					if ([location isEqualToNumber:@(1)]){
						[game setInWishlist:@(YES)];
						[game setWishlistPlatform:selectedPlatforms.firstObject];
					}
					else{
						[game setInLibrary:@(YES)];
						[game setLibraryPlatforms:[NSSet setWithArray:selectedPlatforms]];
					}
				}
			}
			
			[self.importedGames addObject:game];
		}
		
		// Sort imported games by title
		NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
		self.importedGames = [self.importedGames sortedArrayUsingDescriptors:@[titleSortDescriptor]].mutableCopy;
		
		// Request games
		NSArray *splitGamesArray = [NSArray splitArray:self.importedGames componentsPerSegment:100];
		for (NSArray *games in splitGamesArray){
			[self requestGames:games];
		}
		
		// Request releases
		NSArray *releases = [self.importedGames valueForKey:@"selectedRelease"];
		
		NSArray *splitReleasesArray = [NSArray splitArray:releases componentsPerSegment:100];
		for (NSArray *releases in splitReleasesArray){
			[self requestReleases:releases];
		}
	}
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return self.importedGames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = self.importedGames[indexPath.row];
	
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

- (void)requestGames:(NSArray *)games{
	NSArray *identifiers = [games valueForKey:@"identifier"];
	
	NSURLRequest *request = [Networking requestForGamesWithIdentifiers:identifiers fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes,images,videos,releases"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Games", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Games - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
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
				}
			}
		}
		
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}];
	[dataTask resume];
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
					
					[Networking updateRelease:release withResults:dictionary context:self.context];
				}
			}
		}
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
			
			[game setImagePath:[NSString stringWithFormat:@"%@/%@", [Tools imagesDirectory], request.URL.lastPathComponent]];
			[game setImageURL:URLString];
			
			[self.tableView reloadData];
		}
	}];
	[downloadTask resume];
}

#pragma mark - Actions

- (IBAction)cancelBarButtonAction:(UIBarButtonItem *)sender{
	[[Networking manager] invalidateSessionCancelingTasks:YES]; // crashing subsequent requests
	
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
