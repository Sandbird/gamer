//
//  PlatformCell.m
//  Gamer
//
//  Created by Caio Mello on 7/9/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "PlatformCell.h"

@implementation PlatformCell

- (void)awakeFromNib{
	[super awakeFromNib];
	
	UIView *cellBackgroundView = [UIView new];
	[cellBackgroundView setBackgroundColor:[UIColor darkGrayColor]];
	[cellBackgroundView.layer setMasksToBounds:YES];
	[self setSelectedBackgroundView:cellBackgroundView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
	UIColor *platformColor = self.abbreviationLabel.backgroundColor;
	
    [super setSelected:selected animated:animated];
	
	[self.abbreviationLabel setBackgroundColor:platformColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
	UIColor *platformColor = self.abbreviationLabel.backgroundColor;
	
	[super setHighlighted:highlighted animated:animated];
	
	if (highlighted){
		[self.abbreviationLabel setBackgroundColor:platformColor];
	}
}

@end
