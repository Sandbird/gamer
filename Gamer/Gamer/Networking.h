//
//  Networking.h
//  Gamer
//
//  Created by Caio Mello on 13/10/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "Game.h"

typedef NS_ENUM(NSInteger, ReleasePeriodIdentifier){
	ReleasePeriodIdentifierNone = 0,
	ReleasePeriodIdentifierReleased = 1,
	ReleasePeriodIdentifierRecentlyReleased = 2,
	ReleasePeriodIdentifierThisWeek = 3,
	ReleasePeriodIdentifierThisMonth = 4,
	ReleasePeriodIdentifierNextMonth = 5,
	ReleasePeriodIdentifierThisQuarter = 6,
	ReleasePeriodIdentifierNextQuarter = 7,
	ReleasePeriodIdentifierThisYear = 8,
	ReleasePeriodIdentifierNextYear = 9,
	ReleasePeriodIdentifierLater = 10,
	ReleasePeriodIdentifierTBA = 11
};

@interface Networking : NSObject

+ (AFURLSessionManager *)manager;

+ (NSURLRequest *)requestForGamesWithTitle:(NSString *)title fields:(NSString *)fields platforms:(NSArray *)platforms;
+ (NSURLRequest *)requestForGameWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;
+ (NSURLRequest *)requestForVideoWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;
+ (NSURLRequest *)requestForReleasesWithGameIdentifier:(NSNumber *)gameIdentifier fields:(NSString *)fields;
+ (NSURLRequest *)requestForMetascoreWithGame:(Game *)game platform:(Platform *)platform;

+ (void)updateGameInfoWithGame:(Game *)game JSON:(NSDictionary *)JSON context:(NSManagedObjectContext *)context;
+ (void)updateGameReleasesWithGame:(Game *)game JSON:(NSDictionary *)JSON context:(NSManagedObjectContext *)context;

+ (void)setReleaseDateForGameOrRelease:(id)object dateString:(NSString *)date expectedReleaseDay:(NSInteger)day expectedReleaseMonth:(NSInteger)month expectedReleaseQuarter:(NSInteger)quarter expectedReleaseYear:(NSInteger)year;
+ (NSInteger)quarterForMonth:(NSInteger)month;
+ (ReleasePeriod *)releasePeriodForGameOrRelease:(id)object context:(NSManagedObjectContext *)context;

+ (UIColor *)colorForMetascore:(NSString *)metascore;

@end
