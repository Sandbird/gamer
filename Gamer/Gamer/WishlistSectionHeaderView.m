//
//  WishlistSectionHeaderView.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "WishlistSectionHeaderView.h"

@implementation WishlistSectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithReleasePeriod:(ReleasePeriod *)releasePeriod{
	self = [super initWithFrame:CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height)];
	if (self){
		_releasePeriod = releasePeriod;
		
		[self setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
		
//		_iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 34, 34)];
//		[_iconImageView setBackgroundColor:[UIColor darkGrayColor]];
		
//		_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(47, 11, 221, 22)];
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 11, 221, 22)];
		[_titleLabel setBackgroundColor:[UIColor clearColor]];
//		[_titleLabel setTextColor:[[UIApplication sharedApplication] keyWindow].tintColor];
		[_titleLabel setTextColor:[UIColor orangeColor]];
//		[_titleLabel setFont:[UIFont systemFontOfSize:18]];
		
		[_titleLabel setText:releasePeriod.name];
		
		_hideIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(276, 10, 24, 24)];
		[_hideIndicator setBackgroundColor:[UIColor darkGrayColor]];
		
//		[self addSubview:_iconImageView];
		[self addSubview:_titleLabel];
		[self addSubview:_hideIndicator];
		
		_gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerAction:)];
		[self addGestureRecognizer:_gestureRecognizer];
	}
	
	return  self;
}

- (void)tapGestureRecognizerAction:(UITapGestureRecognizer *)gestureRecognizer{
	[self.delegate wishlistSectionHeaderView:self didTapReleasePeriod:_releasePeriod];
}

@end
