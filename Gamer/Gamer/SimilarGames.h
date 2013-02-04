//
//  SimilarGames.h
//  Gamer
//
//  Created by Caio Mello on 2/3/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game;

@interface SimilarGames : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) Game *game;

@end
