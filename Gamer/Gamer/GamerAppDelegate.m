//
//  GamerAppDelegate.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "GamerAppDelegate.h"
#import "Game.h"
#import "Metascore.h"
#import "ReleasePeriod.h"
#import "Platform.h"
#import "Release.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <Crashlytics/Crashlytics.h>
#import "ImportController.h"

@implementation GamerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
	[[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
	
	[self setupAppearance];
	[self setupDatabase];
	[self setupServices];
	
	[Session setupInitialData];
	
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application{
	// Delete all games not added
	
	NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inWishlist = %@ AND inLibrary = %@", @(NO), @(NO)];
	
	NSArray *nonAddedGames = [Game MR_findAllWithPredicate:predicate inContext:context];
	
	for (Game *game in nonAddedGames){
		[[NSFileManager defaultManager] removeItemAtPath:game.imagePath error:nil];
		[game MR_deleteInContext:context];
	}
	
	[context MR_saveToPersistentStoreAndWait];
	
	[MagicalRecord cleanUp];
}

#pragma mark - Setup

- (void)setupAppearance{
	[self.window setTintColor:[UIColor orangeColor]];
	[self.window setTintAdjustmentMode:UIViewTintAdjustmentModeNormal];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	
	UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
	
	UITabBarItem *wishlistTab = tabBarController.tabBar.items.firstObject;
	[wishlistTab setImage:[UIImage imageNamed:@"WishlistTab"]];
	[wishlistTab setSelectedImage:[UIImage imageNamed:@"WishlistTabSelected"]];
	
	UITabBarItem *libraryTab = tabBarController.tabBar.items[1];
	[libraryTab setImage:[UIImage imageNamed:@"LibraryTab"]];
	[libraryTab setSelectedImage:[UIImage imageNamed:@"LibraryTabSelected"]];
	
	[[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];
	[[UIScrollView appearance] setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
}

- (void)setupDatabase{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *previousVersion = [defaults objectForKey:@"AppVersion"];
	
	if (!previousVersion){
		// First launch
		
		[defaults setObject:currentVersion forKey:@"AppVersion"];
		[defaults synchronize];
	}
	else if (![previousVersion isEqualToString:currentVersion]){
		// Not current version
		
		[defaults setObject:currentVersion forKey:@"AppVersion"];
		[defaults synchronize];
	}
	
	[MagicalRecord setupAutoMigratingCoreDataStack];
}

- (void)setupServices{
	[[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:86400];
	
#if !(TARGET_IPHONE_SIMULATOR)
	[Crashlytics startWithAPIKey:@"a807ed553e7fcb9b4a4202e44f5b25d260153417"];
#endif
}

#pragma mark - Background Fetch

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
	NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inWishlist = %@ AND identifier != nil", @(YES)];
	NSArray *games = [Game MR_findAllWithPredicate:predicate inContext:context];
	
	[self requestGames:games context:context completionHandler:completionHandler];
}

#pragma mark - Import

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
	// If import controller isn't being displayed
	if ([((UINavigationController *)self.window.rootViewController.presentedViewController).viewControllers.firstObject class] != [ImportController class]){
		
		// Dismiss any game that might be opened
		[self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];
		
		UIStoryboard *storyboard = application.delegate.window.rootViewController.storyboard;
		UINavigationController *importNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"ImportController"];
		ImportController *importController = importNavigationController.viewControllers.firstObject;
		[importController setBackupData:[NSData dataWithContentsOfURL:url]];
		
		// Show import controller
		[self.window.rootViewController presentViewController:importNavigationController animated:YES completion:^{
			// Delete used backup files in inbox directory
			NSError *error;
			NSString *inboxDirectoryPath = [NSString stringWithFormat:@"%@/Inbox", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];
			NSArray *inboxContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inboxDirectoryPath error:&error];
			
			if (!error){
				for (NSString *path in inboxContents){
					[[NSFileManager defaultManager] removeItemAtPath:[inboxDirectoryPath stringByAppendingPathComponent:path] error:&error];
				}
			}
		}];
	}
	
	return YES;
}

#pragma mark - Networking

- (void)requestGames:(NSArray *)games context:(NSManagedObjectContext *)context completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
	NSArray *identifiers = [games valueForKey:@"identifier"];
	
	NSURLRequest *request = [Networking requestForGamesWithIdentifiers:identifiers fields:@"deck,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,id,image,name,original_release_date,platforms"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			NSLog(@"Failure in %@ - Status code: %ld - Background (Game)", self, (long)((NSHTTPURLResponse *)response).statusCode);
			completionHandler(UIBackgroundFetchResultFailed);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Background (Game) - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				for (NSDictionary *dictionary in responseObject[@"results"]){
					NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
					Game *game = [games filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]].firstObject;
					
					[Networking updateGame:game withResults:dictionary context:context];
					
					if ([game.releasePeriod.identifier compare:@(ReleasePeriodIdentifierThisWeek)] <= NSOrderedSame){
						if (game.selectedMetascore){
							[self requestMetascoreForGame:game platform:game.selectedMetascore.platform context:context completionHandler:completionHandler];
						}
						else{
							[self requestMetascoreForGame:game platform:game.wishlistPlatform context:context completionHandler:completionHandler];
						}
					}
				}
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
			
			NSArray *selectedReleases = [games valueForKey:@"selectedRelease"];
			[self requestReleases:selectedReleases context:context completionHandler:completionHandler];
		}
	}];
	[dataTask resume];
}

