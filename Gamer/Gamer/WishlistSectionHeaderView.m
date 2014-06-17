//
//  WishlistSectionHeaderView.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "WishlistSectionHeaderView.h"

@implementation WishlistSectionHeaderView

- (id)initWithReleasePeriod:(ReleasePeriod *)releasePeriod{
	self = [[NSBundle mainBundle] loadNibNamed:@"iPhone" owner:self options:nil][3];
	if (self){
		UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:self.frame];
		[toolBar setBarStyle:UIBarStyleBlackTranslucent];
		[self insertSubview:toolBar atIndex:0];
		
		[_titleLabel setText:releasePeriod.name];
	}
	
	return  self;
}

@end
