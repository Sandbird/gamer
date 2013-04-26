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

+ (NSMutableURLRequest *)APISearchRequestWithFields:(NSString *)fields query:(NSString *)query{
	if (!REQUEST) REQUEST = [[NSMutableURLRequest alloc] init];
	[REQUEST setHTTPMethod:@"GET"];
	[REQUEST setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.giantbomb.com/api/search/?api_key=d92c258adb509ded409d28f4e51de2c83e297011&format=json&resources=game&limit=20&field_list=%@&query=%@", fields, query]]];
	return  REQUEST;
}

+ (NSMutableURLRequest *)APIGameRequestWithFields:(NSString *)fields identifier:(NSNumber *)identifier{
	if (!REQUEST) REQUEST = [[NSMutableURLRequest alloc] init];
	[REQUEST setHTTPMethod:@"GET"];
	[REQUEST setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.giantbomb.com/api/game/3030-%@/?api_key=d92c258adb509ded409d28f4e51de2c83e297011&format=json&field_list=%@", identifier, fields]]];
	return  REQUEST;
}

@end
