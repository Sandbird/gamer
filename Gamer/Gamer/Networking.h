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
	ReleasePeriodIdentifierNextWeek = 4,
	ReleasePeriodIdentifierThisMonth = 5,
	ReleasePeriodIdentifierNextMonth = 6,
	ReleasePeriodIdentifierThisQuarter = 7,
	ReleasePeriodIdentifierNextQuarter = 8,
	ReleasePeriodIdentifierThisYear = 9,
	ReleasePeriodIdentifierNextYear = 10,
	ReleasePeriodIdentifierLater = 11,
	ReleasePeriodIdentifierTBA = 12,
	ReleasePeriodIdentifierUnknown = 13
};

@interface Networking : NSObject

+ (AFURLSessionManager *)manager;

+ (NSURLRequest *)requestForGamesWithTitle:(NSString *)title fields:(NSString *)fields platforms:(NSArray *)platforms;
+ (NSURLRequest *)requestForGamesWithIdentifiers:(NSArray *)identifiers fields:(NSString *)fields;
+ (NSURLRequest *)requestForGameWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;
+ (NSURLRequest *)requestForReleasesWithIdentifiers:(NSArray *)identifiers fields:(NSString *)fields;
+ (NSURLRequest *)requestForReleasesWithGameIdentifier:(NSNumber *)gameIdentifier fields:(NSString *)fields;
+ (NSURLRequest *)requestForVideosWithIdentifiers:(NSArray *)identifiers fields:(NSString *)fields;
+ (NSURLRequest *)requestForVideoWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;
+ (NSURLRequest *)requestForMetascoreWithGame:(Game *)game platform:(Platform *)platform;

+ (void)updateGame:(Game *)game withResults:(NSDictionary *)results context:(NSManagedObjectContext *)context;
+ (void)updateRelease:(Release *)release withResults:(NSDictionary *)results context:(NSManagedObjectContext *)context;

+ (void)setReleaseDateForGameOrRelease:(id)object dateString:(NSString *)date expectedReleaseDay:(NSInteger)day expectedReleaseMonth:(NSInteger)month expectedReleaseQuarter:(NSInteger)quarter expectedReleaseYear:(NSInteger)year;
+ (NSInteger)quarterForMonth:(NSInteger)month;
+ (ReleasePeriod *)releasePeriodForGameOrRelease:(id)object context:(NSManagedObjectContext *)context;

+ (UIColor *)colorForMetascore:(NSString *)metascore;

@end
