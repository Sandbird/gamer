//
//  Publisher.h
//  Gamer
//
//  Created by Caio Mello on 2/12/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game;

@interface Publisher : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *games;
@end

@interface Publisher (CoreDataGeneratedAccessors)

- (void)addGamesObject:(Game *)value;
- (void)removeGamesObject:(Game *)value;
- (void)addGames:(NSSet *)values;
- (void)removeGames:(NSSet *)values;

@end
