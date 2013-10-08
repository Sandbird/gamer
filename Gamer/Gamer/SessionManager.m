//
//  SessionManager.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SessionManager.h"

@implementation SessionManager

static NSString *APIKEY = @"bb5b34c59426946bea05a8b0b2877789fb374d3c";
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

+ (NSMutableURLRequest *)requestForGamesWithTitle:(NSString *)title fields:(NSString *)fields platforms:(NSArray *)platforms{
	NSArray *identifiers = [platforms valueForKey:@"identifier"];
	NSMutableArray *platformIdentifiers = [[NSMutableArray alloc] initWithArray:identifiers];
	for (NSNumber *identifier in identifiers){
		switch (identifier.integerValue) {
			case 35: [platformIdentifiers addObject:@(88)]; break;
			case 129: [platformIdentifiers addObject:@(143)]; break;
			case 20: [platformIdentifiers addObject:@(86)]; break;
			default: break;
		}
	}
	NSString *platformsString = [platformIdentifiers componentsJoinedByString:@"|"];
	
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/games/3030/?api_key=%@&format=json&sort=date_added:desc&field_list=%@&filter=platforms:%@,name:%@", APIKEY, fields, platformsString, title];
	
	if (!SEARCHREQUEST) SEARCHREQUEST = [[NSMutableURLRequest alloc] init];
	[SEARCHREQUEST setHTTPMethod:@"GET"];
	[SEARCHREQUEST setURL:[NSURL URLWithString:[stringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	return  SEARCHREQUEST;
}

+ (NSMutableURLRequest *)requestForGameWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields{
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/game/3030-%@/?api_key=%@&format=json&field_list=%@", identifier, APIKEY, fields];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
	[request setHTTPMethod:@"GET"];
	
	return  request;
}

+ (NSMutableURLRequest *)requestForVideoWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields{
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/video/2300-%@/?api_key=%@&format=json&field_list=%@", identifier, APIKEY, fields];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
	[request setHTTPMethod:@"GET"];
	
	return request;
}

@end
