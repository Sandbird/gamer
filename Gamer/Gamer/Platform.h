//
//  Platform.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game;

@interface Platform : NSManagedObject

@property (nonatomic, retain) NSString * abbreviation;
@property (nonatomic, retain) id color;
@property (nonatomic, retain) NSNumber * favorite;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *games;
@property (nonatomic, retain) NSSet *savedGames;
@end

@interface Platform (CoreDataGeneratedAccessors)

- (void)addGamesObject:(Game *)value;
- (void)removeGamesObject:(Game *)value;
- (void)addGames:(NSSet *)values;
- (void)removeGames:(NSSet *)values;

- (void)addSavedGamesObject:(Game *)value;
- (void)removeSavedGamesObject:(Game *)value;
- (void)addSavedGames:(NSSet *)values;
- (void)removeSavedGames:(NSSet *)values;

@end
