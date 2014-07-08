//
//  SeparatorView.m
//  Gamer
//
//  Created by Caio Mello on 07/07/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "SeparatorView.h"

@implementation SeparatorView

- (void)awakeFromNib{
	CGFloat singlePixelHeight = 1.0/[UIScreen mainScreen].scale;
	
	UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, singlePixelHeight)];
	[separatorView setBackgroundColor:self.backgroundColor];
	[self addSubview:separatorView];
	
	[self setBackgroundColor:[UIColor clearColor]];
}

@end
