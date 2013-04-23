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
#import "GameViewController.h"

@interface ReleasesTableViewController ()

@end

@implementation ReleasesTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
	_releasesFetch = [Game fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:[NSPredicate predicateWithFormat:@"releasePeriod.identifier != %@", @(1)] sortedBy:@"releaseDate" ascending:YES];
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _releasesFetch.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return [[ReleasePeriod findFirstByAttribute:@"identifier" withValue:[_releasesFetch.sections[section] name]] name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_releasesFetch.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ReleasesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReleasesCell" forIndexPath:indexPath];
	
	Game *game = [_releasesFetch objectAtIndexPath:indexPath];
	[cell.titleLabel setText:game.title];
	[cell.dateLabel setText:game.releaseDateText];
	[cell.coverImageView setImage:[UIImage imageWithData:game.imageSmall]];
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
	[Game deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", [_releasesFetch objectAtIndexPath:indexPath]] inContext:context];
	[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
	}];
}

#pragma mark - Actions

- (IBAction)addBarButtonPressAction:(UIBarButtonItem *)sender{
	[self performSegueWithIdentifier:@"SearchSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		GameViewController *destination = [segue destinationViewController];
		[destination setGame:[_releasesFetch objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
	}
}

@end
