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

@interface GameViewController : UIViewController <UIActionSheetDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) IBOutlet UIView *contentView;

@property (nonatomic, strong) IBOutlet UIView *coverImageShadowView;
@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet UIView *metascoreView;
@property (nonatomic, strong) IBOutlet UILabel *metascoreLabel;

@property (nonatomic, strong) IBOutlet UILabel *releaseDateLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreSecondLabel;
@property (nonatomic, strong) IBOutlet UILabel *platformFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *platformSecondLabel;
@property (nonatomic, strong) IBOutlet UILabel *developerLabel;
@property (nonatomic, strong) IBOutlet UILabel *publisherLabel;
@property (nonatomic, strong) IBOutlet UILabel *franchiseFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *franchiseSecondLabel;
@property (nonatomic, strong) IBOutlet UILabel *themeFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *themeSecondLabel;

@property (nonatomic, strong) IBOutlet UIView *overviewContentView;
@property (nonatomic, strong) IBOutlet UITextView *overviewTextView;
@property (nonatomic, strong) IBOutlet UIView *imagesContentView;
@property (nonatomic, strong) IBOutlet UIScrollView *imagesScrollView;
@property (nonatomic, strong) IBOutlet UIView *videosContentView;
@property (nonatomic, strong) IBOutlet UIScrollView *videosScrollView;

@property (nonatomic, strong) Game *game;

@property (nonatomic, strong) SearchResult *searchResult;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) AFJSONRequestOperation *previousOperation;

@end
