//
//  Release.h
//  Gamer
//
//  Created by Caio Mello on 08/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game, Platform, Region;

@interface Release : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * releaseDate;
@property (nonatomic, retain) NSNumber * releaseDay;
@property (nonatomic, retain) NSNumber * releaseDateDefined;
@property (nonatomic, retain) NSNumber * releaseMonth;
@property (nonatomic, retain) NSNumber * releaseQuarter;
@property (nonatomic, retain) NSNumber * releaseYear;
@property (nonatomic, retain) NSString * releaseDateText;
@property (nonatomic, retain) NSNumber * released;
@property (nonatomic, retain) Game *game;
@property (nonatomic, retain) Platform *platform;
@property (nonatomic, retain) Region *region;
@property (nonatomic, retain) Game *selectedGame;

@end
