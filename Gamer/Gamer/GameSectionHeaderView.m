//
//  GameSectionHeaderView.m
//  Gamer
//
//  Created by Caio Mello on 22/07/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "GameSectionHeaderView.h"

@implementation GameSectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)init{
	self = [super initWithFrame:CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height)];
	if (self){
//		[self setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
		[self setBackgroundColor:[UIColor colorWithRed:.352941176 green:.352941176 blue:.352941176 alpha:1]];
		
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)];
//		[_titleLabel setBackgroundColor:[UIColor redColor]];
//		[_titleLabel setFont:[UIFont systemFontOfSize:15]];
		[_titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
		[_titleLabel setTextColor:[UIColor colorWithRed:.125490196 green:.125490196 blue:.125490196 alpha:1]];
		
		[self addSubview:_titleLabel];
	}
	return self;
}

@end
