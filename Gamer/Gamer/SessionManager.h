//
//  SessionManager.h
//  Gamer
//
//  Created by Caio Mello on 4/22/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SessionManager : NSObject

+ (NSDateFormatter *)dateFormatter;

+ (NSMutableURLRequest *)APISearchRequestWithFields:(NSString *)fields query:(NSString *)query;

+ (NSMutableURLRequest *)APIGameRequestWithFields:(NSString *)fields identifier:(NSNumber *)identifier;

@end
