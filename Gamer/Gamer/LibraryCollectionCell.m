//
//  LibraryCollectionCell.m
//  Gamer
//
//  Created by Caio Mello on 24/07/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "LibraryCollectionCell.h"

@implementation LibraryCollectionCell

- (void)layoutSubviews{
	// Position overlay at the bottom of the cover image
	[_overlayView setFrame:CGRectMake(0, (_overlayView.frame.origin.y - (self.frame.size.height - [Tools frameForImageInImageView:_coverImageView].size.height)/2), _overlayView.frame.size.width, _overlayView.frame.size.height)];
}

@end
