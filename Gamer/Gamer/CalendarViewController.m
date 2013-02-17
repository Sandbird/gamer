//
//  CalendarViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/30/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "CalendarViewController.h"
#import "GameViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CalendarViewController ()

@end

@implementation CalendarViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	_calendarView = [[TKCalendarMonthView alloc] initWithSundayAsFirst:NO];
	[_calendarView setDataSource:self];
	[_calendarView setDelegate:self];
	[self.view addSubview:_calendarView];
	
	_games = [[NSMutableArray alloc] init];
	_games = [Game findAllSortedBy:@"releaseDate" ascending:YES].mutableCopy;
	
	_selectedDayGames = [[NSMutableArray alloc] init];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[_calendarView selectDate:[NSDate date]];
	});
}

- (void)viewDidAppear:(BOOL)animated{
	_games = [Game findAllSortedBy:@"releaseDate" ascending:YES].mutableCopy;
	[_calendarView reload];
	[_tableView reloadData];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Calendar

- (void)calendarMonthView:(TKCalendarMonthView *)monthView didSelectDate:(NSDate *)date{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSDateComponents *components = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date];
	NSDate *calendarDate = [calendar dateFromComponents:components];
	
	_selectedDayGames = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"releaseDate == %@", calendarDate]].mutableCopy;
	
	[_tableView reloadData];
}

- (NSArray *)calendarMonthView:(TKCalendarMonthView *)monthView marksFromDate:(NSDate *)startDate toDate:(NSDate *)lastDate{
	// Resize TableView
//	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"bounds"];
//	animation.duration = 1;
//	animation.fromValue = [NSValue valueWithCGRect:_tableView.bounds];
//	if ([startDate daysBetweenDate:lastDate] == 34 && _tableView.frame.origin.y == 309)
//		animation.toValue = [NSValue valueWithCGRect:CGRectMake(_tableView.frame.origin.x, 265, _tableView.frame.size.width, 82)];
//	else if ([startDate daysBetweenDate:lastDate] == 41 && _tableView.frame.origin.y == 265)
//		animation.toValue = [NSValue valueWithCGRect:CGRectMake(_tableView.frame.origin.x, 309, _tableView.frame.size.width, 38)];
//	[_tableView.layer addAnimation:animation forKey:@"bounds"];
	
	if ([startDate daysBetweenDate:lastDate] == 34 && _tableView.frame.origin.y == 309)
		[_tableView setFrame:CGRectMake(_tableView.frame.origin.x, 265, _tableView.frame.size.width, 102)];
	else if ([startDate daysBetweenDate:lastDate] == 41 && _tableView.frame.origin.y == 265)
		[_tableView setFrame:CGRectMake(_tableView.frame.origin.x, 309, _tableView.frame.size.width, 58)];
	
	NSMutableArray *monthDates = [[NSMutableArray alloc] init];
	
	for (Game *game in _games)
		if ([game.releaseDate compare:startDate] == NSOrderedDescending && [game.releaseDate compare:lastDate] == NSOrderedAscending)
			[monthDates addObject:game.releaseDate];
	
	NSMutableArray *marks = [[NSMutableArray alloc] init];
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSDateComponents *components = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:startDate];
	NSDate *date = [calendar dateFromComponents:components];
	
	NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
	[offsetComponents setDay:1];
	
	while (YES){
		if ([date compare:lastDate] == NSOrderedDescending)
			break;
		
		if ([monthDates containsObject:date])
			[marks addObject:@(YES)];
		else
			[marks addObject:@(NO)];
		
		date = [calendar dateByAddingComponents:offsetComponents toDate:date options:nil];
	}
	
	return marks;
}

- (BOOL)calendarMonthView:(TKCalendarMonthView *)monthView monthShouldChange:(NSDate *)month animated:(BOOL)animated{
	return YES;
}

- (void)calendarMonthView:(TKCalendarMonthView *)monthView monthWillChange:(NSDate *)month animated:(BOOL)animated{
	[_calendarView reload];
	[_selectedDayGames removeAllObjects];
	[_tableView reloadData];
}

- (void)calendarMonthView:(TKCalendarMonthView *)monthView monthDidChange:(NSDate *)month animated:(BOOL)animated{
	
}

#pragma mark -
#pragma mark TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return _selectedDayGames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CalendarCell"];
	
	Game *game = _selectedDayGames[indexPath.row];
	[cell.textLabel setText:game.title];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Actions

- (IBAction)todayButtonPressAction:(UIBarButtonItem *)sender{
	[_calendarView selectDate:[NSDate date]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	GameViewController *destination = segue.destinationViewController;
	[destination setGame:_games[_tableView.indexPathForSelectedRow.row]];
}

@end
