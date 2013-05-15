//
//  SessionManager.m
//  Gamer
//
//  Created by Caio Mello on 4/22/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SessionManager.h"

@implementation SessionManager

static NSDateFormatter *DATEFORMATTER;
static NSMutableURLRequest *REQUEST;

+ (NSDateFormatter *)dateFormatter{
	if (!DATEFORMATTER) DATEFORMATTER = [[NSDateFormatter alloc] init];
	return DATEFORMATTER;
}

+ (NSMutableURLRequest *)URLRequestForGamesWithFields:(NSString *)fields platforms:(NSArray *)platforms name:(NSString *)name{
	if (!REQUEST) REQUEST = [[NSMutableURLRequest alloc] init];
	[REQUEST setHTTPMethod:@"GET"];
	
	NSString *platformIdentifiers = [[platforms valueForKey:@"identifier"] componentsJoinedByString:@"|"];
	
	[REQUEST setURL:[NSURL URLWithString:[[NSString stringWithFormat:@"http://api.giantbomb.com/games/3030/?api_key=d92c258adb509ded409d28f4e51de2c83e297011&format=json&field_list=%@&filter=platforms:%@,name:%@", fields, platformIdentifiers, name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	return  REQUEST;
}

+ (NSMutableURLRequest *)URLRequestForGameWithFields:(NSString *)fields identifier:(NSNumber *)identifier{
	if (!REQUEST) REQUEST = [[NSMutableURLRequest alloc] init];
	[REQUEST setHTTPMethod:@"GET"];
	[REQUEST setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.giantbomb.com/game/3030-%@/?api_key=d92c258adb509ded409d28f4e51de2c83e297011&format=json&field_list=%@", identifier, fields]]];
	return  REQUEST;
}

@end
