//
//  Platform.h
//  Gamer
//
//  Created by Caio Mello on 26/06/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game, Gamer, Metascore, Release;

@interface Platform : NSManagedObject

@property (nonatomic, retain) NSString * abbreviation;
@property (nonatomic, retain) id color;
@property (nonatomic, retain) NSNumber * group;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * metacriticIdentifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *addedGames;
@property (nonatomic, retain) Gamer *gamer;
@property (nonatomic, retain) NSSet *games;
@property (nonatomic, retain) NSSet *metascores;
@property (nonatomic, retain) NSSet *releases;
@end

@interface Platform (CoreDataGeneratedAccessors)

- (void)addAddedGamesObject:(Game *)value;
- (void)removeAddedGamesObject:(Game *)value;
- (void)addAddedGames:(NSSet *)values;
- (void)removeAddedGames:(NSSet *)values;

- (void)addGamesObject:(Game *)value;
- (void)removeGamesObject:(Game *)value;
- (void)addGames:(NSSet *)values;
- (void)removeGames:(NSSet *)values;

- (void)addMetascoresObject:(Metascore *)value;
- (void)removeMetascoresObject:(Metascore *)value;
- (void)addMetascores:(NSSet *)values;
- (void)removeMetascores:(NSSet *)values;

- (void)addReleasesObject:(Release *)value;
- (void)removeReleasesObject:(Release *)value;
- (void)addReleases:(NSSet *)values;
- (void)removeReleases:(NSSet *)values;

@end
