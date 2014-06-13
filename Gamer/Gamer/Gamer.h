//
//  Gamer.h
//  Gamer
//
//  Created by Caio Mello on 12/06/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Platform, Region;

@interface Gamer : NSManagedObject

@property (nonatomic, retain) NSNumber * librarySize;
@property (nonatomic, retain) NSDate * lastRefresh;
@property (nonatomic, retain) NSSet *platforms;
@property (nonatomic, retain) Region *region;
@end

@interface Gamer (CoreDataGeneratedAccessors)

- (void)addPlatformsObject:(Platform *)value;
- (void)removePlatformsObject:(Platform *)value;
- (void)addPlatforms:(NSSet *)values;
- (void)removePlatforms:(NSSet *)values;

@end
