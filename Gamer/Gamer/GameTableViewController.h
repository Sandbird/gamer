//
//  GameTableViewController.h
//  Gamer
//
//  Created by Caio Mello on 4/23/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"
#import "SearchResult.h"

@interface GameTableViewController : UITableViewController

@property (nonatomic, strong) Game *game;

@property (nonatomic, strong) SearchResult *searchResult;

@end
