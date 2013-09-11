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

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	self.fetchedResultsController = [self fetch];
}

- (void)viewDidAppear:(BOOL)animated{
//	[[SessionManager tracker] set:kGAIScreenName value:@"Settings"];
//	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
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
			[cell setSeparatorInset:UIEdgeInsetsMake(0, 20, 0, 0)];
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	if (indexPath.section == 1){
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
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
		[Gamer truncateAll];
		[_context saveToPersistentStoreAndWait];
	}
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	PlatformCell *customCell = (PlatformCell *)cell;
	
	Platform *platform = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[customCell.titleLabel setText:platform.name];
	[customCell.abbreviationLabel setText:platform.abbreviation];
	[customCell.abbreviationLabel setBackgroundColor:platform.color];
	[customCell.switchControl setOn:([[SessionManager gamer].platforms containsObject:platform]) ? YES : NO];
	[customCell.switchControl setTag:indexPath.row];
}

#pragma mark - FetchedTableView

- (NSFetchedResultsController *)fetch{
	if (!self.fetchedResultsController)
		self.fetchedResultsController = [Platform fetchAllSortedBy:@"name" ascending:YES withPredicate:nil groupBy:nil delegate:self];
	return self.fetchedResultsController;
}

#pragma mark - Actions

- (IBAction)switchAction:(UISwitch *)sender{
	Platform *platform = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
	if (sender.isOn)
		[[SessionManager gamer] addPlatformsObject:platform];
	else
		[[SessionManager gamer] removePlatformsObject:platform];
	
	[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PlatformChange" object:nil];
	}];
}

@end
