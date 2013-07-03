//
//  Image.h
//  Gamer
//
//  Created by Caio Mello on 7/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game, Video;

@interface Image : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSData * thumbnailData;
@property (nonatomic, retain) Game *game;
@property (nonatomic, retain) Video *video;

@end
