//
//  GamerAppDelegate.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "GamerAppDelegate.h"
#import <FlurrySDK/Flurry.h>
#import "Game.h"
#import "ReleasePeriod.h"
#import "Platform.h"
#import "ReleaseDate.h"
#import "SessionManager.h"

@implementation GamerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
	[MagicalRecord setupCoreDataStack];
	[[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
	
	//	[Flurry startSession:@"P9BVWFKVSP4PD66TGNXV"];
	
	[self.window setTintColor:[UIColor orangeColor]];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	
	[[UITabBar appearance] setBarStyle:UIBarStyleBlack];
	
	[[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
	[[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:self.window.tintColor}];
	
	// Starting data
	if ([ReleasePeriod findAll].count == 0){
		[self initializeReleasePeriods];
		[self initializePlatforms];
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
	[MagicalRecord cleanUp];
}

#pragma mark - Initialization

- (void)initializeReleasePeriods{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	
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
//		[placeholderGame setTitle:[NSString stringWithFormat:@"placeholder%@", releasePeriod.identifier]];
		[placeholderGame setReleasePeriod:releasePeriod];
		[placeholderGame setReleaseDate:releaseDate];
		[placeholderGame setHidden:@(YES)];
		
		[releasePeriod setPlaceholderGame:placeholderGame];
	}
	
	[context saveToPersistentStoreAndWait];
}

- (void)initializePlatforms{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	
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
							   @"X180"];
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
	}
	
	[context saveToPersistentStoreAndWait];
}


@end
