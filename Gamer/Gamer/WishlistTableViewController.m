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

@interface WishlistTableViewController () <FetchedTableViewDelegate, WishlistSectionHeaderViewDelegate>

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation WishlistTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
//	[self setEdgesForExtendedLayout:UIExtendedEdgeBottom];
	[self setEdgesForExtendedLayout:UIExtendedEdgeAll];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	self.fetchedResultsController = [self fetch];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] sendView:@"Wishlist"];
	
//	[self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 49, 0)];
	
	// Update game release periods
	NSArray *games = [Game findAllWithPredicate:[NSPredicate predicateWithFormat:@"wanted = %@ AND wishlistPlatform.favorite = %@", @(YES), @(YES)]];
	for (Game *game in games)
		[game setReleasePeriod:[self releasePeriodForReleaseDate:game.releaseDate]];
	[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		// Set sections to show if they have tracked games
		NSArray *releasePeriods = [ReleasePeriod findAll];
		
		for (ReleasePeriod *releasePeriod in releasePeriods){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (wanted = %@ AND wishlistPlatform.favorite = %@)", releasePeriod.identifier, @(YES), @(YES)];
//			NSArray *games = [Game findAllWithPredicate:predicate];
			NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
			
//			NSLog(@"hidden? %@ - %@ - %@ - %@ - count: %d", releasePeriod.placeholderGame.hidden, releasePeriod.placeholderGame.title, releasePeriod.identifier, releasePeriod.name, games.count);
			
			[releasePeriod.placeholderGame setHidden:(gamesCount > 0) ? @(NO) : @(YES)];
		}
		
		[_context saveToPersistentStoreAndWait];
	}];
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
	
	BOOL lastRow = (indexPath.row == ([tableView numberOfRowsInSection:indexPath.section] - 2)) ? YES : NO;
	[cell setSeparatorInset:UIEdgeInsetsMake(0, ((lastRow) ? 320 : 74), 0, 0)];
	
	[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[game setWanted:@(NO)];
	[game setWishlistPlatform:nil];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (wanted = %@ AND wishlistPlatform.favorite = %@)", game.releasePeriod.identifier, @(YES), @(YES)];
	NSArray *games = [Game findAllWithPredicate:predicate inContext:_context];
	
	if (games.count == 0)
		[game.releasePeriod.placeholderGame setHidden:@(YES)];
	
	[_context saveToPersistentStoreAndWait];
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WishlistCell *customCell = (WishlistCell *)cell;
	[customCell.titleLabel setText:game.title];
	[customCell.dateLabel setText:([game.releasePeriod.identifier isEqualToNumber:@(9)]) ? @"" : game.releaseDateText];
	[customCell.coverImageView setImage:[UIImage imageWithData:game.wishlistThumbnail]];
	[customCell.platformLabel setText:game.wishlistPlatform.abbreviation];
	[customCell.platformLabel setBackgroundColor:game.wishlistPlatform.color];
}

#pragma mark - HidingSectionView

- (void)wishlistSectionHeaderView:(WishlistSectionHeaderView *)sectionView didTapReleasePeriod:(ReleasePeriod *)releasePeriod{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (wanted = %@ AND wishlistPlatform.favorite = %@)", releasePeriod.identifier, @(YES), @(YES)];
	NSArray *games = [Game findAllWithPredicate:predicate];
	
	for (Game *game in games)
		[game setHidden:@(!game.hidden.boolValue)];
	
	[_context saveToPersistentStoreAndWait];
}

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)fetch{
	if (!self.fetchedResultsController){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hidden = %@ AND ((wanted = %@ AND wishlistPlatform.favorite = %@) OR identifier = nil)", @(NO), @(YES), @(YES)];
		
		self.fetchedResultsController = [Game fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:predicate sortedBy:@"releasePeriod.identifier,releaseDate.date,title" ascending:YES delegate:self];
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
	NSDateComponents *current = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	[current setQuarter:[self quarterForMonth:current.month]];
	
	// Components for next month, next quarter, next year
	NSDateComponents *next = [calendar components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	next.month++;
	[next setQuarter:current.quarter + 1];
	next.year++;
	
	NSInteger period = 0;
	if ([releaseDate.date compare:[calendar dateFromComponents:current]] <= NSOrderedSame) period = 1; // Released
	else{
		if (releaseDate.year.integerValue == 2050)
			period = 9; // TBA
		else if (releaseDate.year.integerValue > next.year)
			period = 8; // Later
		else if (releaseDate.year.integerValue == next.year){
			if (current.month == 12 && releaseDate.month.integerValue == 1)
				period = 3; // Next month
			else if (current.quarter == 4 && releaseDate.quarter.integerValue == 1)
				period = 5; // Next quarter
			else
				period = 7; // Next year
		}
		else if (releaseDate.year.integerValue == current.year){
			if (releaseDate.month.integerValue == current.month)
				period = 2; // This month
			else if (releaseDate.month.integerValue == next.month)
				period = 3; // Next month
			else if (releaseDate.quarter.integerValue == current.quarter)
				period = 4; // This quarter
			else if (releaseDate.quarter.integerValue == next.quarter)
				period = 5; // Next quarter
			else
				period = 6; // This year
		}
	}
	
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
