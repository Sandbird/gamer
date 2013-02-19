//
//  Platform.h
//  Gamer
//
//  Created by Caio Mello on 2/18/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game;

@interface Platform : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * nameShort;
@property (nonatomic, retain) NSSet *games;
@property (nonatomic, retain) NSSet *trackedGames;
@end

@interface Platform (CoreDataGeneratedAccessors)

- (void)addGamesObject:(Game *)value;
- (void)removeGamesObject:(Game *)value;
- (void)addGames:(NSSet *)values;
- (void)removeGames:(NSSet *)values;

- (void)addTrackedGamesObject:(Game *)value;
- (void)removeTrackedGamesObject:(Game *)value;
- (void)addTrackedGames:(NSSet *)values;
- (void)removeTrackedGames:(NSSet *)values;

@end
