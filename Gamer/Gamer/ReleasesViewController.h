//
//  ReleasesViewController.h
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"

@interface ReleasesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) Game *game0;
@property (nonatomic, strong) Game *game1;
@property (nonatomic, strong) Game *game2;
@property (nonatomic, strong) Game *game3;
@property (nonatomic, strong) Game *game4;
@property (nonatomic, strong) Game *game5;
@property (nonatomic, strong) Game *game6;

@property (nonatomic, strong) NSMutableArray *games;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end
