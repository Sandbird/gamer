//
//  SettingsTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
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
#import "ReleaseDate.h"

@interface SettingsTableViewController () <FetchedTableViewDelegate>

@end

@implementation SettingsTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIExtendedEdgeAll];
	
	[self.tableView setBackgroundColor:[UIColor colorWithRed:.098039216 green:.098039216 blue:.098039216 alpha:1]];
	[self.tableView setSeparatorColor:[UIColor darkGrayColor]];
	
	self.fetchedResultsController = [self fetch];
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
		case 0: return @"Select your platforms";
		default: return @"";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case 0: return [self.fetchedResultsController.sections[section] numberOfObjects];
//		case 1: case 2: return 1;
		case 1: return 1;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell;
	
	switch (indexPath.section) {
		case 0:{
			cell = [tableView dequeueReusableCellWithIdentifier:@"CheckmarkCell" forIndexPath:indexPath];
			[self configureCell:cell atIndexPath:indexPath];
			break;
		}
//		case 1:
//			cell = [tableView dequeueReusableCellWithIdentifier:@"NavigationCell" forIndexPath:indexPath];
//			[cell.textLabel setText:@"Notifications"];
//			break;
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell" forIndexPath:indexPath];
			[cell.textLabel setText:@"Delete all data"];
			break;
		default:
			break;
	}
    
	[cell setBackgroundColor:[UIColor colorWithRed:.125490196 green:.125490196 blue:.125490196 alpha:1]];
	[cell.textLabel setTextColor:[UIColor lightGrayColor]];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	switch (indexPath.section) {
		case 0:{
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			[cell setAccessoryType:(cell.accessoryType == UITableViewCellAccessoryCheckmark) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark];
			
			NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
			Platform *platform = [self.fetchedResultsController objectAtIndexPath:indexPath];
			[platform setFavorite:(cell.accessoryType == UITableViewCellAccessoryCheckmark) ? @(YES) : @(NO)];
			[context saveToPersistentStoreAndWait];
			break;
		}
//		case 1:
//			[self performSegueWithIdentifier:@"NotificationsSegue" sender:nil];
//			break;
		case 1:{
			NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
			[Game truncateAll];
			[Genre truncateAll];
			[Platform truncateAll];
			[Developer truncateAll];
			[Publisher truncateAll];
			[Franchise truncateAll];
			[Theme truncateAll];
			[ReleasePeriod truncateAll];
			[ReleaseDate truncateAll];
			[context saveToPersistentStoreAndWait];
			break;
		}
		default:
			break;
	}
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	Platform *platform = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[cell.textLabel setText:platform.name];
	[cell setAccessoryType:([platform.favorite isEqualToNumber:@(YES)]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
}

#pragma mark - FetchedTableView

- (NSFetchedResultsController *)fetch{
	if (!self.fetchedResultsController)
		self.fetchedResultsController = [Platform fetchAllSortedBy:@"name" ascending:YES withPredicate:nil groupBy:nil delegate:self];
	return self.fetchedResultsController;
}

@end
