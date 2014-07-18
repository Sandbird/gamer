//
//  Platform.h
//  Gamer
//
//  Created by Caio Mello on 17/07/2014.
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
@property (nonatomic, retain) Gamer *gamer;
@property (nonatomic, retain) NSSet *games;
@property (nonatomic, retain) NSSet *libraryGames;
@property (nonatomic, retain) NSSet *metascores;
@property (nonatomic, retain) NSSet *releases;
@property (nonatomic, retain) NSSet *wishlistGames;
@end

@interface Platform (CoreDataGeneratedAccessors)

- (void)addGamesObject:(Game *)value;
- (void)removeGamesObject:(Game *)value;
- (void)addGames:(NSSet *)values;
- (void)removeGames:(NSSet *)values;

- (void)addLibraryGamesObject:(Game *)value;
- (void)removeLibraryGamesObject:(Game *)value;
- (void)addLibraryGames:(NSSet *)values;
- (void)removeLibraryGames:(NSSet *)values;

- (void)addMetascoresObject:(Metascore *)value;
- (void)removeMetascoresObject:(Metascore *)value;
- (void)addMetascores:(NSSet *)values;
- (void)removeMetascores:(NSSet *)values;

- (void)addReleasesObject:(Release *)value;
- (void)removeReleasesObject:(Release *)value;
- (void)addReleases:(NSSet *)values;
- (void)removeReleases:(NSSet *)values;

- (void)addWishlistGamesObject:(Game *)value;
- (void)removeWishlistGamesObject:(Game *)value;
- (void)addWishlistGames:(NSSet *)values;
- (void)removeWishlistGames:(NSSet *)values;

@end
