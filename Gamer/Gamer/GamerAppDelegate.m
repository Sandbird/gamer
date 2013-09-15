//
//  GamerAppDelegate.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "GamerAppDelegate.h"
#import "Game.h"
#import "ReleasePeriod.h"
#import "Platform.h"
#import "Thumbnail.h"
#import "ReleaseDate.h"
#import <AFNetworking/AFNetworking.h>

@implementation GamerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
	[MagicalRecord setupAutoMigratingCoreDataStack];
	[[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
	
	// Analytics setup
#if !(TARGET_IPHONE_SIMULATOR)
	// Google Analytics
	[[GAI sharedInstance] setTrackUncaughtExceptions:YES];
	[[GAI sharedInstance] setDispatchInterval:20];
//	[[GAI sharedInstance] setDebug:YES];
	[[GAI sharedInstance] setDefaultTracker:[[GAI sharedInstance] trackerWithTrackingId:@"UA-42707514-1"]];
#endif
	
	// UI setup
	
	[self.window setTintColor:[UIColor orangeColor]];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	
//	[[UITabBar appearance] setBarStyle:UIBarStyleBlack];
	
//	[[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
	[[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:self.window.tintColor}];
	
	UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
	UITabBarItem *wishlistTab = tabBarController.tabBar.items[0];
	[wishlistTab setImage:[UIImage imageNamed:@"WishlistTab"]];
	[wishlistTab setSelectedImage:[UIImage imageNamed:@"WishlistTabSelected"]];
	UITabBarItem *libraryTab = tabBarController.tabBar.items[1];
	[libraryTab setImage:[UIImage imageNamed:@"LibraryTab"]];
	[libraryTab setSelectedImage:[UIImage imageNamed:@"LibraryTabSelected"]];
	
	[[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];
	
	// Initial data
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	
	EKEventStore *eventStore = [[EKEventStore alloc] init];
	[SessionManager setEventStore:eventStore];
	
	Gamer *gamer = [Gamer findFirst];
	
	if (gamer){
		[SessionManager setGamer:gamer];
	}
	else {
		gamer = [Gamer createInContext:context];
		[SessionManager setGamer:gamer];
		
		NSCalendar *calendar = [NSCalendar currentCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		NSDateComponents *components = [calendar components:NSYearCalendarUnit fromDate:[NSDate date]];
		[components setYear:2051];
		
		ReleaseDate *releaseDate = [ReleaseDate createInContext:context];
		[releaseDate setDate:[calendar dateFromComponents:components]];
		
		NSArray *periods = @[@"Released", @"This Month", @"Next Month", @"This Quarter", @"Next Quarter", @"This Year", @"Next Year", @"Later", @"To Be Announced"];
		for (NSInteger period = 1; period <= periods.count; period++){
			ReleasePeriod *releasePeriod = [ReleasePeriod createInContext:context];
			[releasePeriod setIdentifier:@(period)];
			[releasePeriod setName:periods[period - 1]];
			
			Game *placeholderGame = [Game createInContext:context];
			[placeholderGame setTitle:@"ZZZ"];
			[placeholderGame setReleasePeriod:releasePeriod];
			[placeholderGame setReleaseDate:releaseDate];
			[placeholderGame setHidden:@(YES)];
			
			[releasePeriod setPlaceholderGame:placeholderGame];
		}
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			NSArray *identifiers = @[@(117), @(94), @(35), @(146), @(129), @(139), @(20), @(145)];
			NSArray *names = @[@"Nintendo 3DS",
							   @"PC",
							   @"PlayStation 3",
							   @"PlayStation 4",
							   @"PlayStation Vita",
							   @"Wii U",
							   @"Xbox 360",
							   @"Xbox One"];
			NSArray *abbreviations = @[@"3DS",
									   @"PC",
									   @"PS3",
									   @"PS4",
									   @"VITA",
									   @"WIIU",
									   @"X360",
									   @"XONE"];
			NSArray *colors = @[[UIColor colorWithRed:.764705882 green:0 blue:.058823529 alpha:1],
								[UIColor colorWithRed:0 green:0 blue:0 alpha:1],
								[UIColor colorWithRed:0 green:.039215686 blue:.525490196 alpha:1],
								[UIColor colorWithRed:.039215686 green:.254901961 blue:.588235294 alpha:1],
								[UIColor colorWithRed:0 green:.235294118 blue:.592156863 alpha:1],
								[UIColor colorWithRed:0 green:.521568627 blue:.749019608 alpha:1],
								[UIColor colorWithRed:.501960784 green:.760784314 blue:.145098039 alpha:1],
								[UIColor colorWithRed:.058823529 green:.42745098 blue:0 alpha:1]];
			
			for (NSInteger index = 0; index < identifiers.count; index++){
				Platform *platform = [Platform createInContext:context];
				[platform setIdentifier:identifiers[index]];
				[platform setName:names[index]];
				[platform setAbbreviation:abbreviations[index]];
				[platform setColor:colors[index]];
				[platform setIndex:@(index)];
			}
			
			[context saveToPersistentStoreAndWait];
		}];
	}
	
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
	// Delete non-initial thumbnails
	[Thumbnail truncateAll];
//	[Thumbnail deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"image.index > %@ OR video.index > %@", ([Tools deviceIsiPad] ? @(7) : @(1)), ([Tools deviceIsiPad] ? @(3) : @(1))]];
	
	// Delete games not opened in the last ten days
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:NSDayCalendarUnit fromDate:[NSDate date]];
	[components setDay:-10];
	NSDate *tenDaysAgo = [calendar dateByAddingComponents:components toDate:[NSDate date] options:NSCalendarWrapComponents];
	
	[Game deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"wanted = %@ AND owned = %@ AND dateLastOpened < %@", @(NO), @(NO), tenDaysAgo]];
	
	[[NSManagedObjectContext contextForCurrentThread] saveToPersistentStoreAndWait];
	
	[MagicalRecord cleanUp];
}


@end
