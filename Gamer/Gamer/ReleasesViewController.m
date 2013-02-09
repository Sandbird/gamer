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
	
	_games = [[NSMutableArray alloc] init];
	_games = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"track == %@", @(YES)]].mutableCopy;
	[_tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated{
	_games = [Game findAllSortedBy:@"releaseDate" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"track == %@", @(YES)]].mutableCopy;
	[_tableView reloadData];
	
//	[_games sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//		NSDate *obj1ReleaseDate = [(Game *)obj1 releaseDate];
//		NSDate *obj2ReleaseDate = [(Game *)obj2 releaseDate];
//		return [obj1ReleaseDate compare:obj2ReleaseDate];
//	}];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark TableView

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
//	
//}
//
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//	
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return _games.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	ReleasesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"releasesCell"];
	
	Game *game = _games[indexPath.row];
	
//	if ([game.title rangeOfString:@":"].location == NSNotFound){
//		[cell.titleLabel setText:game.title];
//	}
//	else{
//		[cell.titleLabel setText:[[game.title componentsSeparatedByString:@": "][0] stringByAppendingString:@":"]];
//	}
	
	[cell.titleLabel setText:game.title];
	[cell.titleLabel sizeToFit];
	[cell.dateLabel setText:game.releaseDateText];
//	if (cell.titleLabel.frame.size.height < 40)
//		[cell.dateLabel setFrame:CGRectMake(cell.dateLabel.frame.origin.x, cell.titleLabel.frame.origin.y + cell.titleLabel.frame.size.height, cell.dateLabel.frame.size.width, cell.dateLabel.frame.size.height)];
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
