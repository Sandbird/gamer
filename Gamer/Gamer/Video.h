//
//  Video.h
//  Gamer
//
//  Created by Caio Mello on 7/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game, Image;

@interface Video : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * overview;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSString * highQualityURL;
@property (nonatomic, retain) NSString * lowQualityURL;
@property (nonatomic, retain) NSDate * publishDate;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) Game *game;
@property (nonatomic, retain) Image *image;

@end
