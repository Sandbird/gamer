//
//  VideoCollectionCell.m
//  Gamer
//
//  Created by Caio Mello on 7/3/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "VideoCollectionCell.h"

@implementation VideoCollectionCell

- (void)setHighlighted:(BOOL)highlighted{
	[super setHighlighted:highlighted];
	
	if (highlighted){
		[self.playImageView setAlpha:0.5];
	}
	else{
		[self.playImageView setAlpha:1];
		[self.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	}
}

@end
