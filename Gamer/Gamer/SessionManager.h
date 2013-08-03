//
//  SessionManager.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleAnalytics-iOS-SDK/GAI.h>
#import <EventKit/EventKit.h>
#import "Gamer.h"

@interface SessionManager : NSObject

+ (void)setGamer:(Gamer *)gamer;

+ (Gamer *)gamer;

+ (void)setEventStore:(EKEventStore *)eventStore;

+ (EKEventStore *)eventStore;

+ (BOOL)calendarEnabled;

+ (id<GAITracker>)tracker;

+ (NSMutableURLRequest *)URLRequestForGamesWithFields:(NSString *)fields platforms:(NSArray *)platforms name:(NSString *)name;

+ (NSMutableURLRequest *)URLRequestForGameWithFields:(NSString *)fields identifier:(NSNumber *)identifier;

+ (NSMutableURLRequest *)URLRequestForVideoWithFields:(NSString *)fields identifier:(NSNumber *)identifier;

@end
