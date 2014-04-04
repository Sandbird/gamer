//
//  GamerAppDelegate.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "GamerAppDelegate.h"
#import "Game.h"
#import "CoverImage.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <Crashlytics/Crashlytics.h>
#import "ImportController.h"

@interface GamerAppDelegate ()

@property (nonatomic, assign) NSInteger numberOfRunningTasks;
@property (nonatomic, assign) NSInteger numberOfReleasedGamesToRefreshMetascore;

@end

@implementation GamerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
	[[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
	
	[MagicalRecord setupAutoMigratingCoreDataStack];
	
	[Session setupInitialData];
	
#if !(TARGET_IPHONE_SIMULATOR)
	// Crashlytics
	[Crashlytics startWithAPIKey:@"a807ed553e7fcb9b4a4202e44f5b25d260153417"];
#endif
	
	// UI
	[self.window setTintColor:[UIColor orangeColor]];
	
	[application setStatusBarStyle:UIStatusBarStyleLightContent];
	
	UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
	UITabBarItem *wishlistTab = tabBarController.tabBar.items.firstObject;
	[wishlistTab setImage:[UIImage imageNamed:@"WishlistTab"]];
	[wishlistTab setSelectedImage:[UIImage imageNamed:@"WishlistTabSelected"]];
	UITabBarItem *libraryTab = tabBarController.tabBar.items[1];
	[libraryTab setImage:[UIImage imageNamed:@"LibraryTab"]];
	[libraryTab setSelectedImage:[UIImage imageNamed:@"LibraryTabSelected"]];
	
	[[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];
	
	// Stuff
	[application setMinimumBackgroundFetchInterval:86400];
	
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
	[MagicalRecord cleanUp];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
	NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"location = %@ AND identifier != nil", @(GameLocationWishlist)];
	NSArray *games = [Game MR_findAllWithPredicate:predicate inContext:context];
	
	_numberOfReleasedGamesToRefreshMetascore = [games filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"released = %@", @(YES)]].count;
	
	_numberOfRunningTasks = 0;
	
	for (Game *game in games){
		[self requestInformationForGame:game context:context completionHandler:completionHandler];
	}
}

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
			NSLog(@"URL: %@", url);
			NSLog(@"ERROR: %@", error);
			if (!error){
				for (NSString *path in inboxContents){
					NSLog(@"PATH: %@", path);
					[[NSFileManager defaultManager] removeItemAtPath:[inboxDirectoryPath stringByAppendingPathComponent:path] error:&error];
				}
			}
		}];
	}
	
	return YES;
}

#pragma mark - Custom

- (void)requestInformationForGame:(Game *)game context:(NSManagedObjectContext *)context completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			NSLog(@"Failure in %@ - Status code: %ld - Background (Game)", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			_numberOfRunningTasks--;
			
			if (_numberOfRunningTasks == 0 && _numberOfReleasedGamesToRefreshMetascore == 0){
				completionHandler(UIBackgroundFetchResultNewData);
				[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
			}
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Background (Game) - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			NSLog(@"%@", responseObject);
			
			_numberOfRunningTasks--;
			
			[Networking updateGame:game withDataFromJSON:responseObject context:context];
			
//			if ([game.released isEqualToNumber:@(YES)])
//				[self requestMetascoreForGame:game context:context completionHandler:completionHandler];
			
			if (_numberOfRunningTasks == 0 && _numberOfReleasedGamesToRefreshMetascore == 0){
				completionHandler(UIBackgroundFetchResultNewData);
				[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
			}
		}
	}];
	[dataTask resume];
	_numberOfRunningTasks++;
}

//- (void)requestMetascoreForGame:(Game *)game context:(NSManagedObjectContext *)context completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
//	NSURLRequest *request = [Networking requestForMetascoreForGameWithTitle:game.title platform:game.wishlistPlatform];
//	
//	if (request.URL){
//		NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
//			NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject, request.URL.lastPathComponent]];
//			return fileURL;
//		} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//			_numberOfReleasedGamesToRefreshMetascore--;
//			
//			if (error){
//				NSLog(@"Failure in %@ - Background (Metascore)", self);
//				
//				if (_numberOfReleasedGamesToRefreshMetascore == 0){
//					completionHandler(UIBackgroundFetchResultNewData);
//					[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
//				}
//			}
//			else{
//				NSLog(@"Success in %@ - Background (Metascore) - %@", self, request.URL);
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
//				
//				[context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
//					if (_numberOfReleasedGamesToRefreshMetascore == 0){
//						completionHandler(UIBackgroundFetchResultNewData);
//						[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
//					}
//				}];
//			}
//		}];
//		[downloadTask resume];
//	}
//}

@end
