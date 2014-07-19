//
//  SearchCollectionCell.m
//  Gamer
//
//  Created by Caio Mello on 01/11/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "SearchCollectionCell.h"

@implementation SearchCollectionCell

- (void)setHighlighted:(BOOL)highlighted{
	[super setHighlighted:highlighted];
	
	if (highlighted){
		[self setAlpha:0.5];
	}
	else{
		[self setAlpha:1];
	}
}

@end
