//
//  Metascore.h
//  Gamer
//
//  Created by Caio Mello on 26/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game, Platform;

@interface Metascore : NSManagedObject

@property (nonatomic, retain) NSNumber * criticScore;
@property (nonatomic, retain) NSDecimalNumber * userScore;
@property (nonatomic, retain) NSString * metacriticURL;
@property (nonatomic, retain) Game *game;
@property (nonatomic, retain) Platform *platform;

@end
