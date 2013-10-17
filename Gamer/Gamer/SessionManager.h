//
//  SessionManager.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleAnalytics-iOS-SDK/GAI.h>
#import "Gamer.h"

@interface SessionManager : NSObject

+ (void)setGamer:(Gamer *)gamer;

+ (Gamer *)gamer;

+ (id<GAITracker>)tracker;

+ (void)setup;

@end
