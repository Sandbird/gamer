//
//  GameViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "GameViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

@interface GameViewController ()

@end

@implementation GameViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self.navigationItem setTitle:[_game.title componentsSeparatedByString:@":"][0]];
	
	// UI setup
	[_coverImageShadowView setClipsToBounds:NO];
	[_coverImageShadowView.layer setShadowPath:[UIBezierPath bezierPathWithRect:_coverImageShadowView.bounds].CGPath];
	[_coverImageShadowView.layer setShadowColor:[UIColor blackColor].CGColor];
	[_coverImageShadowView.layer setShadowOpacity:0.6];
	[_coverImageShadowView.layer setShadowRadius:5];
	[_coverImageShadowView.layer setShadowOffset:CGSizeMake(0, 0)];
	
	[_metascoreView setClipsToBounds:NO];
	[_metascoreView.layer setShadowPath:[UIBezierPath bezierPathWithRect:_metascoreView.bounds].CGPath];
	[_metascoreView.layer setShadowColor:[UIColor blackColor].CGColor];
	[_metascoreView.layer setShadowOpacity:0.6];
	[_metascoreView.layer setShadowRadius:5];
	[_metascoreView.layer setShadowOffset:CGSizeMake(0, 0)];
	
	_dateFormatter = [[NSDateFormatter alloc] init];
	[_dateFormatter setDateFormat:@"dd/MM/yyyy"];
	
	// Set data
	[_releaseDateLabel setText:[_dateFormatter stringFromDate:_game.releaseDate]];
	[_genreFirstLabel setText:[[_game.genres allObjects][0] name]];
	[_genreSecondLabel setText:[[_game.genres allObjects][1] name]];
	[_summaryTextView setText:_game.summary];
	[_overviewTextView setText:_game.overview];
	
	// Resize content
	[_summaryTextView setFrame:CGRectMake(_summaryTextView.frame.origin.x, _summaryTextView.frame.origin.y, _summaryTextView.contentSize.width, _summaryTextView.contentSize.height)];
	[_overviewContentView setFrame:CGRectMake(0, _summaryTextView.frame.origin.y + _summaryTextView.frame.size.height + 10, 320, (_overviewContentView.frame.size.height))];
	[_overviewTextView setFrame:CGRectMake(_overviewTextView.frame.origin.x, _overviewTextView.frame.origin.y, _overviewTextView.contentSize.width, _overviewTextView.contentSize.height)];
	[_overviewContentView setFrame:CGRectMake(0, _overviewContentView.frame.origin.y, 320, _overviewTextView.frame.origin.y + _overviewTextView.frame.size.height + 10)];
	[_screenshotsContentView setFrame:CGRectMake(0, _overviewContentView.frame.origin.y + _overviewContentView.frame.size.height, 320, _screenshotsContentView.frame.size.height)];
	[_trailerContentView setFrame:CGRectMake(0, _screenshotsContentView.frame.origin.y + _screenshotsContentView.frame.size.height, 320, _trailerContentView.frame.size.height)];
	[_contentView setFrame:CGRectMake(0, 0, 320, _trailerContentView.frame.origin.y + _trailerContentView.frame.size.height)];
	
	[_scrollView setContentSize:CGSizeMake(_contentView.frame.size.width, _contentView.frame.size.height)];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Actions

- (IBAction)trailerButtonPressAction:(UIButton *)sender{
	MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:_game.trailerURL]];
	player.controlStyle=MPMovieControlStyleDefault;
	player.shouldAutoplay=YES;
	[self.view addSubview:player.view];
	[player setFullscreen:YES animated:YES];
}

@end
