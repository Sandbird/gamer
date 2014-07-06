//
//  NSArray+Split.m
//  Gamer
//
//  Created by Caio Mello on 06/07/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "NSArray+Split.h"

@implementation NSArray (Split)

+ (NSArray *)splitArray:(NSArray *)sourceArray componentsPerSegment:(NSInteger)numberOfComponents{
	NSMutableArray *splitArray = [NSMutableArray new];
	
	if (sourceArray.count > 0) {
		NSInteger index = 0;
		
		while (index < sourceArray.count) {
			NSInteger length = MIN(sourceArray.count - index, numberOfComponents);
			NSArray *subArray = [sourceArray subarrayWithRange:NSMakeRange(index, length)];
			[splitArray addObject:subArray];
			index += length;
		}
		
		return splitArray;
	}
	else {
		return splitArray;
	}
}

@end
