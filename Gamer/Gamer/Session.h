//
//  SessionManager.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Gamer.h"

typedef NS_ENUM(NSInteger, LibrarySize){
	LibrarySizeSmall = 0,
	LibrarySizeMedium = 1,
	LibrarySizeLarge = 2
};

@interface Session : NSObject

+ (void)setGamer:(Gamer *)gamer;

+ (Gamer *)gamer;

+ (NSString *)searchQuery;
+ (void)setSearchQuery:(NSString *)query;

+ (NSArray *)searchResults;
+ (void)setSearchResults:(NSArray *)results;

+ (CGSize)coverImageSize;

+ (void)setupInitialData;

@end
