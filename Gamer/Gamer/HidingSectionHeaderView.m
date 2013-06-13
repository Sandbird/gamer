//
//  ReleasesSectionHeaderView.m
//  Gamer
//
//  Created by Caio Mello on 4/6/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "HidingSectionHeaderView.h"

@implementation HidingSectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithSectionIndex:(NSInteger)index{
	self = [super initWithFrame:CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height)];
	if (self){
		_index = index;
		
		[self setBackgroundColor:[UIColor colorWithWhite:0.96 alpha:1]];
		
		[Utilities addDropShadowToView:self color:[UIColor lightGrayColor] opacity:1 radius:2 offset:CGSizeMake(0, 1)];
		
		_iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 34, 34)];
		[_iconImageView setBackgroundColor:[UIColor lightGrayColor]];
		
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(47, 11, 221, 22)];
		[_titleLabel setBackgroundColor:[UIColor clearColor]];
		[_titleLabel setTextColor:[UIColor darkGrayColor]];
		[_titleLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:18]];
		
		_hideIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(276, 10, 24, 24)];
		[_hideIndicator setBackgroundColor:[UIColor lightGrayColor]];
		
		[self addSubview:_iconImageView];
		[self addSubview:_titleLabel];
		[self addSubview:_hideIndicator];
		
		_gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerAction:)];
		[self addGestureRecognizer:_gestureRecognizer];
	}
	
	return  self;
}

- (void)tapGestureRecognizerAction:(UITapGestureRecognizer *)gestureRecognizer{
	[self.delegate hidingSectionHeaderView:self didTapSection:_index];
}

@end
