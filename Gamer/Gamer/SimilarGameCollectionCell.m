//
//  SimilarGameCollectionCell.m
//  Gamer
//
//  Created by Caio Mello on 11/10/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "SimilarGameCollectionCell.h"

@implementation SimilarGameCollectionCell

- (void)setHighlighted:(BOOL)highlighted{
	[super setHighlighted:highlighted];
	
	if (highlighted){
		[self setAlpha:0.5];
	}
	else{
		[self setAlpha:1];
		[self.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	}
}

@end
