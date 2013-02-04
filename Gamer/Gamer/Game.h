//
//  Game.h
//  Gamer
//
//  Created by Caio Mello on 2/3/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Developer, Franchise, Genre, Platform, Publisher, Screenshot, SimilarGames;

@interface Game : NSManagedObject

@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSNumber * metascore;
@property (nonatomic, retain) NSString * overview;
@property (nonatomic, retain) NSDate * releaseDate;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * trailerURL;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSSet *genres;
@property (nonatomic, retain) NSSet *platforms;
@property (nonatomic, retain) NSSet *screenshots;
@property (nonatomic, retain) NSSet *developers;
@property (nonatomic, retain) NSSet *publishers;
@property (nonatomic, retain) NSSet *similarGames;
@property (nonatomic, retain) NSSet *franchises;
@end

@interface Game (CoreDataGeneratedAccessors)

- (void)addGenresObject:(Genre *)value;
- (void)removeGenresObject:(Genre *)value;
- (void)addGenres:(NSSet *)values;
- (void)removeGenres:(NSSet *)values;

- (void)addPlatformsObject:(Platform *)value;
- (void)removePlatformsObject:(Platform *)value;
- (void)addPlatforms:(NSSet *)values;
- (void)removePlatforms:(NSSet *)values;

- (void)addScreenshotsObject:(Screenshot *)value;
- (void)removeScreenshotsObject:(Screenshot *)value;
- (void)addScreenshots:(NSSet *)values;
- (void)removeScreenshots:(NSSet *)values;

- (void)addDevelopersObject:(Developer *)value;
- (void)removeDevelopersObject:(Developer *)value;
- (void)addDevelopers:(NSSet *)values;
- (void)removeDevelopers:(NSSet *)values;

- (void)addPublishersObject:(Publisher *)value;
- (void)removePublishersObject:(Publisher *)value;
- (void)addPublishers:(NSSet *)values;
- (void)removePublishers:(NSSet *)values;

- (void)addSimilarGamesObject:(SimilarGames *)value;
- (void)removeSimilarGamesObject:(SimilarGames *)value;
- (void)addSimilarGames:(NSSet *)values;
- (void)removeSimilarGames:(NSSet *)values;

- (void)addFranchisesObject:(Franchise *)value;
- (void)removeFranchisesObject:(Franchise *)value;
- (void)addFranchises:(NSSet *)values;
- (void)removeFranchises:(NSSet *)values;

@end
