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

@property (nonatomic, strong) NSFetchedResultsController *calendarFetch;

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
	NSFetchRequest *gameDatesRequest = [Game requestAllWithPredicate:[NSPredicate predicateWithFormat:@"releaseDate >= %@ AND releaseDate <= %@", startDate, lastDate]];
	[gameDatesRequest setResultType:NSDictionaryResultType];
	[gameDatesRequest setPropertiesToFetch:@[@"releaseDate"]];
	
	NSArray *datesFromGamesReleasedThisMonth = [[Game executeFetchRequest:gameDatesRequest] valueForKey:@"releaseDate"];
	
	NSMutableArray *marks;
	if (!marks) marks = [[NSMutableArray alloc] init];
	
	NSDateComponents *offsetComponents;
	if (!offsetComponents) offsetComponents = [[NSDateComponents alloc] init];
	[offsetComponents setDay:1];
	
	NSDate *date = startDate;
	
	while (YES) {
		if ([date compare:lastDate] == NSOrderedDescending) break;
		[marks addObject:([datesFromGamesReleasedThisMonth containsObject:date]) ? @(YES) : @(NO)];
		date = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:date options:nil];
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
	return [Game fetchAllGroupedBy:nil withPredicate:[NSPredicate predicateWithFormat:@"releaseDate == %@", date] sortedBy:@"title" ascending:YES];
}

#pragma mark - Actions

- (IBAction)todayBarButtonAction:(UIBarButtonItem *)sender{
	[self.monthView selectDate:[NSDate date]];
	_calendarFetch = [self calendarFetchedResultsControllerForDate:[Utilities dateWithoutTimeFromDate:[NSDate date]]];
	[self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	GameTableViewController *destination = segue.destinationViewController;
	[destination setGame:[_calendarFetch objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
}

@end
