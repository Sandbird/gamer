//
//  GameController.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"

@interface GameController : UITableViewController

@property (nonatomic, strong) Game *game;
@property (nonatomic, strong) NSNumber *gameIdentifier;

@end
