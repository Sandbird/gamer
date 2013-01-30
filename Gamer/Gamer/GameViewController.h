//
//  GameViewController.h
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"

@interface GameViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;

@property (nonatomic, strong) Game *game;

@end
