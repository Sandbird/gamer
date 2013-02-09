//
//  ReleasesViewController.h
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReleasesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *games;

@property (nonatomic, strong) NSMutableArray *gamesReleasingThisMonth;
@property (nonatomic, strong) NSMutableArray *gamesReleasingNextMonth;
@property (nonatomic, strong) NSMutableArray *gamesReleasingThisQuarter;
@property (nonatomic, strong) NSMutableArray *gamesReleasingNextQuarter;
@property (nonatomic, strong) NSMutableArray *gamesReleasingThisYear;
@property (nonatomic, strong) NSMutableArray *gamesReleasingNextYear;

@end
