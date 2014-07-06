//
//  NSArray+Split.h
//  Gamer
//
//  Created by Caio Mello on 06/07/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Split)

+ (NSArray *)splitArray:(NSArray *)sourceArray componentsPerSegment:(NSInteger)numberOfComponents;

@end
