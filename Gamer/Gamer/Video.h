//
//  Video.h
//  Gamer
//
//  Created by Caio Mello on 07/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game;

@interface Video : NSManagedObject

@property (nonatomic, retain) NSString * highQualityURL;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSString * lowQualityURL;
@property (nonatomic, retain) NSString * overview;
@property (nonatomic, retain) NSDate * publishDate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Game *game;

@end
