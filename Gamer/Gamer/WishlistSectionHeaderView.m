//
//  WishlistSectionHeaderView.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "WishlistSectionHeaderView.h"
#import "Game.h"

@implementation WishlistSectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithReleasePeriod:(ReleasePeriod *)releasePeriod{
	self = [super initWithFrame:CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height)];
	if (self){
		_releasePeriod = releasePeriod;
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (hidden = %@ AND wanted = %@ AND selectedPlatform.favorite = %@)", releasePeriod.identifier, @(NO), @(YES), @(YES)];
		NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
		_hidden = (gamesCount > 0) ? NO : YES;
		
		[self setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
//		[self setBackgroundColor:[UIColor colorWithRed:.156862745 green:.156862745 blue:.156862745 alpha:1]];
		
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 11, 221, 22)];
		[_titleLabel setBackgroundColor:[UIColor clearColor]];
//		[_titleLabel setTextColor:[[UIApplication sharedApplication] keyWindow].tintColor];
		[_titleLabel setTextColor:[UIColor orangeColor]];
//		[_titleLabel setFont:[UIFont systemFontOfSize:18]];
		[_titleLabel setText:releasePeriod.name];
		
		_hideIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(276, 10, 24, 24)];
		[_hideIndicator setImage:[UIImage imageNamed:@"HideArrow"]];
		
		[self addSubview:_titleLabel];
		[self addSubview:_hideIndicator];
		
		if (_hidden) [_hideIndicator setTransform:CGAffineTransformMakeRotation(M_PI)];
		
		_gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerAction:)];
		[self addGestureRecognizer:_gestureRecognizer];
	}
	
	return  self;
}

- (void)tapGestureRecognizerAction:(UITapGestureRecognizer *)gestureRecognizer{
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	[animation setDelegate:self];
	[animation setFromValue:@(_hidden ? M_PI : 0)];
	[animation setToValue:@(_hidden ? 0 : M_PI)];
	[animation setDuration:0.3];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	[_hideIndicator.layer addAnimation:animation forKey:@"rotation"];
	
	[self.delegate wishlistSectionHeaderView:self didTapReleasePeriod:_releasePeriod];
}

- (void)animationDidStart:(CAAnimation *)anim{
	[_hideIndicator setTransform:CGAffineTransformMakeRotation(_hidden ? 0 : M_PI)];
	_hidden = !_hidden;
}

@end
