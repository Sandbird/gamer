//
//  Thumbnail.h
//  Gamer
//
//  Created by Caio Mello on 13/09/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Image, Video;

@interface Thumbnail : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) Image *image;
@property (nonatomic, retain) Video *video;

@end
