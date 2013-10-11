//
//  Gamer.h
//  Gamer
//
//  Created by Caio Mello on 11/10/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Platform;

@interface Gamer : NSManagedObject

@property (nonatomic, retain) NSNumber * librarySize;
@property (nonatomic, retain) NSSet *platforms;
@end

@interface Gamer (CoreDataGeneratedAccessors)

- (void)addPlatformsObject:(Platform *)value;
- (void)removePlatformsObject:(Platform *)value;
- (void)addPlatforms:(NSSet *)values;
- (void)removePlatforms:(NSSet *)values;

@end
