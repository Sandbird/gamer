//
//  CoverImage.h
//  Gamer
//
//  Created by Caio Mello on 07/10/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game;

@interface CoverImage : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Game *game;

@end
