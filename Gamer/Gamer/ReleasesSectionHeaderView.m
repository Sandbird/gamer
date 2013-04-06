//
//  ReleasesSectionHeaderView.m
//  Gamer
//
//  Created by Caio Mello on 4/6/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "ReleasesSectionHeaderView.h"

@implementation ReleasesSectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		
		_iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 34, 34)];
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(47, 11, 221, 22)];
		_hideIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(276, 10, 24, 24)];
		
		[self addSubview:_iconImageView];
		[self addSubview:_titleLabel];
		[self addSubview:_hideIndicator];
		
		[self setBackgroundColor:[UIColor lightGrayColor]];
		
		[_iconImageView setBackgroundColor:[UIColor blackColor]];
		
		[_titleLabel setBackgroundColor:[UIColor clearColor]];
		[_titleLabel setTextColor:[UIColor darkGrayColor]];
		[_titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:16]];
		
		[_hideIndicator setBackgroundColor:[UIColor blackColor]];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
