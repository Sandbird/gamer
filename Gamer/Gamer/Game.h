//
//  Game.h
//  Gamer
//
//  Created by Caio Mello on 2/12/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Developer, Franchise, Genre, Platform, Publisher, Screenshot, SimilarGame, Theme;

@interface Game : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSData * imageSmall;
@property (nonatomic, retain) NSNumber * metascore;
@property (nonatomic, retain) NSString * overview;
@property (nonatomic, retain) NSDate * releaseDate;
@property (nonatomic, retain) NSString * releaseDateText;
@property (nonatomic, retain) NSNumber * releaseMonth;
@property (nonatomic, retain) NSNumber * releaseQuarter;
@property (nonatomic, retain) NSNumber * releaseYear;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * track;
@property (nonatomic, retain) NSString * trailerURL;
@property (nonatomic, retain) NSNumber * period;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSSet *developers;
@property (nonatomic, retain) NSSet *franchises;
@property (nonatomic, retain) NSSet *genres;
@property (nonatomic, retain) NSSet *platforms;
@property (nonatomic, retain) NSSet *publishers;
@property (nonatomic, retain) NSSet *screenshots;
@property (nonatomic, retain) NSSet *similarGames;
@property (nonatomic, retain) NSSet *themes;
@end

@interface Game (CoreDataGeneratedAccessors)

- (void)addDevelopersObject:(Developer *)value;
- (void)removeDevelopersObject:(Developer *)value;
- (void)addDevelopers:(NSSet *)values;
- (void)removeDevelopers:(NSSet *)values;

- (void)addFranchisesObject:(Franchise *)value;
- (void)removeFranchisesObject:(Franchise *)value;
- (void)addFranchises:(NSSet *)values;
- (void)removeFranchises:(NSSet *)values;

- (void)addGenresObject:(Genre *)value;
- (void)removeGenresObject:(Genre *)value;
- (void)addGenres:(NSSet *)values;
- (void)removeGenres:(NSSet *)values;

- (void)addPlatformsObject:(Platform *)value;
- (void)removePlatformsObject:(Platform *)value;
- (void)addPlatforms:(NSSet *)values;
- (void)removePlatforms:(NSSet *)values;

- (void)addPublishersObject:(Publisher *)value;
- (void)removePublishersObject:(Publisher *)value;
- (void)addPublishers:(NSSet *)values;
- (void)removePublishers:(NSSet *)values;

- (void)addScreenshotsObject:(Screenshot *)value;
- (void)removeScreenshotsObject:(Screenshot *)value;
- (void)addScreenshots:(NSSet *)values;
- (void)removeScreenshots:(NSSet *)values;

- (void)addSimilarGamesObject:(SimilarGame *)value;
- (void)removeSimilarGamesObject:(SimilarGame *)value;
- (void)addSimilarGames:(NSSet *)values;
- (void)removeSimilarGames:(NSSet *)values;

- (void)addThemesObject:(Theme *)value;
- (void)removeThemesObject:(Theme *)value;
- (void)addThemes:(NSSet *)values;
- (void)removeThemes:(NSSet *)values;

@end
