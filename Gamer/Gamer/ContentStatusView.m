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
