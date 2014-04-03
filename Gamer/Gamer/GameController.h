//
//  GameController.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"

@interface GameController : UITableViewController

@property (nonatomic, strong) Game *game;
@property (nonatomic, strong) NSNumber *gameIdentifier;

- (IBAction)addButtonPressAction:(UIButton *)sender;
- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender;

@end
