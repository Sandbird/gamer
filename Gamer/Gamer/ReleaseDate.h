//
//  ReleaseDate.h
//  Gamer
//
//  Created by Caio Mello on 03/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game, Release;

@interface ReleaseDate : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * day;
@property (nonatomic, retain) NSNumber * defined;
@property (nonatomic, retain) NSNumber * month;
@property (nonatomic, retain) NSNumber * quarter;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSSet *games;
@property (nonatomic, retain) NSSet *releases;
@end

@interface ReleaseDate (CoreDataGeneratedAccessors)

- (void)addGamesObject:(Game *)value;
- (void)removeGamesObject:(Game *)value;
- (void)addGames:(NSSet *)values;
- (void)removeGames:(NSSet *)values;

- (void)addReleasesObject:(Release *)value;
- (void)removeReleasesObject:(Release *)value;
- (void)addReleases:(NSSet *)values;
- (void)removeReleases:(NSSet *)values;

@end
