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
#import <SDSegmentedControl/SDSegmentedControl.h>

@interface LibraryTableViewController ()

@property (nonatomic, strong) NSFetchedResultsController *gamesFetch;
@property (nonatomic, strong) NSPredicate *predicate;

@end

@implementation LibraryTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
	NSArray *favoritePlatforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"favorite == %@", @(YES)]];
	
	SDSegmentedControl *filterSegmentedControl = (SDSegmentedControl *)self.tableView.tableHeaderView;
	[filterSegmentedControl removeAllSegments];
	
	if (favoritePlatforms.count > 0){
		for (Platform *platform in favoritePlatforms)
			[filterSegmentedControl insertSegmentWithTitle:platform.nameShort atIndex:[favoritePlatforms indexOfObject:platform] animated:NO];
		[filterSegmentedControl setSelectedSegmentIndex:0];
	}
	else
		[filterSegmentedControl insertSegmentWithTitle:@"Select your platforms in Settings" atIndex:0 animated:NO];
	
	_gamesFetch = [self libraryFetchedResultsControllerWithPredicate:_predicate];
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
	[cell.coverImageView setImage:[UIImage imageWithData:game.coverImageSmall]];
	
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
		_gamesFetch = [self libraryFetchedResultsControllerWithPredicate:_predicate];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
	}];
}

#pragma mark - Custom

- (NSFetchedResultsController *)libraryFetchedResultsControllerWithPredicate:(NSPredicate *)predicate{
	return [Game fetchAllGroupedBy:nil withPredicate:(predicate) ? predicate : [NSPredicate predicateWithFormat:@"releasePeriod.identifier == %@ AND owned == %@", @(1), @(YES)] sortedBy:@"title" ascending:YES];
}

#pragma mark - Actions

- (IBAction)segmentedControlValueChanged:(SDSegmentedControl *)sender{
	NSArray *platforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"favorite == %@", @(YES)]];
	Platform *selectedPlatform = platforms[sender.selectedSegmentIndex];
	_gamesFetch = [self libraryFetchedResultsControllerWithPredicate:[NSPredicate predicateWithFormat:@"releasePeriod.identifier == %@ AND owned == %@ AND selectedPlatform == %@", @(1), @(YES), selectedPlatform]];
	[self.tableView reloadData];
}

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
