//
//  WishlistTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "WishlistTableViewController.h"
#import "WishlistCell.h"
#import "Game.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "ReleasePeriod.h"
#import "ReleaseDate.h"
#import "GameTableViewController.h"
#import "SearchTableViewController.h"

@interface WishlistTableViewController () <FetchedTableViewDelegate, WishlistSectionHeaderViewDelegate>

@end

@implementation WishlistTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIExtendedEdgeBottom];
	
	[self.tableView setBackgroundColor:[UIColor colorWithRed:.098039216 green:.098039216 blue:.098039216 alpha:1]];
	[self.tableView setSeparatorColor:[UIColor darkGrayColor]];
	
	self.fetchedResultsController = [self fetch];
	
	// Update game release periods
//	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
//	
//	NSFetchRequest *fetchRequest = [Game createFetchRequest];
//	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"wanted = %@ AND selectedPlatform.favorite = %@", @(YES), @(YES)]];
//	[fetchRequest setPropertiesToFetch:@[@"releaseDate", @"releasePeriod"]];
//	[fetchRequest setRelationshipKeyPathsForPrefetching:@[@"releaseDate", @"releasePeriod"]];
//	NSArray *games = [Game executeFetchRequest:fetchRequest];
//	
//	for (Game *game in games)
//		[game setReleasePeriod:[self releasePeriodForReleaseDate:game.releaseDate]];
//
//	[context saveToPersistentStoreAndWait];
}

- (void)viewDidAppear:(BOOL)animated{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	
//	NSFetchRequest *fRequest = [ReleasePeriod createFetchRequest];
//	[fetchRequest setPropertiesToFetch:@[@"placeholderGame.hidden"]];
//	[fRequest setRelationshipKeyPathsForPrefetching:@[@"games", @"placeholderGame"]];
//	NSArray *releasePeriods = [ReleasePeriod executeFetchRequest:fRequest];
	
	// Set sections to show if they have tracked games
	NSArray *releasePeriods = [ReleasePeriod findAll];
	
	for (ReleasePeriod *releasePeriod in releasePeriods){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (wanted = %@ AND selectedPlatform.favorite = %@)", releasePeriod.identifier, @(YES), @(YES)];
		NSArray *games = [Game findAllWithPredicate:predicate];
		
//		NSLog(@"hidden? %@ - %@ - %@ - %@ - count: %d", releasePeriod.placeholderGame.hidden, releasePeriod.placeholderGame.title, releasePeriod.identifier, releasePeriod.name, games.count);
		
		[releasePeriod.placeholderGame setHidden:(games.count > 0) ? @(NO) : @(YES)];
	}
	
	[context saveToPersistentStoreAndWait];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.fetchedResultsController.sections.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
	NSString *sectionName = [self.fetchedResultsController.sections[section] name];
	ReleasePeriod *releasePeriod = [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(sectionName.integerValue)];
	
	WishlistSectionHeaderView *headerView = [[WishlistSectionHeaderView alloc] initWithReleasePeriod:releasePeriod];
	[headerView setDelegate:self];
	
	return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	return (game.identifier) ? tableView.rowHeight : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    WishlistCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell setBackgroundColor:[UIColor colorWithRed:.125490196 green:.125490196 blue:.125490196 alpha:1]];
	[cell setSeparatorInset:UIEdgeInsetsMake(0, 74, 0, 0)];
	[cell.titleLabel setTextColor:[UIColor lightGrayColor]];
	[cell.dateLabel setTextColor:[UIColor grayColor]];
	
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
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (wanted = %@ AND selectedPlatform.favorite = %@)", game.releasePeriod.identifier, @(YES), @(YES)];
	NSArray *games = [Game findAllWithPredicate:predicate inContext:context];
	
	if (games.count == 0)
		[game.releasePeriod.placeholderGame setHidden:@(YES)];
	
	[context saveToPersistentStoreAndWait];
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WishlistCell *customCell = (WishlistCell *)cell;
	[customCell.titleLabel setText:game.title];
	[customCell.dateLabel setText:([game.releasePeriod.identifier isEqualToNumber:@(8)]) ? @"" : game.releaseDateText];
	[customCell.coverImageView setImage:[UIImage imageWithData:game.thumbnail]];
	[customCell.platformLabel setText:game.selectedPlatform.abbreviation];
	[customCell.platformLabel setBackgroundColor:game.selectedPlatform.color];
}

#pragma mark - HidingSectionView

- (void)wishlistSectionHeaderView:(WishlistSectionHeaderView *)sectionView didTapReleasePeriod:(ReleasePeriod *)releasePeriod{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (wanted = %@ AND selectedPlatform.favorite = %@)", releasePeriod.identifier, @(YES), @(YES)];
	NSArray *games = [Game findAllWithPredicate:predicate];
	
	for (Game *game in games)
		[game setHidden:@(!game.hidden.boolValue)];
	
	[context saveToPersistentStoreAndWait];
}

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)fetch{
	if (!self.fetchedResultsController){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hidden = %@ AND ((wanted = %@ AND selectedPlatform.favorite = %@) OR identifier = nil)", @(NO), @(YES), @(YES)];
		
		self.fetchedResultsController = [Game fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:predicate sortedBy:@"releasePeriod.identifier,releaseDate.date" ascending:YES delegate:self];
	}
	
	return self.fetchedResultsController;
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

- (ReleasePeriod *)releasePeriodForReleaseDate:(ReleaseDate *)releaseDate{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	// Components for today, this month, this quarter, this year
	NSDateComponents *currentComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	[currentComponents setQuarter:[self quarterForMonth:currentComponents.month]];
	
	// Components for next month, next quarter, next year
	NSDateComponents *nextComponents = [calendar components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	nextComponents.month++;
	[nextComponents setQuarter:[self quarterForMonth:nextComponents.month]];
	nextComponents.year++;
	
	NSInteger period = 0;
	if ([releaseDate.date compare:[calendar dateFromComponents:currentComponents]] <= NSOrderedSame) period = 1;
	else if ([releaseDate.month isEqualToNumber:@(currentComponents.month)]) period = 2;
	else if ([releaseDate.month isEqualToNumber:@(nextComponents.month)]) period = 3;
	else if ([releaseDate.quarter isEqualToNumber:@(currentComponents.quarter)]) period = 4;
	else if ([releaseDate.quarter isEqualToNumber:@(nextComponents.quarter)]) period = 5;
	else if ([releaseDate.year isEqualToNumber:@(currentComponents.year)]) period = 6;
	else if ([releaseDate.year isEqualToNumber:@(nextComponents.year)]) period = 7;
	else if ([releaseDate.year isEqualToNumber:@(2050)]) period = 8;
	
	return [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(period)];
}

#pragma mark - Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
	}
}

@end
