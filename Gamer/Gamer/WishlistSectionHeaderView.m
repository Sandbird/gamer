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

- (id)initWithReleasePeriod:(ReleasePeriod *)releasePeriod{
	self = [[NSBundle mainBundle] loadNibNamed:@"iPhone" owner:self options:nil][3];
	if (self){
		_releasePeriod = releasePeriod;
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (hidden = %@ AND wanted = %@)", releasePeriod.identifier, @(NO), @(YES)];
		NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
		_hidden = (gamesCount > 0) ? NO : YES;
		
		[_titleLabel setText:releasePeriod.name];
		
		if (!_hidden) [_hideIndicator setTransform:CGAffineTransformMakeRotation(M_PI/2)];
	}
	
	return  self;
}

- (IBAction)tapGestureRecognizerAction:(UITapGestureRecognizer *)gestureRecognizer{
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
