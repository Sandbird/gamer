//
//  Image.h
//  Gamer
//
//  Created by Caio Mello on 13/09/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game, Thumbnail;

@interface Image : NSManagedObject

@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * isDownloading;
@property (nonatomic, retain) NSString * originalURL;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) Game *game;
@property (nonatomic, retain) Thumbnail *thumbnail;

@end
