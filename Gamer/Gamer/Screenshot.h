//
//  Screenshot.h
//  Gamer
//
//  Created by Caio Mello on 2/12/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game;

@interface Screenshot : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Game *game;

@end
