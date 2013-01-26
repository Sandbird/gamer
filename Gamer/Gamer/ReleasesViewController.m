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

@interface ReleasesViewController ()

@end

@implementation ReleasesViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	_games = [[NSMutableArray alloc] init];
	
	_dateFormatter = [[NSDateFormatter alloc] init];
	[_dateFormatter setDateFormat:@"dd/MM/yyyy"];
	
	NSManagedObjectContext *context0 = [NSManagedObjectContext contextForCurrentThread];
	[Game truncateAll];
	[Genre truncateAll];
	[Platform truncateAll];
	[context0 saveNestedContexts];
	
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	
	Genre *shooter = [[Genre alloc] initWithEntity:[NSEntityDescription entityForName:@"Genre" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[shooter setName:@"Shooter"];
	
	Platform *xbox360 = [[Platform alloc] initWithEntity:[NSEntityDescription entityForName:@"Platform" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[xbox360 setName:@"Xbox 360"];
	
	Platform *playstation3 = [[Platform alloc] initWithEntity:[NSEntityDescription entityForName:@"Platform" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[playstation3 setName:@"Playstation 3"];
	
	_game0 = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[_game0 setName:@"Gears of War: Judgment"];
	[_game0 setReleaseDate:[_dateFormatter dateFromString:@"19/03/2013"]];
	[_game0 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Shooter"]];
	[_game0 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"Xbox 360"]];
	[_games addObject:_game0];
	
	[context saveNestedContexts];
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
	ReleasesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"releasesCell"];
	
	Game *game = _games[indexPath.row];
	
	[cell.titleLabel setText:game.name];
	[cell.dateLabel setText:[_dateFormatter stringFromDate:game.releaseDate]];
	
	[cell.titleLabel setText:[[game.genres allObjects][0] name]];
	[cell.dateLabel setText:[[game.platforms allObjects][0] name]];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
}

@end
