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
#import "GameViewController.h"

static NSInteger selectedRow;

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
	[context0 saveToPersistentStoreAndWait];
	
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	
	Genre *shooter = [[Genre alloc] initWithEntity:[NSEntityDescription entityForName:@"Genre" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[shooter setName:@"Shooter"];
	
	Genre *action = [[Genre alloc] initWithEntity:[NSEntityDescription entityForName:@"Genre" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[action setName:@"Action"];
	
	Genre *adventure = [[Genre alloc] initWithEntity:[NSEntityDescription entityForName:@"Genre" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[adventure setName:@"Adventure"];
	
	Platform *xbox360 = [[Platform alloc] initWithEntity:[NSEntityDescription entityForName:@"Platform" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[xbox360 setName:@"Xbox 360"];
	
	Platform *playstation3 = [[Platform alloc] initWithEntity:[NSEntityDescription entityForName:@"Platform" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[playstation3 setName:@"PlayStation 3"];
	
	Platform *wiiu = [[Platform alloc] initWithEntity:[NSEntityDescription entityForName:@"Platform" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[wiiu setName:@"Wii U"];
	
	Platform *pc = [[Platform alloc] initWithEntity:[NSEntityDescription entityForName:@"Platform" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[pc setName:@"PC"];
	
	_game0 = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[_game0 setTitle:@"Gears of War: Judgment"];
	[_game0 setReleaseDate:[_dateFormatter dateFromString:@"19/03/2013"]];
	[_game0 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Action"]];
	[_game0 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Shooter"]];
	[_game0 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"Xbox 360"]];
	[_games addObject:_game0];
	
	_game1 = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[_game1 setTitle:@"The Last of Us"];
	[_game1 setReleaseDate:[_dateFormatter dateFromString:@"07/05/2013"]];
	[_game1 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Action"]];
	[_game1 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Adventure"]];
	[_game1 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"PlayStation 3"]];
	[_games addObject:_game1];
	
	_game2 = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[_game2 setTitle:@"Bioshock: Infinite"];
	[_game2 setReleaseDate:[_dateFormatter dateFromString:@"26/03/2013"]];
	[_game2 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Adventure"]];
	[_game2 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Shooter"]];
	[_game2 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"Xbox 360"]];
	[_game2 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"PlayStation 3"]];
	[_game2 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"PC"]];
	[_games addObject:_game2];
	
	_game3 = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[_game3 setTitle:@"Assassin's Creed III"];
	[_game3 setReleaseDate:[_dateFormatter dateFromString:@"30/10/2012"]];
	[_game3 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Action"]];
	[_game3 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Adventure"]];
	[_game3 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"Xbox 360"]];
	[_game3 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"PlayStation 3"]];
	[_game3 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"Wii U"]];
	[_game3 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"PC"]];
	[_games addObject:_game3];
	
	_game4 = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[_game4 setTitle:@"Tomb Raider"];
	[_game4 setReleaseDate:[_dateFormatter dateFromString:@"05/03/2013"]];
	[_game4 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Action"]];
	[_game4 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Adventure"]];
	[_game4 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"Xbox 360"]];
	[_game4 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"PlayStation 3"]];
	[_games addObject:_game4];
	
	_game5 = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[_game5 setTitle:@"Watch Dogs"];
	[_game5 setReleaseDate:[_dateFormatter dateFromString:@"01/01/2014"]];
	[_game5 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Action"]];
	[_game5 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Shooter"]];
	[_game5 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"PC"]];
	[_games addObject:_game5];
	
	_game6 = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[_game6 setTitle:@"Splinter Cell: Blacklist"];
	[_game6 setReleaseDate:[_dateFormatter dateFromString:@"20/08/2013"]];
	[_game6 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Action"]];
	[_game2 addGenresObject:[Genre findFirstByAttribute:@"name" withValue:@"Shooter"]];
	[_game6 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"Xbox 360"]];
	[_game6 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"PlayStation 3"]];
	[_game6 addPlatformsObject:[Platform findFirstByAttribute:@"name" withValue:@"PC"]];
	[_games addObject:_game6];
	
	[context saveToPersistentStoreAndWait];
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
	
	[cell.titleLabel setText:game.title];
	[cell.dateLabel setText:[_dateFormatter stringFromDate:game.releaseDate]];
	
//	[cell.titleLabel setText:[[game.genres allObjects][0] name]];
//	[cell.dateLabel setText:[[game.platforms allObjects][0] name]];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	selectedRow = indexPath.row;
	
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
}

#pragma mark -
#pragma mark Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	GameViewController *destination = [segue destinationViewController];
	[destination setGame:_games[selectedRow]];
}

@end
