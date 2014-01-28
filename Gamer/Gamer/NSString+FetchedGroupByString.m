//
//  NSString+FetchedGroupByString.m
//  Gamer
//
//  Created by Caio Mello on 26/01/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "NSString+FetchedGroupByString.h"

@implementation NSString (FetchedGroupByString)

- (NSString *)stringGroupByFirstInitial {
	if (!self.length || self.length == 1)
		return self;
	return [self substringToIndex:1];
}

@end
