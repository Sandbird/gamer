//
//  MetascoreCell.m
//  Gamer
//
//  Created by Caio Mello on 05/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "MetascoreCell.h"

@implementation MetascoreCell

- (void)awakeFromNib{
	[super awakeFromNib];
	
	UIView *cellBackgroundView = [UIView new];
	[cellBackgroundView setBackgroundColor:[UIColor darkGrayColor]];
	[cellBackgroundView.layer setMasksToBounds:YES];
	[self setSelectedBackgroundView:cellBackgroundView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
	UIColor *criticColor = self.criticScoreLabel.backgroundColor;
	UIColor *userColor = self.userScoreLabel.backgroundColor;
	UIColor *platformColor = self.platformLabel.backgroundColor;
	
	[super setSelected:selected animated:animated];
	
	[self.criticScoreLabel setBackgroundColor:criticColor];
	[self.userScoreLabel setBackgroundColor:userColor];
	[self.platformLabel setBackgroundColor:platformColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
	UIColor *criticColor = self.criticScoreLabel.backgroundColor;
	UIColor *userColor = self.userScoreLabel.backgroundColor;
	UIColor *platformColor = self.platformLabel.backgroundColor;
	
	[super setHighlighted:highlighted animated:animated];
	
	if (highlighted){
		[self.criticScoreLabel setBackgroundColor:criticColor];
		[self.userScoreLabel setBackgroundColor:userColor];
		[self.platformLabel setBackgroundColor:platformColor];
	}
}

@end
