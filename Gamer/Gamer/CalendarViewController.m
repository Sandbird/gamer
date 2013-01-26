//
//  CalendarViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "CalendarViewController.h"
#import "CalendarCell.h"

@interface CalendarViewController ()

@end

@implementation CalendarViewController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	[self.navigationItem setTitle:@""];
	
	KalViewController *calendar = [[KalViewController alloc] init];
	[calendar.tableView setDelegate:self];
	[calendar.tableView setDataSource:self];
	
//	[self.navigationController setViewControllers:@[calendar, self]];
	
	NSMutableArray *viewControllers = self.navigationController.viewControllers.mutableCopy;
	[viewControllers insertObject:calendar atIndex:0];
	[self.navigationController setViewControllers:viewControllers];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Kal

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate{
	
}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate{
	return nil;
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate{
	
}

- (void)removeAllItems{
	
}

- (void)showPreviousMonth{
	
}

- (void)showFollowingMonth{
	
}

- (void)didSelectDate:(KalDate *)date{
	
}

#pragma mark -
#pragma mark TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return 88;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CalendarCell"];
	
	if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CalendarCell"];
	
	[cell.textLabel setText:@"Gears of War: Judgement"];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//	[tableView deselectRowAtIndexPath:indexPath animated:YES];
//	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
}

@end
