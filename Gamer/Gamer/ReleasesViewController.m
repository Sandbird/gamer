//
//  ReleasesViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "ReleasesViewController.h"
#import "ReleasesCell.h"
#import "ReleasesSectionHeaderView.h"
#import "Game.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "GameViewController.h"

#define thisMonthTag 10
#define nextMonthTag 11
#define thisQuarterTag 12
#define nextQuarterTag 13
#define thisYearTag 14
#define nextYearTag 15
#define toBeAnnouncedTag 16
#define releasedTag 17

@interface ReleasesViewController ()

@end

@implementation ReleasesViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
//	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
//	[Game truncateAll];
//	[Genre truncateAll];
//	[Platform truncateAll];
//	[Developer truncateAll];
//	[Publisher truncateAll];
//	[Franchise truncateAll];
//	[Theme truncateAll];
//	[context saveToPersistentStoreAndWait];
	
	_games = [[NSMutableArray alloc] init];
	_gamesReleasingThisMonth = [[NSMutableArray alloc] init];
	_gamesReleasingNextMonth = [[NSMutableArray alloc] init];
	_gamesReleasingThisQuarter = [[NSMutableArray alloc] init];
	_gamesReleasingNextQuarter = [[NSMutableArray alloc] init];
	_gamesReleasingThisYear = [[NSMutableArray alloc] init];
	_gamesReleasingNextYear = [[NSMutableArray alloc] init];
	_gamesToBeAnnounced = [[NSMutableArray alloc] init];
	_gamesReleased = [[NSMutableArray alloc] init];
	
	_thisMonthGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	[_thisMonthGestureRecognizer setDelegate:self];
	
	_nextMonthGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	[_nextMonthGestureRecognizer setDelegate:self];
	
	_thisQuarterGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	[_thisQuarterGestureRecognizer setDelegate:self];
	
	_nextQuarterGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	[_nextQuarterGestureRecognizer setDelegate:self];
	
	_thisYearGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	[_thisYearGestureRecognizer setDelegate:self];
	
	_nextYearGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	[_nextYearGestureRecognizer setDelegate:self];
	
	_releasedGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	[_releasedGestureRecognizer setDelegate:self];
	
	_toBeAnnouncedGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	[_toBeAnnouncedGestureRecognizer setDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated{
	_indexPaths = [[NSMutableArray alloc] init];
	
	[_games removeAllObjects];
	
	[self setTimePeriodForGamesInDatabase];
	[self reloadArrayForSectionWithTag:thisMonthTag removeFromParentArray:YES];
	[self reloadArrayForSectionWithTag:nextMonthTag removeFromParentArray:YES];
	[self reloadArrayForSectionWithTag:thisQuarterTag removeFromParentArray:YES];
	[self reloadArrayForSectionWithTag:nextQuarterTag removeFromParentArray:YES];
	[self reloadArrayForSectionWithTag:thisYearTag removeFromParentArray:YES];
	[self reloadArrayForSectionWithTag:nextYearTag removeFromParentArray:YES];
	[self reloadArrayForSectionWithTag:toBeAnnouncedTag removeFromParentArray:YES];
	[self reloadArrayForSectionWithTag:releasedTag removeFromParentArray:YES];
	
	[_tableView reloadData];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return _games.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
	ReleasesSectionHeaderView *view;
	if (!view) view = [[ReleasesSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, tableView.sectionHeaderHeight)];
	
	if (_games[section] == _gamesReleasingThisMonth){
		[view addGestureRecognizer:_thisMonthGestureRecognizer];
		[view setTag:thisMonthTag];
		[view.titleLabel setText:@"This month"];
	}
	
	if (_games[section] == _gamesReleasingNextMonth){
		[view addGestureRecognizer:_nextMonthGestureRecognizer];
		[view setTag:nextMonthTag];
		[view.titleLabel setText:@"Next month"];
	}
	
	if (_games[section] == _gamesReleasingThisQuarter){
		[view addGestureRecognizer:_thisQuarterGestureRecognizer];
		[view setTag:thisQuarterTag];
		[view.titleLabel setText:@"This quarter"];
	}
	
	if (_games[section] == _gamesReleasingNextQuarter){
		[view addGestureRecognizer:_nextQuarterGestureRecognizer];
		[view setTag:nextQuarterTag];
		[view.titleLabel setText:@"Next quarter"];
	}
	
	if (_games[section] == _gamesReleasingThisYear){
		[view addGestureRecognizer:_thisYearGestureRecognizer];
		[view setTag:thisYearTag];
		[view.titleLabel setText:@"This year"];
	}
	
	if (_games[section] == _gamesReleasingNextYear){
		[view addGestureRecognizer:_nextYearGestureRecognizer];
		[view setTag:nextYearTag];
		[view.titleLabel setText:@"Next year"];
	}
	
	if (_games[section] == _gamesToBeAnnounced){
		[view addGestureRecognizer:_toBeAnnouncedGestureRecognizer];
		[view setTag:toBeAnnouncedTag];
		[view.titleLabel setText:@"To Be Announced"];
	}
	
	if (_games[section] == _gamesReleased){
		[view addGestureRecognizer:_releasedGestureRecognizer];
		[view setTag:releasedTag];
		[view.titleLabel setText:@"Released"];
	}
	
	return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	if (_games[section] == _gamesReleasingThisMonth) return _gamesReleasingThisMonth.count;
	if (_games[section] == _gamesReleasingNextMonth) return _gamesReleasingNextMonth.count;
	if (_games[section] == _gamesReleasingThisQuarter) return _gamesReleasingThisQuarter.count;
	if (_games[section] == _gamesReleasingNextQuarter) return _gamesReleasingNextQuarter.count;
	if (_games[section] == _gamesReleasingThisYear) return _gamesReleasingThisYear.count;
	if (_games[section] == _gamesReleasingNextYear) return _gamesReleasingNextYear.count;
	if (_games[section] == _gamesToBeAnnounced) return _gamesToBeAnnounced.count;
	if (_games[section] == _gamesReleased) return _gamesReleased.count;
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	ReleasesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"releasesCell"];
	
	Game *game = nil;
	if (_games[indexPath.section] == _gamesReleasingThisMonth) game = _gamesReleasingThisMonth[indexPath.row];
	else if (_games[indexPath.section] == _gamesReleasingNextMonth) game = _gamesReleasingNextMonth[indexPath.row];
	else if (_games[indexPath.section] == _gamesReleasingThisQuarter) game = _gamesReleasingThisQuarter[indexPath.row];
	else if (_games[indexPath.section] == _gamesReleasingNextQuarter) game = _gamesReleasingNextQuarter[indexPath.row];
	else if (_games[indexPath.section] == _gamesReleasingThisYear) game = _gamesReleasingThisYear[indexPath.row];
	else if (_games[indexPath.section] == _gamesReleasingNextYear) game = _gamesReleasingNextYear[indexPath.row];
	else if (_games[indexPath.section] == _gamesToBeAnnounced) game = _gamesToBeAnnounced[indexPath.row];
	else if (_games[indexPath.section] == _gamesReleased) game = _gamesReleased[indexPath.row];
	
	[cell.titleLabel setText:game.title];
//	[cell.titleLabel sizeToFit];
	[cell.dateLabel setText:game.releaseDateText];
	[cell.coverImageView setImage:[UIImage imageWithData:game.imageSmall]];
//	NSLog(@"%.2f x %.2f", cell.coverImageView.image.size.width, cell.coverImageView.image.size.height);
	
	[cell.platformLabel setText:game.selectedPlatform.nameShort];
	
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
	[Game deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", [_games[indexPath.section][indexPath.row] identifier]] inContext:context];
	[context saveToPersistentStoreAndWait];
	
	[_games[indexPath.section] removeObjectAtIndex:indexPath.row];
	[_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
	
	if ([_tableView numberOfRowsInSection:indexPath.section] == 0){
		[_games removeObjectAtIndex:indexPath.section];
		[_tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationLeft];
	}
}

#pragma mark -
#pragma mark GestureRecognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
	[_indexPaths removeAllObjects];
	
	BOOL didInsertRows = NO;
	NSMutableArray *gamesInSection;
	
	switch (gestureRecognizer.view.tag) {
		case thisMonthTag:
			if ([_games containsObject:_gamesReleasingThisMonth] && _gamesReleasingThisMonth.count == 0){
				[self reloadArrayForSectionWithTag:thisMonthTag removeFromParentArray:NO];
				for (Game *game in _gamesReleasingThisMonth)
					[_indexPaths addObject:[NSIndexPath indexPathForRow:[_gamesReleasingThisMonth indexOfObject:game] inSection:[_games indexOfObject:_gamesReleasingThisMonth]]];
				[_tableView insertRowsAtIndexPaths:_indexPaths withRowAnimation:UITableViewRowAnimationTop];
				didInsertRows = YES;
			}
			gamesInSection = _gamesReleasingThisMonth;
			break;
		case nextMonthTag:
			if ([_games containsObject:_gamesReleasingNextMonth] && _gamesReleasingNextMonth.count == 0){
				[self reloadArrayForSectionWithTag:nextMonthTag removeFromParentArray:NO];
				for (Game *game in _gamesReleasingNextMonth)
					[_indexPaths addObject:[NSIndexPath indexPathForRow:[_gamesReleasingNextMonth indexOfObject:game] inSection:[_games indexOfObject:_gamesReleasingNextMonth]]];
				[_tableView insertRowsAtIndexPaths:_indexPaths withRowAnimation:UITableViewRowAnimationTop];
				didInsertRows = YES;
			}
			gamesInSection = _gamesReleasingNextMonth;
			break;
		case thisQuarterTag:
			if ([_games containsObject:_gamesReleasingThisQuarter] && _gamesReleasingThisQuarter.count == 0){
				[self reloadArrayForSectionWithTag:thisQuarterTag removeFromParentArray:NO];
				for (Game *game in _gamesReleasingThisQuarter)
					[_indexPaths addObject:[NSIndexPath indexPathForRow:[_gamesReleasingThisQuarter indexOfObject:game] inSection:[_games indexOfObject:_gamesReleasingThisQuarter]]];
				[_tableView insertRowsAtIndexPaths:_indexPaths withRowAnimation:UITableViewRowAnimationTop];
				didInsertRows = YES;
			}
			gamesInSection = _gamesReleasingThisQuarter;
			break;
		case nextQuarterTag:
			if ([_games containsObject:_gamesReleasingNextQuarter] && _gamesReleasingNextQuarter.count == 0){
				[self reloadArrayForSectionWithTag:nextQuarterTag removeFromParentArray:NO];
				for (Game *game in _gamesReleasingNextQuarter)
					[_indexPaths addObject:[NSIndexPath indexPathForRow:[_gamesReleasingNextQuarter indexOfObject:game] inSection:[_games indexOfObject:_gamesReleasingNextQuarter]]];
				[_tableView insertRowsAtIndexPaths:_indexPaths withRowAnimation:UITableViewRowAnimationTop];
				didInsertRows = YES;
			}
			gamesInSection = _gamesReleasingNextQuarter;
			break;
		case thisYearTag:
			if ([_games containsObject:_gamesReleasingThisYear] && _gamesReleasingThisYear.count == 0){
				[self reloadArrayForSectionWithTag:thisYearTag removeFromParentArray:NO];
				for (Game *game in _gamesReleasingThisYear)
					[_indexPaths addObject:[NSIndexPath indexPathForRow:[_gamesReleasingThisYear indexOfObject:game] inSection:[_games indexOfObject:_gamesReleasingThisYear]]];
				[_tableView insertRowsAtIndexPaths:_indexPaths withRowAnimation:UITableViewRowAnimationTop];
				didInsertRows = YES;
			}
			gamesInSection = _gamesReleasingThisYear;
			break;
		case nextYearTag:
			if ([_games containsObject:_gamesReleasingNextYear] && _gamesReleasingNextYear.count == 0){
				[self reloadArrayForSectionWithTag:nextYearTag removeFromParentArray:NO];
				for (Game *game in _gamesReleasingNextYear)
					[_indexPaths addObject:[NSIndexPath indexPathForRow:[_gamesReleasingNextYear indexOfObject:game] inSection:[_games indexOfObject:_gamesReleasingNextYear]]];
				[_tableView insertRowsAtIndexPaths:_indexPaths withRowAnimation:UITableViewRowAnimationTop];
				didInsertRows = YES;
			}
			gamesInSection = _gamesReleasingNextYear;
			break;
		case toBeAnnouncedTag:
			if ([_games containsObject:_gamesToBeAnnounced] && _gamesToBeAnnounced.count == 0){
				[self reloadArrayForSectionWithTag:toBeAnnouncedTag removeFromParentArray:NO];
				for (Game *game in _gamesToBeAnnounced)
					[_indexPaths addObject:[NSIndexPath indexPathForRow:[_gamesToBeAnnounced indexOfObject:game] inSection:[_games indexOfObject:_gamesToBeAnnounced]]];
				[_tableView insertRowsAtIndexPaths:_indexPaths withRowAnimation:UITableViewRowAnimationTop];
				didInsertRows = YES;
			}
			gamesInSection = _gamesToBeAnnounced;
			break;
		case releasedTag:
			if ([_games containsObject:_gamesReleased] && _gamesReleased.count == 0){
				[self reloadArrayForSectionWithTag:releasedTag removeFromParentArray:NO];
				for (Game *game in _gamesReleased)
					[_indexPaths addObject:[NSIndexPath indexPathForRow:[_gamesReleased indexOfObject:game] inSection:[_games indexOfObject:_gamesReleased]]];
				[_tableView insertRowsAtIndexPaths:_indexPaths withRowAnimation:UITableViewRowAnimationTop];
				didInsertRows = YES;
			}
			gamesInSection = _gamesReleased;
			break;
		default:
			break;
	}
	
	if (!didInsertRows){
		for (Game *game in gamesInSection)
			[_indexPaths addObject:[NSIndexPath indexPathForRow:[gamesInSection indexOfObject:game] inSection:[_games indexOfObject:gamesInSection]]];
		for (NSIndexPath *indexPath in [_indexPaths reverseObjectEnumerator])
			[_games[indexPath.section] removeObjectAtIndex:indexPath.row];
		[_tableView deleteRowsAtIndexPaths:_indexPaths withRowAnimation:UITableViewRowAnimationTop];
	}
	
	return YES;
}

#pragma mark -
#pragma mark Custom

- (void)setTimePeriodForGamesInDatabase{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSDateComponents *currentComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	NSDateComponents *nextComponents = [calendar components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	
	[currentComponents setQuarter:[self quarterForMonth:currentComponents.month]];
	
	nextComponents.month++;
	[nextComponents setQuarter:[self quarterForMonth:nextComponents.month]];
	nextComponents.quarter++;
	nextComponents.year++;
	
	NSMutableArray *allGames = [[NSMutableArray alloc] init];
	allGames = [Game findAllWithPredicate:[NSPredicate predicateWithFormat:@"track == %@", @(YES)]].mutableCopy;
	
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	for (Game *game in allGames){
		if ([game.releaseDate compare:[calendar dateFromComponents:currentComponents]] <= NSOrderedSame)
			[game setPeriod:@(7)];
		else if ([game.releaseMonth isEqualToNumber:@(currentComponents.month)])
			[game setPeriod:@(1)];
		else if ([game.releaseMonth isEqualToNumber:@(nextComponents.month)])
			[game setPeriod:@(2)];
		else if ([game.releaseQuarter isEqualToNumber:@(currentComponents.quarter)])
			[game setPeriod:@(3)];
		else if ([game.releaseQuarter isEqualToNumber:@(nextComponents.quarter)])
			[game setPeriod:@(4)];
		else if ([game.releaseYear isEqualToNumber:@(currentComponents.year)])
			[game setPeriod:@(5)];
		else if ([game.releaseYear isEqualToNumber:@(nextComponents.year)])
			[game setPeriod:@(6)];
		else if ([game.releaseYear isEqualToNumber:@(2050)])
			[game setPeriod:@(8)];
	}
	
	[context saveToPersistentStoreAndWait];
}

- (void)reloadArrayForSectionWithTag:(NSInteger)tag removeFromParentArray:(BOOL)shouldRemoveFromParent{
	NSInteger index = 0;
	NSPredicate *predicate;
	
	switch (tag) {
		case thisMonthTag:
			if (!shouldRemoveFromParent) index = [_games indexOfObjectIdenticalTo:_gamesReleasingThisMonth];
			[_games removeObjectIdenticalTo:_gamesReleasingThisMonth];
			predicate = [NSPredicate predicateWithFormat:@"track == %@ && period == %@", @(YES), @(1)];
			_gamesReleasingThisMonth = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:predicate].mutableCopy;
			if (!shouldRemoveFromParent) [_games insertObject:_gamesReleasingThisMonth atIndex:index];
			else if (_gamesReleasingThisMonth.count > 0) [_games addObject:_gamesReleasingThisMonth];
			break;
		case nextMonthTag:
			if (!shouldRemoveFromParent) index = [_games indexOfObjectIdenticalTo:_gamesReleasingNextMonth];
			[_games removeObjectIdenticalTo:_gamesReleasingNextMonth];
			predicate = [NSPredicate predicateWithFormat:@"track == %@ && period == %@", @(YES), @(2)];
			_gamesReleasingNextMonth = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:predicate].mutableCopy;
			if (!shouldRemoveFromParent) [_games insertObject:_gamesReleasingNextMonth atIndex:index];
			else if (_gamesReleasingNextMonth.count > 0) [_games addObject:_gamesReleasingNextMonth];
			break;
		case thisQuarterTag:
			if (!shouldRemoveFromParent) index = [_games indexOfObjectIdenticalTo:_gamesReleasingThisQuarter];
			[_games removeObjectIdenticalTo:_gamesReleasingThisQuarter];
			predicate = [NSPredicate predicateWithFormat:@"track == %@ && period == %@", @(YES), @(3)];
			_gamesReleasingThisQuarter = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:predicate].mutableCopy;
			if (!shouldRemoveFromParent) [_games insertObject:_gamesReleasingThisQuarter atIndex:index];
			else if (_gamesReleasingThisQuarter.count > 0) [_games addObject:_gamesReleasingThisQuarter];
			break;
		case nextQuarterTag:
			if (!shouldRemoveFromParent) index = [_games indexOfObjectIdenticalTo:_gamesReleasingNextQuarter];
			[_games removeObjectIdenticalTo:_gamesReleasingNextQuarter];
			predicate = [NSPredicate predicateWithFormat:@"track == %@ && period == %@", @(YES), @(4)];
			_gamesReleasingNextQuarter = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:predicate].mutableCopy;
			if (!shouldRemoveFromParent) [_games insertObject:_gamesReleasingNextQuarter atIndex:index];
			else if (_gamesReleasingNextQuarter.count > 0) [_games addObject:_gamesReleasingNextQuarter];
			break;
		case thisYearTag:
			if (!shouldRemoveFromParent) index = [_games indexOfObjectIdenticalTo:_gamesReleasingThisYear];
			[_games removeObjectIdenticalTo:_gamesReleasingThisYear];
			predicate = [NSPredicate predicateWithFormat:@"track == %@ && period == %@", @(YES), @(5)];
			_gamesReleasingThisYear = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:predicate].mutableCopy;
			if (!shouldRemoveFromParent) [_games insertObject:_gamesReleasingThisYear atIndex:index];
			else if (_gamesReleasingThisYear.count > 0) [_games addObject:_gamesReleasingThisYear];
			break;
		case nextYearTag:
			if (!shouldRemoveFromParent) index = [_games indexOfObjectIdenticalTo:_gamesReleasingNextYear];
			[_games removeObjectIdenticalTo:_gamesReleasingNextYear];
			predicate = [NSPredicate predicateWithFormat:@"track == %@ && period == %@", @(YES), @(6)];
			_gamesReleasingNextYear = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:predicate].mutableCopy;
			if (!shouldRemoveFromParent) [_games insertObject:_gamesReleasingNextYear atIndex:index];
			else if (_gamesReleasingNextYear.count > 0) [_games addObject:_gamesReleasingNextYear];
			break;
		case toBeAnnouncedTag:
			if (!shouldRemoveFromParent) index = [_games indexOfObjectIdenticalTo:_gamesToBeAnnounced];
			[_games removeObjectIdenticalTo:_gamesToBeAnnounced];
			predicate = [NSPredicate predicateWithFormat:@"track == %@ && period == %@", @(YES), @(8)];
			_gamesToBeAnnounced = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:predicate].mutableCopy;
			if (!shouldRemoveFromParent) [_games insertObject:_gamesToBeAnnounced atIndex:index];
			else if (_gamesToBeAnnounced.count > 0) [_games addObject:_gamesToBeAnnounced];
			break;
		case releasedTag:
			if (!shouldRemoveFromParent) index = [_games indexOfObjectIdenticalTo:_gamesReleased];
			[_games removeObjectIdenticalTo:_gamesReleased];
			predicate = [NSPredicate predicateWithFormat:@"track == %@ && period == %@", @(YES), @(7)];
			_gamesReleased = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:predicate].mutableCopy;
			if (!shouldRemoveFromParent) [_games insertObject:_gamesReleased atIndex:index];
			else if (_gamesReleased.count > 0) [_games addObject:_gamesReleased];
			break;
		default:
			break;
	}
}

- (NSInteger)quarterForMonth:(NSInteger)month{
	switch (month) {
		case 1: return 1;
		case 2: return 1;
		case 3: return 1;
		case 4: return 2;
		case 5: return 2;
		case 6: return 2;
		case 7: return 3;
		case 8: return 3;
		case 9: return 3;
		case 10: return 4;
		case 11: return 4;
		case 12: return 4;
		default:
			return 0;
	}
}

#pragma mark -
#pragma mark Actions

- (IBAction)addBarButtonPressAction:(UIBarButtonItem *)sender{
	[self performSegueWithIdentifier:@"SearchSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		GameViewController *destination = [segue destinationViewController];
		[destination setGame:_games[_tableView.indexPathForSelectedRow.section][_tableView.indexPathForSelectedRow.row]];
	}
}

@end
