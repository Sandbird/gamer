//
//  CalendarViewController.h
//  Gamer
//
//  Created by Caio Mello on 1/30/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TapkuLibrary/TapkuLibrary.h>

@interface CalendarViewController : UIViewController <TKCalendarMonthViewDataSource, TKCalendarMonthViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end
