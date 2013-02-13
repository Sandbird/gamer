//
//  GamesViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "GamesViewController.h"
#import "GamesCell.h"
#import "Game.h"
#import "Platform.h"

@interface GamesViewController ()

@end

@implementation GamesViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	_games = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated{
	[_games removeAllObjects];
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSDateComponents *components = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	
	_games = [Game findAllSortedBy:@"title" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"releaseDate <= %@ && track == %@", [calendar dateFromComponents:components], @(NO)]].mutableCopy;
	
	NSLog(@"%@", [_games[0] title]);
	
	[_tableView reloadData];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return _games.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	GamesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GamesCell"];
	
	Game *game = _games[indexPath.row];
	[cell.titleLabel setText:game.title];
	[cell.coverImageView setImage:[UIImage imageWithData:game.imageSmall]];
	
	[cell.platformLabel setText:game.selectedPlatform.name];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
}

@end
