//
//  Platform.h
//  Gamer
//
//  Created by Caio Mello on 06/11/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game, Gamer;

@interface Platform : NSManagedObject

@property (nonatomic, retain) NSString * abbreviation;
@property (nonatomic, retain) id color;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Gamer *gamer;
@property (nonatomic, retain) NSSet *games;
@property (nonatomic, retain) NSSet *libraryGames;
@property (nonatomic, retain) NSSet *wishlistGames;
@property (nonatomic, retain) NSSet *metascoreGames;
@property (nonatomic, retain) NSSet *wishlistMetascoreGames;
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

- (void)addWishlistGamesObject:(Game *)value;
- (void)removeWishlistGamesObject:(Game *)value;
- (void)addWishlistGames:(NSSet *)values;
- (void)removeWishlistGames:(NSSet *)values;

- (void)addMetascoreGamesObject:(Game *)value;
- (void)removeMetascoreGamesObject:(Game *)value;
- (void)addMetascoreGames:(NSSet *)values;
- (void)removeMetascoreGames:(NSSet *)values;

- (void)addWishlistMetascoreGamesObject:(Game *)value;
- (void)removeWishlistMetascoreGamesObject:(Game *)value;
- (void)addWishlistMetascoreGames:(NSSet *)values;
- (void)removeWishlistMetascoreGames:(NSSet *)values;

@end
