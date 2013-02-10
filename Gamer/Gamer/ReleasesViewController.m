//
//  ReleasesViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "ReleasesViewController.h"
#import "ReleasesCell.h"
#import "Game.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "GameViewController.h"

static NSInteger selectedRow;

@interface ReleasesViewController ()

@end

@implementation ReleasesViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated{
	[self setupDataSource];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark TableView

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
	return 22;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return _games.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	if (_games[section] == _gamesReleasingThisMonth) return @"This month";
	if (_games[section] == _gamesReleasingNextMonth) return @"Next month";
	if (_games[section] == _gamesReleasingThisQuarter) return @"This quarter";
	if (_games[section] == _gamesReleasingNextQuarter) return @"Next quarter";
	if (_games[section] == _gamesReleasingThisYear) return @"This year";
	if (_games[section] == _gamesReleasingNextYear) return @"Next year";
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	if (_games[section] == _gamesReleasingThisMonth) return _gamesReleasingThisMonth.count;
	if (_games[section] == _gamesReleasingNextMonth) return _gamesReleasingNextMonth.count;
	if (_games[section] == _gamesReleasingThisQuarter) return _gamesReleasingThisQuarter.count;
	if (_games[section] == _gamesReleasingNextQuarter) return _gamesReleasingNextQuarter.count;
	if (_games[section] == _gamesReleasingThisYear) return _gamesReleasingThisYear.count;
	if (_games[section] == _gamesReleasingNextYear) return _gamesReleasingNextYear.count;
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
	
//	if ([game.title rangeOfString:@":"].location == NSNotFound){
//		[cell.titleLabel setText:game.title];
//	}
//	else{
//		[cell.titleLabel setText:[[game.title componentsSeparatedByString:@": "][0] stringByAppendingString:@":"]];
//	}
	NSLog(@"%@", game.releaseQuarter);
	[cell.titleLabel setText:game.title];
//	[cell.titleLabel sizeToFit];
	[cell.dateLabel setText:game.releaseDateText];
	[cell.imageView setImage:[UIImage imageWithData:game.image scale:10]];
//	NSLog(@"%.2f x %.2f", cell.imageView.image.size.width, cell.imageView.image.size.height);
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	selectedRow = indexPath.row;
	
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	Game *game = [Game findFirstByAttribute:@"identifier" withValue:[_games[indexPath.row] identifier]];
	[game setTrack:@(NO)];
	[context saveToPersistentStoreAndWait];
	
	[_games removeObjectAtIndex:indexPath.row];
	[tableView reloadData];
}

#pragma mark -
#pragma mark Custom

