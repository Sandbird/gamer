//
//  GameViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "GameViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface GameViewController ()

@end

@implementation GameViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self.navigationItem setTitle:[_game.title componentsSeparatedByString:@":"][0]];
	
	[_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height + 1)];
	
	// UI setup
//	[_coverImageView setClipsToBounds:NO];
//	[_coverImageView.layer setShadowPath:[UIBezierPath bezierPathWithRect:_coverImageView.bounds].CGPath];
//	[_coverImageView.layer setShadowColor:[UIColor darkGrayColor].CGColor];
//	[_coverImageView.layer setShadowOpacity:0.6];
//	[_coverImageView.layer setShadowRadius:2];
//	[_coverImageView.layer setShadowOffset:CGSizeMake(0, 2)];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

@end
