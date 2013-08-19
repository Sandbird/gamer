//
//  ContentStatusView.m
//  Gamer
//
//  Created by Caio Mello on 17/08/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "ContentStatusView.h"

@implementation ContentStatusView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithUnavailableTitle:(NSString *)title{
	self = [super initWithFrame:CGRectMake(0, 0, 320, 180)];
	if (self){
		[self setBackgroundColor:[UIColor blackColor]];
		
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 21)];
		[_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		[_titleLabel setBackgroundColor:[UIColor clearColor]];
		[_titleLabel setTextColor:[UIColor lightGrayColor]];
		[_titleLabel setFont:[UIFont systemFontOfSize:14]];
		[_titleLabel setText:title];
		[self addSubview:_titleLabel];
		
		_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[_activityIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
		[self addSubview:_activityIndicator];
		
		// Center title
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
		[self addConstraint:constraint];
		constraint = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
		[self addConstraint:constraint];
		
		// Center actitivy indicator
		constraint = [NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
		[self addConstraint:constraint];
		constraint = [NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
		[self addConstraint:constraint];
	}
	
	return  self;
}

- (void)setStatus:(ContentStatus)contentStatus{
	switch (contentStatus) {
		case ContentStatusUnavailable:
			[_titleLabel setHidden:NO];
			[_activityIndicator stopAnimating];
			break;
		case ContentStatusLoading:
			[_titleLabel setHidden:YES];
			[_activityIndicator startAnimating];
			break;
		default:
			break;
	}
	
	[_titleLabel.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
}

@end
