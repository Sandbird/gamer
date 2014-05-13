//
//  SearchCell.m
//  Gamer
//
//  Created by Caio Mello on 03/08/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "SearchCell.h"

@implementation SearchCell

- (void)awakeFromNib{
	[super awakeFromNib];
	
	UIView *cellBackgroundView = [UIView new];
	[cellBackgroundView setBackgroundColor:[UIColor darkGrayColor]];
	[cellBackgroundView.layer setMasksToBounds:YES];
	[self setSelectedBackgroundView:cellBackgroundView];
}

@end
