//
//  Release.h
//  Gamer
//
//  Created by Caio Mello on 03/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game, Platform, ReleaseDate;

@interface Release : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) Game *game;
@property (nonatomic, retain) Platform *platform;
@property (nonatomic, retain) ReleaseDate *releaseDate;
@property (nonatomic, retain) NSManagedObject *region;

@end
