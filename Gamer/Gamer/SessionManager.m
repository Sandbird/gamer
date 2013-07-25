//
//  SessionManager.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SessionManager.h"

@implementation SessionManager

static NSMutableURLRequest *REQUEST;

+ (id<GAITracker>)tracker{
	return [GAI sharedInstance].defaultTracker;
}

+ (NSMutableURLRequest *)URLRequestForGamesWithFields:(NSString *)fields platforms:(NSArray *)platforms name:(NSString *)name{
	NSString *apiKey = @"d92c258adb509ded409d28f4e51de2c83e297011";
	NSString *platformIdentifiers = [[platforms valueForKey:@"identifier"] componentsJoinedByString:@"|"];
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/games/3030/?api_key=%@&format=json&sort=date_added:desc&field_list=%@&filter=platforms:%@,name:%@", apiKey, fields, platformIdentifiers, name];
	
	if (!REQUEST) REQUEST = [[NSMutableURLRequest alloc] init];
	[REQUEST setHTTPMethod:@"GET"];
	[REQUEST setURL:[NSURL URLWithString:[stringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	return  REQUEST;
}

+ (NSMutableURLRequest *)URLRequestForGameWithFields:(NSString *)fields identifier:(NSNumber *)identifier{
	NSString *apiKey = @"d92c258adb509ded409d28f4e51de2c83e297011";
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/game/3030-%@/?api_key=%@&format=json&field_list=%@", identifier, apiKey, fields];
	
	if (!REQUEST) REQUEST = [[NSMutableURLRequest alloc] init];
	[REQUEST setHTTPMethod:@"GET"];
	[REQUEST setURL:[NSURL URLWithString:stringURL]];
	
	return  REQUEST;
}

+ (NSMutableURLRequest *)URLRequestForVideoWithFields:(NSString *)fields identifier:(NSNumber *)identifier{
	NSString *apiKey = @"d92c258adb509ded409d28f4e51de2c83e297011";
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/video/2300-%@/?api_key=%@&format=json&field_list=%@", identifier, apiKey, fields];
	
//	if (!REQUEST) REQUEST = [[NSMutableURLRequest alloc] init];
//	[REQUEST setHTTPMethod:@"GET"];
//	[REQUEST setURL:[NSURL URLWithString:stringURL]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
	[request setHTTPMethod:@"GET"];
	
	return request;
}

@end
