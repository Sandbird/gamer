//
//  ContentStatusView.m
//  Gamer
//
//  Created by Caio Mello on 17/08/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "ContentStatusView.h"

@implementation ContentStatusView

- (id)initWithUnavailableTitle:(NSString *)title{
	self = [[NSBundle mainBundle] loadNibNamed:[Tools deviceIsiPhone] ? @"iPhone" : @"iPad" owner:self options:nil][ViewIndexContentStatusView];
	if (self) {
		[_statusLabel setText:title];
	}
	return self;
}

- (void)setStatus:(ContentStatus)contentStatus{
	switch (contentStatus) {
		case ContentStatusUnavailable:
			[self.statusLabel setHidden:NO];
			[self.activityIndicator stopAnimating];
			break;
		case ContentStatusLoading:
			[self.statusLabel setHidden:YES];
			[self.activityIndicator startAnimating];
			break;
		default:
			break;
	}
	
	[self.statusLabel.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
}

@end
