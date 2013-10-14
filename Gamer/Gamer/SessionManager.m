//
//  SessionManager.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SessionManager.h"

@implementation SessionManager

static NSMutableURLRequest *SEARCHREQUEST;
static Gamer *GAMER;

+ (void)setGamer:(Gamer *)gamer{
	GAMER = gamer;
}

+ (Gamer *)gamer{
	return GAMER;
}

+ (id<GAITracker>)tracker{
	return [GAI sharedInstance].defaultTracker;
}

@end
