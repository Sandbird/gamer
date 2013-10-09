//
//  LibraryCollectionCell.m
//  Gamer
//
//  Created by Caio Mello on 24/07/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "LibraryCollectionCell.h"

@implementation LibraryCollectionCell

- (void)drawRect:(CGRect)rect{
	// Position overlay at the bottom of the cover image
	if (_coverImageView.image){
		[_coverImageView setBackgroundColor:[UIColor clearColor]];
		CGRect imageFrame = [Tools frameForImageInImageView:_coverImageView];
		[_overlayView setFrame:CGRectMake((rect.size.width - imageFrame.size.width)/2, (_overlayView.frame.origin.y - (rect.size.height - imageFrame.size.height)/2), imageFrame.size.width, _overlayView.frame.size.height)];
	}
	else
		[_coverImageView setBackgroundColor:[UIColor darkGrayColor]];
}

@end
