//
//  Game.h
//  Gamer
//
//  Created by Caio Mello on 2/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Genre, Platform;

@interface Game : NSManagedObject

@property (nonatomic, retain) NSData * coverImage;
@property (nonatomic, retain) NSNumber * metascore;
@property (nonatomic, retain) NSString * overview;
@property (nonatomic, retain) NSDate * releaseDate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * trailerURL;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSSet *genres;
@property (nonatomic, retain) NSSet *platforms;
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

@end
