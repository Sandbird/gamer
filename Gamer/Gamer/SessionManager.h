//
//  SessionManager.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SessionManager : NSObject

+ (NSMutableURLRequest *)URLRequestForGamesWithFields:(NSString *)fields platforms:(NSArray *)platforms name:(NSString *)name;

+ (NSMutableURLRequest *)URLRequestForGameWithFields:(NSString *)fields identifier:(NSNumber *)identifier;

@end
