//
//  ReleaseCell.m
//  Gamer
//
//  Created by Caio Mello on 05/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "ReleaseCell.h"

@implementation ReleaseCell

- (void)awakeFromNib{
	[super awakeFromNib];
	
	UIView *cellBackgroundView = [UIView new];
	[cellBackgroundView setBackgroundColor:[UIColor darkGrayColor]];
	[cellBackgroundView.layer setMasksToBounds:YES];
	[self setSelectedBackgroundView:cellBackgroundView];
}

@end
