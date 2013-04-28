//
//  LibraryTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 4/23/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "LibraryTableViewController.h"
#import "LibraryCell.h"
#import "Game.h"
#import "Platform.h"
#import "GameTableViewController.h"
#import "SearchTableViewController.h"

@interface LibraryTableViewController ()

@end

@implementation LibraryTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
	_gamesFetch = [self libraryFetchedResultsController];
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_gamesFetch.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    LibraryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	Game *game = [_gamesFetch objectAtIndexPath:indexPath];
	[cell.titleLabel setText:game.title];
	[cell.platformLabel setText:game.selectedPlatform.nameShort];
	[cell.coverImageView setImage:[UIImage imageWithData:game.imageSmall]];
	
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
	Game *game = [_gamesFetch objectAtIndexPath:indexPath];
//	[Game deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", game.identifier] inContext:context];
	[game setOwned:@(NO)];
	[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		_gamesFetch = [self libraryFetchedResultsController];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
	}];
}

#pragma mark - Custom

- (NSFetchedResultsController *)libraryFetchedResultsController{
	return [Game fetchAllGroupedBy:nil withPredicate:[NSPredicate predicateWithFormat:@"releasePeriod.identifier == %@ AND owned == %@", @(1), @(YES)] sortedBy:@"title" ascending:YES];
}

#pragma mark - Actions

- (IBAction)addBarButtonPressAction:(UIBarButtonItem *)sender{
	[self performSegueWithIdentifier:@"SearchSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[_gamesFetch objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
	}
	if ([segue.identifier isEqualToString:@"SearchSegue"]){
		SearchTableViewController *destination = [segue destinationViewController];
		[destination setOrigin:2];
	}
}

@end
