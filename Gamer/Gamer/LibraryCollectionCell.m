//
//  LibraryCollectionCell.m
//  Gamer
//
//  Created by Caio Mello on 24/07/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "LibraryCollectionCell.h"

@implementation LibraryCollectionCell

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