- (void)requestReleases:(NSArray *)releases context:(NSManagedObjectContext *)context completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
	NSArray *identifiers = [releases valueForKey:@"identifier"];
	
	NSURLRequest *request = [Networking requestForReleasesWithIdentifiers:identifiers fields:@"id,name,platform,region,release_date,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Background (Releases)", self, (long)((NSHTTPURLResponse *)response).statusCode);
			completionHandler(UIBackgroundFetchResultFailed);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Background (Releases) - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				for (NSDictionary *dictionary in responseObject[@"results"]){
					NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
					Release *release = [releases filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]].firstObject;
					
					Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:dictionary[@"platform"][@"id"] inContext:context];
					if (platform){
						[Networking updateRelease:release withResults:dictionary context:context];
					}
					else{
						[release MR_deleteInContext:context];
					}
				}
			}
			
			completionHandler(UIBackgroundFetchResultNewData);
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
		}
		
		
	}];
	[dataTask resume];
}

- (void)requestMetascoreForGame:(Game *)game platform:(Platform *)platform context:(NSManagedObjectContext *)context completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
	NSURLRequest *request = [Networking requestForMetascoreWithGame:game platform:platform];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Background (Metascore)", self, (long)((NSHTTPURLResponse *)response).statusCode);
			completionHandler(UIBackgroundFetchResultFailed);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Background (Metascore) - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"result"] isKindOfClass:[NSNumber class]])
				return;
			
			NSDictionary *results = responseObject[@"result"];
			
			NSString *metacriticURL = [Tools stringFromSourceIfNotNull:results[@"url"]];
			
			Metascore *metascore = [Metascore MR_findFirstByAttribute:@"metacriticURL" withValue:metacriticURL inContext:context];
			if (!metascore) metascore = [Metascore MR_createInContext:context];
			[metascore setCriticScore:[Tools integerNumberFromSourceIfNotNull:results[@"score"]]];
			[metascore setUserScore:[Tools decimalNumberFromSourceIfNotNull:results[@"userscore"]]];
			[metascore setMetacriticURL:metacriticURL];
			[metascore setPlatform:platform];
			[game addMetascoresObject:metascore];
			
			completionHandler(UIBackgroundFetchResultNewData);
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
		}
	}];
	[dataTask resume];
}

@end
