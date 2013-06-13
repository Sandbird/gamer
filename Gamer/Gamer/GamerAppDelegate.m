//
//  GamerAppDelegate.m
//  Gamer
//
//  Created by Caio Mello on 12/28/12.
//  Copyright (c) 2012 Caio Mello. All rights reserved.
//

#import "GamerAppDelegate.h"
#import <FlurrySDK/Flurry.h>
#import "Game.h"
#import "ReleasePeriod.h"
#import "Platform.h"

@implementation GamerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
	[MagicalRecord setupCoreDataStack];
	[[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
	
//	[Flurry startSession:@"P9BVWFKVSP4PD66TGNXV"];
	
	[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"NavigationBarBackground"] forBarMetrics:UIBarMetricsDefault];
	[[UINavigationBar appearance] setTitleTextAttributes:@{UITextAttributeFont:[UIFont fontWithName:@"Avenir-Heavy" size:20]}];
	
	[[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"TabBarBackground"]];
	[[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:@"TabBarSelectionIndicator"]];
	[[UITabBarItem appearance] setTitleTextAttributes:@{UITextAttributeFont:[UIFont fontWithName:@"Avenir-Medium" size:12]} forState:UIControlStateNormal];
	
	// Starting data
	if ([ReleasePeriod findAll].count == 0) [self initializeReleasePeriods];
	if ([Platform findAll].count == 0) [self initializePlatforms];
	
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	
	
	
	
	
//	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
//	[Game deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"temporary == %@", @(YES)] inContext:context];
//	[context saveToPersistentStoreAndWait];
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

- (void)initializeReleasePeriods{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	
	NSArray *periods = @[@"Released", @"This Month", @"Next Month", @"This Quarter", @"Next Quarter", @"This Year", @"Next Year", @"To Be Announced"];
	for (NSInteger period = 1; period <= 8; period++){
		ReleasePeriod *releasePeriod = [[ReleasePeriod alloc] initWithEntity:[NSEntityDescription entityForName:@"ReleasePeriod" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		[releasePeriod setIdentifier:@(period)];
		[releasePeriod setName:periods[period - 1]];
	}
	
	[context saveToPersistentStoreAndWait];
}

- (void)initializePlatforms{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	
	NSArray *identifiers = @[@(117), @(94), @(35), @(146), @(129), @(139), @(20), @(145)];
	NSArray *names = @[@"Nintendo 3DS", @"PC", @"PlayStation 3", @"PlayStation 4", @"PlayStation Vita", @"Wii U", @"Xbox 360", @"Xbox One"];
	NSArray *shortNames = @[@"3DS", @"PC", @"PS3", @"PS4", @"VITA", @"WIIU", @"X360", @"XONE"];
	NSArray *colors = @[[UIColor colorWithRed:.784313725 green:0 blue:0 alpha:1], [UIColor colorWithRed:.156862745 green:.156862745 blue:.156862745 alpha:1], [UIColor colorWithRed:0 green:.117647059 blue:.62745098 alpha:1], [UIColor colorWithRed:.019607843 green:0 blue:.235294118 alpha:1], [UIColor colorWithRed:0 green:.235294118 blue:.705882353 alpha:1], [UIColor colorWithRed:0 green:.509803922 blue:.745098039 alpha:1], [UIColor colorWithRed:.31372549 green:.62745098 blue:.117647059 alpha:1], [UIColor colorWithRed:.058823529 green:.431372549 blue:0 alpha:1]];
	for (NSInteger index = 0; index < identifiers.count; index++){
		Platform *platform = [[Platform alloc] initWithEntity:[NSEntityDescription entityForName:@"Platform" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		[platform setIdentifier:identifiers[index]];
		[platform setName:names[index]];
		[platform setNameShort:shortNames[index]];
		[platform setColor:colors[index]];
	}
	
	[context saveToPersistentStoreAndWait];
}

@end
