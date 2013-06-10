//
//  SettingsTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 4/28/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "Game.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "ReleasePeriod.h"

@interface SettingsTableViewController ()

@property (nonatomic, strong) NSFetchedResultsController *platformsFetch;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
	_platformsFetch = [Platform fetchAllGroupedBy:nil withPredicate:nil sortedBy:@"name" ascending:YES];
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section) {
		case 0: return @"Plataforms";
		default: return @"";
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
	switch (section) {
		case 0: return @"Select the platforms of the games you want to see on search results.";
		default: return @"";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case 0: return [_platformsFetch.sections[section] numberOfObjects];
		case 1: case 2: return 1;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell;
	
	switch (indexPath.section) {
		case 0:{
			cell = [tableView dequeueReusableCellWithIdentifier:@"CheckmarkCell" forIndexPath:indexPath];
			Platform *platform = [_platformsFetch objectAtIndexPath:indexPath];
			[cell.textLabel setText:platform.name];
			[cell setAccessoryType:([platform.favorite isEqualToNumber:@(YES)]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
			break;
		}
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier:@"NavigationCell" forIndexPath:indexPath];
			[cell.textLabel setText:@"Notifications"];
			break;
		case 2:
			cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell" forIndexPath:indexPath];
			[cell.textLabel setText:@"Delete all data"];
			break;
		default:
			break;
	}
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	switch (indexPath.section) {
		case 0:{
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			[cell setAccessoryType:(cell.accessoryType == UITableViewCellAccessoryCheckmark) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark];
			
			NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
			Platform *platform = [_platformsFetch objectAtIndexPath:indexPath];
			[platform setFavorite:(cell.accessoryType == UITableViewCellAccessoryCheckmark) ? @(YES) : @(NO)];
			[context saveToPersistentStoreAndWait];
			break;
		}
		case 1:
			[self performSegueWithIdentifier:@"NotificationsSegue" sender:nil];
			break;
		case 2:{
			NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
			[Game truncateAll];
			[Genre truncateAll];
			[Platform truncateAll];
			[Developer truncateAll];
			[Publisher truncateAll];
			[Franchise truncateAll];
			[Theme truncateAll];
			[ReleasePeriod truncateAll];
			[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				_platformsFetch = [Platform fetchAllGroupedBy:nil withPredicate:nil sortedBy:@"name" ascending:YES];
				[self.tableView reloadData];
			}];
			break;
		}
		default:
			break;
	}
}

@end
