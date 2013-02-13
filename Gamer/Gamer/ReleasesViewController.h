//
//  ReleasesViewController.h
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReleasesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) UITapGestureRecognizer *thisMonthGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *nextMonthGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *thisQuarterGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *nextQuarterGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *thisYearGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *nextYearGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *releasedGestureRecognizer;

@property (nonatomic, strong) NSMutableArray *games;
@property (nonatomic, strong) NSMutableArray *gamesReleasingThisMonth;
@property (nonatomic, strong) NSMutableArray *gamesReleasingNextMonth;
@property (nonatomic, strong) NSMutableArray *gamesReleasingThisQuarter;
@property (nonatomic, strong) NSMutableArray *gamesReleasingNextQuarter;
@property (nonatomic, strong) NSMutableArray *gamesReleasingThisYear;
@property (nonatomic, strong) NSMutableArray *gamesReleasingNextYear;
@property (nonatomic, strong) NSMutableArray *gamesReleased;

@property (nonatomic, strong) NSMutableArray *indexPaths;

@end
