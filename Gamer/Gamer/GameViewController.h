//
//  GameViewController.h
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"
#import "SearchResult.h"

@interface GameViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) IBOutlet UIView *contentView;

@property (nonatomic, strong) IBOutlet UIView *coverImageShadowView;
@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;

@property (nonatomic, strong) IBOutlet UIView *metascoreView;
@property (nonatomic, strong) IBOutlet UILabel *metascoreLabel;

@property (nonatomic, strong) IBOutlet UILabel *genreFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreSecondLabel;

@property (nonatomic, strong) IBOutlet UILabel *releaseDateLabel;

@property (nonatomic, strong) IBOutlet UITextView *summaryTextView;

@property (nonatomic, strong) IBOutlet UIView *overviewContentView;
@property (nonatomic, strong) IBOutlet UITextView *overviewTextView;

@property (nonatomic, strong) IBOutlet UIView *screenshotsContentView;

@property (nonatomic, strong) IBOutlet UIView *trailerContentView;
@property (nonatomic, strong) IBOutlet UIButton *trailerButton;

@property (nonatomic, strong) Game *game;

@property (nonatomic, strong) SearchResult *searchResult;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end
