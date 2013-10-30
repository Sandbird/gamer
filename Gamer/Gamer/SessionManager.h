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

typedef NS_ENUM(NSInteger, OptimalImageWidthiPhone){
	OptimalImageWidthiPhoneCover = 280,
	OptimalImageWidthiPhoneWishlist = 50,
	OptimalImageWidthiPhoneLibrary = 92
};

typedef NS_ENUM(NSInteger, OptimalImageHeightiPhone){
	OptimalImageHeightiPhoneCover = 200,
	OptimalImageHeightiPhoneWishlist = 50,
	OptimalImageHeightiPhoneLibrary = 116
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

@interface SessionManager : NSObject

+ (void)setGamer:(Gamer *)gamer;

+ (Gamer *)gamer;

+ (id<GAITracker>)tracker;

+ (CGSize)optimalCoverImageSizeForImage:(UIImage *)image;

+ (UIImage *)aspectFitImageWithImage:(UIImage *)image type:(GameImageType)type;

+ (void)setup;

@end