- (void)setupDataSource{
	_games = [[NSMutableArray alloc] init];
	_gamesReleasingThisMonth = [[NSMutableArray alloc] init];
	_gamesReleasingNextMonth = [[NSMutableArray alloc] init];
	_gamesReleasingThisQuarter = [[NSMutableArray alloc] init];
	_gamesReleasingNextQuarter = [[NSMutableArray alloc] init];
	_gamesReleasingThisYear = [[NSMutableArray alloc] init];
	_gamesReleasingNextYear = [[NSMutableArray alloc] init];
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSDateComponents *currentComponents = [calendar components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	NSDateComponents *nextComponents = [calendar components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	nextComponents.month++;
	
	if (nextComponents.month <= 3) [nextComponents setQuarter:1];
	else if (nextComponents.month >= 4 && nextComponents.month <= 6) [nextComponents setQuarter:2];
	else if (nextComponents.month >= 7 && nextComponents.month <= 9) [nextComponents setQuarter:3];
	else if (nextComponents.month >= 10 && nextComponents.month <= 12) [nextComponents setQuarter:4];
	
	nextComponents.quarter++;
	
	nextComponents.year++;
	
	if (currentComponents.month <= 3) [currentComponents setQuarter:1];
	else if (currentComponents.month >= 4 && currentComponents.month <= 6) [currentComponents setQuarter:2];
	else if (currentComponents.month >= 7 && currentComponents.month <= 9) [currentComponents setQuarter:3];
	else if (currentComponents.month >= 10 && currentComponents.month <= 12) [currentComponents setQuarter:4];
	
	NSPredicate *thisMonthPredicate = [NSPredicate predicateWithFormat:@"releaseMonth == %@ && track == %@", @(currentComponents.month), @(YES)];
	_gamesReleasingThisMonth = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:thisMonthPredicate].mutableCopy;
	
	NSPredicate *nextMonthPredicate = [NSPredicate predicateWithFormat:@"releaseMonth == %@ && track == %@ && NOT (SELF IN %@)", @(nextComponents.month), @(YES), _gamesReleasingThisMonth];
	_gamesReleasingNextMonth = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:nextMonthPredicate].mutableCopy;
	
	NSPredicate *thisQuarterPredicate = [NSPredicate predicateWithFormat:@"releaseQuarter == %@ && track == %@ && NOT (SELF IN %@) && NOT (SELF IN %@)", @(currentComponents.quarter), @(YES), _gamesReleasingThisMonth, _gamesReleasingNextMonth];
	_gamesReleasingThisQuarter = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:thisQuarterPredicate].mutableCopy;
	
	NSPredicate *nextQuarterPredicate = [NSPredicate predicateWithFormat:@"releaseQuarter == %@ && track == %@ && NOT (SELF IN %@) && NOT (SELF IN %@) && NOT (SELF IN %@)", @(nextComponents.quarter), @(YES), _gamesReleasingThisMonth, _gamesReleasingNextMonth, _gamesReleasingThisQuarter];
	_gamesReleasingNextQuarter = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:nextQuarterPredicate].mutableCopy;
	
	NSPredicate *thisYearPredicate = [NSPredicate predicateWithFormat:@"releaseYear == %@ && track == %@ && NOT (SELF IN %@) && NOT (SELF IN %@) && NOT (SELF IN %@) && NOT (SELF IN %@)", @(currentComponents.year), @(YES), _gamesReleasingThisMonth, _gamesReleasingNextMonth, _gamesReleasingThisQuarter, _gamesReleasingNextQuarter];
	_gamesReleasingThisYear = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:thisYearPredicate].mutableCopy;
	
	NSPredicate *nextYearPredicate = [NSPredicate predicateWithFormat:@"releaseYear == %@ && track == %@ && NOT (SELF IN %@) && NOT (SELF IN %@) && NOT (SELF IN %@) && NOT (SELF IN %@) && NOT (SELF IN %@)", @(nextComponents.year), @(YES), _gamesReleasingThisMonth, _gamesReleasingNextMonth, _gamesReleasingThisQuarter, _gamesReleasingNextQuarter, _gamesReleasingThisYear];
	_gamesReleasingNextYear = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:nextYearPredicate].mutableCopy;
	
	if (_gamesReleasingThisMonth.count > 0) [_games addObject:_gamesReleasingThisMonth];
	if (_gamesReleasingNextMonth.count > 0) [_games addObject:_gamesReleasingNextMonth];
	if (_gamesReleasingThisQuarter.count > 0) [_games addObject:_gamesReleasingThisQuarter];
	if (_gamesReleasingNextQuarter.count > 0) [_games addObject:_gamesReleasingNextQuarter];
	if (_gamesReleasingThisYear.count > 0) [_games addObject:_gamesReleasingThisYear];
	if (_gamesReleasingNextYear.count > 0) [_games addObject:_gamesReleasingNextYear];
	
	[_tableView reloadData];
}

#pragma mark -
#pragma mark Actions

- (IBAction)addBarButtonPressAction:(UIBarButtonItem *)sender{
	[self performSegueWithIdentifier:@"SearchSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		GameViewController *destination = [segue destinationViewController];
		[destination setGame:_games[selectedRow]];
	}
}

@end
