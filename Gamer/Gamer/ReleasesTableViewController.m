//
//  ReleasesTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 4/23/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "ReleasesTableViewController.h"
#import "ReleasesCell.h"
#import "Game.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "ReleasePeriod.h"
#import "GameTableViewController.h"
#import "SearchTableViewController.h"
#import "ReleasesSectionHeaderView.h"

@interface ReleasesTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *releasesFetch;

@end

@implementation ReleasesTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewDidLayoutSubviews{
//	ReleasesCell *cell = (ReleasesCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
//	[Utilities addDropShadowToView:cell.coverImageView color:[UIColor redColor] opacity:0.6 radius:10 offset:CGSizeZero];
}

- (void)viewWillAppear:(BOOL)animated{
	
}

- (void)viewDidAppear:(BOOL)animated{
	_releasesFetch = [self releasesFetchedResultsController];
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _releasesFetch.sections.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
	ReleasesSectionHeaderView *headerView = [[ReleasesSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, tableView.sectionHeaderHeight)];
	[headerView.titleLabel setText:[[ReleasePeriod findFirstByAttribute:@"identifier" withValue:[_releasesFetch.sections[section] name]] name]];
	
	return headerView;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//	return [[ReleasePeriod findFirstByAttribute:@"identifier" withValue:[_releasesFetch.sections[section] name]] name];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_releasesFetch.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ReleasesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	Game *game = [_releasesFetch objectAtIndexPath:indexPath];
	[cell.titleLabel setText:game.title];
	[cell.dateLabel setText:([game.releasePeriod.identifier isEqualToNumber:@(8)]) ? @"" : game.releaseDateText];
	[cell.coverImageView setImage:[UIImage imageWithData:game.coverImageSmall]];
	[cell.platformLabel setText:game.selectedPlatform.nameShort];
	[cell.platformLabel setBackgroundColor:game.selectedPlatform.color];
//	[Utilities addDropShadowToView:cell.coverImageView color:[UIColor redColor] opacity:0.6 radius:10 offset:CGSizeZero];
	
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
	Game *game = [_releasesFetch objectAtIndexPath:indexPath];
	[game setWanted:@(NO)];
	[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		_releasesFetch = [self releasesFetchedResultsController];
		
		if ([tableView numberOfRowsInSection:indexPath.section] == 1)
			[tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationLeft];
		else
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
	}];
}

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)releasesFetchedResultsController{
	return [Game fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:[NSPredicate predicateWithFormat:@"wanted = %@ && selectedPlatform.favorite = %@", @(YES), @(YES)] sortedBy:@"releaseDate" ascending:YES delegate:self];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
	NSLog(@"index: %@", indexPath);
	NSLog(@"new index: %@", newIndexPath);
}

#pragma mark - Actions

- (IBAction)addBarButtonPressAction:(UIBarButtonItem *)sender{
	[self performSegueWithIdentifier:@"SearchSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[_releasesFetch objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
	}
	if ([segue.identifier isEqualToString:@"SearchSegue"]){
		SearchTableViewController *destination = [segue destinationViewController];
		[destination setOrigin:1];
	}
}

@end
