//
//  WishlistSectionHeaderView.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "WishlistSectionHeaderView.h"
#import "Game.h"

@implementation WishlistSectionHeaderView

- (id)initWithReleasePeriod:(ReleasePeriod *)releasePeriod{
	self = [[NSBundle mainBundle] loadNibNamed:@"iPhone" owner:self options:nil][3];
	if (self){
		_releasePeriod = releasePeriod;
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod = %@ AND (hidden = %@ AND location = %@)", releasePeriod, @(NO), @(GameLocationWishlist)];
		NSInteger gamesCount = [Game MR_countOfEntitiesWithPredicate:predicate];
		_hidden = (gamesCount > 0) ? NO : YES;
		
		[_titleLabel setText:releasePeriod.name];
		
		if (!_hidden) [_hideIndicator setTransform:CGAffineTransformMakeRotation(M_PI/2)];
	}
	
	return  self;
}

- (IBAction)tapGestureRecognizerAction:(UITapGestureRecognizer *)gestureRecognizer{
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	[animation setDelegate:self];
	[animation setFromValue:@(self.hidden ? 0 : M_PI/2)];
	[animation setToValue:@(self.hidden ? M_PI/2 : 0)];
	[animation setDuration:0.3];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	[self.hideIndicator.layer addAnimation:animation forKey:@"rotation"];
	
	[self.delegate wishlistSectionHeaderView:self didTapReleasePeriod:self.releasePeriod];
}

- (void)animationDidStart:(CAAnimation *)anim{
	[self.hideIndicator setTransform:CGAffineTransformMakeRotation(self.hidden ? M_PI/2 : 0)];
	self.hidden = !self.hidden;
}

@end
