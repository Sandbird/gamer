//
//  Image.h
//  Gamer
//
//  Created by Caio Mello on 2/18/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game;

@interface Image : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Game *game;

@end
