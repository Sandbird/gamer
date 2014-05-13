//
//  CustomSelectionCell.m
//  Gamer
//
//  Created by Caio Mello on 12/05/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "CustomSelectionCell.h"

@implementation CustomSelectionCell

- (void)awakeFromNib{
	[super awakeFromNib];
	
	UIView *cellBackgroundView = [UIView new];
	[cellBackgroundView setBackgroundColor:[UIColor darkGrayColor]];
	[cellBackgroundView.layer setMasksToBounds:YES];
	[self setSelectedBackgroundView:cellBackgroundView];
}

@end
