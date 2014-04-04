//
//  SessionManager.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Gamer.h"

typedef NS_ENUM(NSInteger, OptimalImageWidthiPhone){
	OptimalImageWidthiPhoneCover = 280,
	OptimalImageWidthiPhoneWishlist = 50,
	OptimalImageWidthiPhoneLibrary = 66
};

typedef NS_ENUM(NSInteger, OptimalImageHeightiPhone){
	OptimalImageHeightiPhoneCover = 200,
	OptimalImageHeightiPhoneWishlist = 50,
	OptimalImageHeightiPhoneLibrary = 83
};

typedef NS_ENUM(NSInteger, OptimalImageWidthiPad){
	OptimalImageWidthiPadCover = 420,
	OptimalImageWidthiPadWishlist = 135,
	OptimalImageWidthiPadLibrary = 140
};

typedef NS_ENUM(NSInteger, OptimalImageHeightiPad){
	OptimalImageHeightiPadCover = 300,
	OptimalImageHeightiPadWishlist = 170,
	OptimalImageHeightiPadLibrary = 176
};

typedef NS_ENUM(NSInteger, GameImageType){
	GameImageTypeCover,
	GameImageTypeWishlist,
	GameImageTypeLibrary
};

typedef NS_ENUM(NSInteger, GameLocation){
	GameLocationNone = 0,
	GameLocationWishlist = 1,
	GameLocationLibrary = 2
};

typedef NS_ENUM(NSInteger, LibrarySize){
	LibrarySizeSmall = 0,
	LibrarySizeMedium = 1,
	LibrarySizeLarge = 2
};

typedef NS_ENUM(NSInteger, PlatformGroup){
	PlatformGroupModern = 0,
	PlatformGroupLegacy = 1
};

@interface Session : NSObject

+ (void)setGamer:(Gamer *)gamer;

+ (Gamer *)gamer;

+ (NSString *)searchQuery;
+ (void)setSearchQuery:(NSString *)query;

+ (NSArray *)searchResults;
+ (void)setSearchResults:(NSArray *)results;

+ (CGSize)optimalCoverImageSizeForImage:(UIImage *)image type:(GameImageType)type;

+ (UIImage *)aspectFitImageWithImage:(UIImage *)image type:(GameImageType)type;

+ (void)setupInitialData;

@end
