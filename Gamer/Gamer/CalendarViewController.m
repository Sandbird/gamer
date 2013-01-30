//
//  CalendarViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/30/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "CalendarViewController.h"

@interface CalendarViewController ()

@end

@implementation CalendarViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	TKCalendarMonthView *calendarView = [[TKCalendarMonthView alloc] initWithSundayAsFirst:YES];
	[calendarView setDataSource:self];
	[calendarView setDelegate:self];
	[calendarView selectDate:[NSDate date]];
	[self.view addSubview:calendarView];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Calendar

- (void)calendarMonthView:(TKCalendarMonthView *)monthView didSelectDate:(NSDate *)date{
	
}

- (NSArray *)calendarMonthView:(TKCalendarMonthView *)monthView marksFromDate:(NSDate *)startDate toDate:(NSDate *)lastDate{
	return nil;
}

- (void)calendarMonthView:(TKCalendarMonthView *)monthView monthDidChange:(NSDate *)month animated:(BOOL)animated{
	
}

- (BOOL)calendarMonthView:(TKCalendarMonthView *)monthView monthShouldChange:(NSDate *)month animated:(BOOL)animated{
	return YES;
}

- (void)calendarMonthView:(TKCalendarMonthView *)monthView monthWillChange:(NSDate *)month animated:(BOOL)animated{
	
}

#pragma mark -
#pragma mark TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CalendarCell"];
	[cell.textLabel setText:@"Test"];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
}

@end
