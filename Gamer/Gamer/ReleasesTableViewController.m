//
//  ReleasesTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 4/23/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "ReleasesTableViewController.h"
#import "ReleasesCell.h"
#import "Game.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "ReleasePeriod.h"
#import "GameTableViewController.h"
#import "SearchTableViewController.h"
#import "ReleasesSectionHeaderView.h"

@interface ReleasesTableViewController ()

@end

@implementation ReleasesTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	self.fetchedResultsController = [self releasesFetchedResultsController];
//	[self.tableView reloadData];
}

- (void)viewDidLayoutSubviews{
//	ReleasesCell *cell = (ReleasesCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
//	[Utilities addDropShadowToView:cell.coverImageView color:[UIColor redColor] opacity:0.6 radius:10 offset:CGSizeZero];
}

- (void)viewWillAppear:(BOOL)animated{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	NSArray *games = [Game findAllWithPredicate:[NSPredicate predicateWithFormat:@"wanted = %@ AND selectedPlatform.favorite = %@", @(YES), @(YES)]];
	for (Game *game in games)
		[game setReleasePeriod:[self releasePeriodForGame:game]];
	[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		self.fetchedResultsController = [self releasesFetchedResultsController];
		NSLog(@"%d", self.fetchedResultsController.fetchedObjects.count);
		[self.tableView reloadData];
	}];
}

- (void)viewDidAppear:(BOOL)animated{
//	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.fetchedResultsController.sections.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
	ReleasesSectionHeaderView *headerView = [[ReleasesSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, tableView.sectionHeaderHeight)];
	[headerView.titleLabel setText:[[ReleasePeriod findFirstByAttribute:@"identifier" withValue:[self.fetchedResultsController.sections[section] name]] name]];
	
	return headerView;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//	return [[ReleasePeriod findFirstByAttribute:@"identifier" withValue:[_releasesFetch.sections[section] name]] name];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ReleasesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[game setWanted:@(NO)];
	[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		self.fetchedResultsController = [self releasesFetchedResultsController];
	}];
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	ReleasesCell *customCell = (ReleasesCell *)cell;
	
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[customCell.titleLabel setText:game.title];
	[customCell.dateLabel setText:([game.releasePeriod.identifier isEqualToNumber:@(8)]) ? @"" : game.releaseDateText];
	[customCell.coverImageView setImage:[UIImage imageWithData:game.coverImageSmall]];
	[customCell.platformLabel setText:game.selectedPlatform.nameShort];
	[customCell.platformLabel setBackgroundColor:game.selectedPlatform.color];
//	[Utilities addDropShadowToView:cell.coverImageView color:[UIColor redColor] opacity:0.6 radius:10 offset:CGSizeZero];
}

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)releasesFetchedResultsController{
	return [Game fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:[NSPredicate predicateWithFormat:@"wanted = %@ && selectedPlatform.favorite = %@", @(YES), @(YES)] sortedBy:@"releaseDate" ascending:YES delegate:self];
}

#pragma mark - Custom

- (NSInteger)quarterForMonth:(NSInteger)month{
	switch (month) {
		case 1: case 2: case 3: return 1;
		case 4: case 5: case 6: return 2;
		case 7: case 8: case 9: return 3;
		case 10: case 11: case 12: return 4;
		default: return 0;
	}
}

- (ReleasePeriod *)releasePeriodForGame:(Game *)game{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	// Components for today, this month, this quarter, this year
	NSDateComponents *currentComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	[currentComponents setQuarter:[self quarterForMonth:currentComponents.month]];
	
	// Components for next month, next quarter, next year
	NSDateComponents *nextComponents = [calendar components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	nextComponents.month++;
	[nextComponents setQuarter:[self quarterForMonth:nextComponents.month]];
	nextComponents.quarter++;
	nextComponents.year++;
	
	NSInteger period = 0;
	if ([game.releaseDate compare:[calendar dateFromComponents:currentComponents]] <= NSOrderedSame) period = 1;
	else if ([game.releaseMonth isEqualToNumber:@(currentComponents.month)]) period = 2;
	else if ([game.releaseMonth isEqualToNumber:@(nextComponents.month)]) period = 3;
	else if ([game.releaseQuarter isEqualToNumber:@(currentComponents.quarter)]) period = 4;
	else if ([game.releaseQuarter isEqualToNumber:@(nextComponents.quarter)]) period = 5;
	else if ([game.releaseYear isEqualToNumber:@(currentComponents.year)]) period = 6;
	else if ([game.releaseYear isEqualToNumber:@(nextComponents.year)]) period = 7;
	else if ([game.releaseYear isEqualToNumber:@(2050)]) period = 8;
	
	return [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(period)];
}

#pragma mark - Actions

- (IBAction)addBarButtonPressAction:(UIBarButtonItem *)sender{
	[self performSegueWithIdentifier:@"SearchSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
	}
	if ([segue.identifier isEqualToString:@"SearchSegue"]){
		SearchTableViewController *destination = [segue destinationViewController];
		[destination setOrigin:1];
	}
}

@end
