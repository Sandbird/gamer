//
//  CalendarViewController.h
//  Gamer
//
//  Created by Caio Mello on 1/30/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TapkuLibrary/TapkuLibrary.h>
#import "Game.h"

@interface CalendarViewController : UIViewController <TKCalendarMonthViewDataSource, TKCalendarMonthViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) TKCalendarMonthView *calendarView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *games;
@property (nonatomic, strong) NSMutableArray *selectedDayGames;

@end
