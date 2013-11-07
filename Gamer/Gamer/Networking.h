//
//  Networking.h
//  Gamer
//
//  Created by Caio Mello on 13/10/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Game.h"

@interface Networking : NSObject

+ (NSMutableURLRequest *)requestForGamesWithTitle:(NSString *)title fields:(NSString *)fields platforms:(NSArray *)platforms;
+ (NSMutableURLRequest *)requestForGameWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;
+ (NSMutableURLRequest *)requestForVideoWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;

+ (void)updateGame:(Game *)game withDataFromJSON:(NSDictionary *)JSON context:(NSManagedObjectContext *)context;
+ (NSURLRequest *)requestForMetascoreForGameWithTitle:(NSString *)title platform:(Platform *)platform;

+ (NSInteger)quarterForMonth:(NSInteger)month;
+ (ReleasePeriod *)releasePeriodForReleaseDate:(ReleaseDate *)releaseDate;

+ (UIColor *)colorForMetascore:(NSString *)metascore;
+ (NSString *)retrieveMetascoreFromHTML:(NSString *)HTML;

@end
