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
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (hidden = %@ AND wanted = %@ AND wishlistPlatform in %@)", releasePeriod.identifier, @(NO), @(YES), [SessionManager gamer].platforms];
		NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
		_hidden = (gamesCount > 0) ? NO : YES;
		
		[self setBackgroundColor:[UIColor colorWithRed:.203921569 green:.203921569 blue:.203921569 alpha:1]];
		
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 11, 221, 22)];
		[_titleLabel setBackgroundColor:[UIColor clearColor]];
//		[_titleLabel setTextColor:[[UIApplication sharedApplication] keyWindow].tintColor];
		[_titleLabel setTextColor:[UIColor orangeColor]];
//		[_titleLabel setFont:[UIFont systemFontOfSize:18]];
		[_titleLabel setText:releasePeriod.name];
		[self addSubview:_titleLabel];
		
		_hideIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(276, 10, 24, 24)];
		[_hideIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
		[_hideIndicator setImage:[UIImage imageNamed:@"HideArrow"]];
		[self addSubview:_hideIndicator];
		
		if (!_hidden) [_hideIndicator setTransform:CGAffineTransformMakeRotation(M_PI/2)];
		
		_gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerAction:)];
		[self addGestureRecognizer:_gestureRecognizer];
		
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_hideIndicator attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:-20];
		[self addConstraint:constraint];
	}
	
	return  self;
}

- (void)tapGestureRecognizerAction:(UITapGestureRecognizer *)gestureRecognizer{
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	[animation setDelegate:self];
	[animation setFromValue:@(_hidden ? 0 : M_PI/2)];
	[animation setToValue:@(_hidden ? M_PI/2 : 0)];
	[animation setDuration:0.3];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	[_hideIndicator.layer addAnimation:animation forKey:@"rotation"];
	
	[self.delegate wishlistSectionHeaderView:self didTapReleasePeriod:_releasePeriod];
}

- (void)animationDidStart:(CAAnimation *)anim{
	[_hideIndicator setTransform:CGAffineTransformMakeRotation(_hidden ? M_PI/2 : 0)];
	_hidden = !_hidden;
}

@end
