//
//  Networking.h
//  Gamer
//
//  Created by Caio Mello on 13/10/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "Game.h"

@interface Networking : NSObject

+ (AFURLSessionManager *)manager;

+ (NSMutableURLRequest *)requestForGamesWithTitle:(NSString *)title fields:(NSString *)fields platforms:(NSArray *)platforms;
+ (NSMutableURLRequest *)requestForGameWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;
+ (NSMutableURLRequest *)requestForVideoWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;

+ (void)updateGame:(Game *)game withDataFromJSON:(NSDictionary *)JSON context:(NSManagedObjectContext *)context;
+ (NSURLRequest *)requestForMetascoreForGameWithTitle:(NSString *)title platform:(Platform *)platform;

+ (NSInteger)quarterForMonth:(NSInteger)month;
+ (ReleasePeriod *)releasePeriodForReleaseDate:(ReleaseDate *)releaseDate context:(NSManagedObjectContext *)context;

+ (UIColor *)colorForMetascore:(NSString *)metascore;
+ (NSString *)retrieveMetascoreFromHTML:(NSString *)HTML;

@end
