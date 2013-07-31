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
#import "Video.h"
#import "Image.h"
#import "CoverImage.h"
#import "SimilarGame.h"
#import "PlatformCell.h"

@interface SettingsTableViewController () <FetchedTableViewDelegate>

@end

@implementation SettingsTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	self.fetchedResultsController = [self fetch];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] sendView:@"Settings"];
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
		case 0: return @"Platforms";
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
		case 1: return 1;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case 0:{
			PlatformCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlatformCell" forIndexPath:indexPath];
			[cell setSeparatorInset:UIEdgeInsetsMake(0, 90, 0, 0)];
			[self configureCell:cell atIndexPath:indexPath];
			return cell;
		}
		case 1:{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell" forIndexPath:indexPath];
			[cell.textLabel setText:@"Delete all data"];
			return cell;
		}
		default:
			return nil;
	}
    
//	[cell setBackgroundColor:[UIColor colorWithRed:.125490196 green:.125490196 blue:.125490196 alpha:1]];
//	[cell.textLabel setTextColor:[UIColor lightGrayColor]];
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
			[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"PlatformChange" object:nil];
			}];
			break;
		}
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
			[Video truncateAll];
			[Image truncateAll];
			[CoverImage truncateAll];
			[SimilarGame truncateAll];
			[context saveToPersistentStoreAndWait];
			break;
		}
		default:
			break;
	}
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	PlatformCell *customCell = (PlatformCell *)cell;
	
	Platform *platform = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[customCell.titleLabel setText:platform.name];
	[customCell.abbreviationLabel setText:platform.abbreviation];
	[customCell.abbreviationLabel setBackgroundColor:platform.color];
	[customCell setAccessoryType:([platform.favorite isEqualToNumber:@(YES)]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
}

#pragma mark - FetchedTableView

- (NSFetchedResultsController *)fetch{
	if (!self.fetchedResultsController)
		self.fetchedResultsController = [Platform fetchAllSortedBy:@"name" ascending:YES withPredicate:nil groupBy:nil delegate:self];
	return self.fetchedResultsController;
}

@end
