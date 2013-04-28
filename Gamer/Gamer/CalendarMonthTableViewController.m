//
//  CalendarMonthTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 4/28/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "CalendarMonthTableViewController.h"
#import "Game.h"
#import "GameTableViewController.h"

@interface CalendarMonthTableViewController ()

@end

@implementation CalendarMonthTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self.monthView selectDate:[NSDate date]];
	_calendarFetch = [self calendarFetchedResultsControllerForDate:[NSDate date]];
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - CalendarMonthView

- (NSArray *)calendarMonthView:(TKCalendarMonthView *)monthView marksFromDate:(NSDate *)startDate toDate:(NSDate *)lastDate{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	NSDateComponents *startDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:startDate];
	[startDateComponents setHour:9];
	NSDate *date = [calendar dateFromComponents:startDateComponents];
	
	NSDateComponents *lastDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:lastDate];
	[lastDateComponents setHour:9];
	NSDate *lastDateWithTime = [calendar dateFromComponents:lastDateComponents];
	
	NSFetchRequest *gameDatesRequest = [Game requestAllWithPredicate:[NSPredicate predicateWithFormat:@"releaseDate >= %@ AND releaseDate <= %@", date, lastDateWithTime]];
	[gameDatesRequest setResultType:NSDictionaryResultType];
	[gameDatesRequest setPropertiesToFetch:@[@"releaseDate"]];
	
	NSArray *datesFromGamesReleasedThisMonth = [[Game executeFetchRequest:gameDatesRequest] valueForKey:@"releaseDate"];
	
	NSMutableArray *marks;
	if (!marks) marks = [[NSMutableArray alloc] init];
	
	NSDateComponents *offsetComponents;
	if (!offsetComponents) offsetComponents = [[NSDateComponents alloc] init];
	[offsetComponents setDay:1];
	
	while (YES) {
		if ([date compare:lastDateWithTime] == NSOrderedDescending) break;
		[marks addObject:([datesFromGamesReleasedThisMonth containsObject:date]) ? @(YES) : @(NO)];
		date = [calendar dateByAddingComponents:offsetComponents toDate:date options:nil];
	}
	
	return marks;
}

- (void)calendarMonthView:(TKCalendarMonthView *)monthView monthWillChange:(NSDate *)month animated:(BOOL)animated{
	_calendarFetch = nil;
	[self.tableView reloadData];
}

- (void)calendarMonthView:(TKCalendarMonthView *)monthView didSelectDate:(NSDate *)date{
	_calendarFetch = [self calendarFetchedResultsControllerForDate:date];
	[self.tableView reloadData];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return _calendarFetch.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return [_calendarFetch.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
	
	Game *game = [_calendarFetch objectAtIndexPath:indexPath];
	[cell.textLabel setText:game.title];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Custom

- (NSFetchedResultsController *)calendarFetchedResultsControllerForDate:(NSDate *)date{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	NSDateComponents *dateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date];
	[dateComponents setHour:9];
	
	return [Game fetchAllGroupedBy:nil withPredicate:[NSPredicate predicateWithFormat:@"releaseDate == %@", [calendar dateFromComponents:dateComponents]] sortedBy:@"title" ascending:YES];
}

#pragma mark - Actions

- (IBAction)todayBarButtonAction:(UIBarButtonItem *)sender{
	[self.monthView selectDate:[NSDate date]];
	_calendarFetch = [self calendarFetchedResultsControllerForDate:[NSDate date]];
	[self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	GameTableViewController *destination = segue.destinationViewController;
	[destination setGame:[_calendarFetch objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
}

@end
