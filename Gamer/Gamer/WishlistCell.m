//
//  WishlistCell.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "WishlistCell.h"

@implementation WishlistCell

- (void)awakeFromNib{
	[super awakeFromNib];
	
	UIView *cellBackgroundView = [UIView new];
	[cellBackgroundView setBackgroundColor:[UIColor darkGrayColor]];
	[cellBackgroundView.layer setMasksToBounds:YES];
	[self setSelectedBackgroundView:cellBackgroundView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
	UIColor *platformColor = self.platformLabel.backgroundColor;
	
    [super setSelected:selected animated:animated];
	
	[self.platformLabel setBackgroundColor:platformColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
	UIColor *platformColor = self.platformLabel.backgroundColor;
	
	[super setHighlighted:highlighted animated:animated];
	
	if (highlighted){
		[self.platformLabel setBackgroundColor:platformColor];
	}
}

@end
