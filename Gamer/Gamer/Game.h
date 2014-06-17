//
//  Game.h
//  Gamer
//
//  Created by Caio Mello on 17/06/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Developer, Franchise, Genre, Image, Metascore, Platform, Publisher, Release, ReleasePeriod, SimilarGame, Theme, Video;

@interface Game : NSManagedObject

@property (nonatomic, retain) NSNumber * borrowed;
@property (nonatomic, retain) NSNumber * digital;
@property (nonatomic, retain) NSNumber * finished;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * imagePath;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSNumber * lent;
@property (nonatomic, retain) NSNumber * location;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * overview;
@property (nonatomic, retain) NSNumber * personalRating;
@property (nonatomic, retain) NSNumber * preordered;
@property (nonatomic, retain) NSNumber * released;
@property (nonatomic, retain) NSDate * releaseDate;
@property (nonatomic, retain) NSNumber * releaseDateDefined;
@property (nonatomic, retain) NSString * releaseDateText;
@property (nonatomic, retain) NSNumber * releaseDay;
@property (nonatomic, retain) NSNumber * releaseMonth;
@property (nonatomic, retain) NSNumber * releaseQuarter;
@property (nonatomic, retain) NSNumber * releaseYear;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *developers;
@property (nonatomic, retain) NSSet *franchises;
@property (nonatomic, retain) NSSet *genres;
@property (nonatomic, retain) NSSet *images;
@property (nonatomic, retain) NSSet *metascores;
@property (nonatomic, retain) NSSet *platforms;
@property (nonatomic, retain) NSSet *publishers;
@property (nonatomic, retain) ReleasePeriod *releasePeriod;
@property (nonatomic, retain) NSSet *releases;
@property (nonatomic, retain) Metascore *selectedMetascore;
@property (nonatomic, retain) NSSet *selectedPlatforms;
@property (nonatomic, retain) Release *selectedRelease;
@property (nonatomic, retain) NSSet *similarGames;
@property (nonatomic, retain) NSSet *themes;
@property (nonatomic, retain) NSSet *videos;
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

- (void)addImagesObject:(Image *)value;
- (void)removeImagesObject:(Image *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

- (void)addMetascoresObject:(Metascore *)value;
- (void)removeMetascoresObject:(Metascore *)value;
- (void)addMetascores:(NSSet *)values;
- (void)removeMetascores:(NSSet *)values;

- (void)addPlatformsObject:(Platform *)value;
- (void)removePlatformsObject:(Platform *)value;
- (void)addPlatforms:(NSSet *)values;
- (void)removePlatforms:(NSSet *)values;

- (void)addPublishersObject:(Publisher *)value;
- (void)removePublishersObject:(Publisher *)value;
- (void)addPublishers:(NSSet *)values;
- (void)removePublishers:(NSSet *)values;

- (void)addReleasesObject:(Release *)value;
- (void)removeReleasesObject:(Release *)value;
- (void)addReleases:(NSSet *)values;
- (void)removeReleases:(NSSet *)values;

- (void)addSelectedPlatformsObject:(Platform *)value;
- (void)removeSelectedPlatformsObject:(Platform *)value;
- (void)addSelectedPlatforms:(NSSet *)values;
- (void)removeSelectedPlatforms:(NSSet *)values;

- (void)addSimilarGamesObject:(SimilarGame *)value;
- (void)removeSimilarGamesObject:(SimilarGame *)value;
- (void)addSimilarGames:(NSSet *)values;
- (void)removeSimilarGames:(NSSet *)values;

- (void)addThemesObject:(Theme *)value;
- (void)removeThemesObject:(Theme *)value;
- (void)addThemes:(NSSet *)values;
- (void)removeThemes:(NSSet *)values;

- (void)addVideosObject:(Video *)value;
- (void)removeVideosObject:(Video *)value;
- (void)addVideos:(NSSet *)values;
- (void)removeVideos:(NSSet *)values;

@end
