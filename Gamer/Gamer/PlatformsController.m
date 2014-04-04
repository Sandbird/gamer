//
//  PlatformsController.m
//  Gamer
//
//  Created by Caio Mello on 09/03/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "PlatformsController.h"
#import "Platform.h"
#import "SettingsPlatformCell.h"

typedef NS_ENUM(NSInteger, Section){
	SectionModern,
	SectionLegacy
};

@interface PlatformsController () <UISplitViewControllerDelegate>

@property (nonatomic, strong) UIPopoverController *menuPopoverController;

@property (nonatomic, strong) NSMutableArray *modernPlatforms;
@property (nonatomic, strong) NSMutableArray *legacyPlatforms;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation PlatformsController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	_modernPlatforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"group = %@", @(PlatformGroupModern)] inContext:_context].mutableCopy;
	_legacyPlatforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"group = %@", @(PlatformGroupLegacy)] inContext:_context].mutableCopy;
	
	[self.tableView setEditing:YES animated:NO];
	
	[self.splitViewController setDelegate:self];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - SplitViewController

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc{
	_menuPopoverController = pc;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem{
	_menuPopoverController = nil;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section) {
		case PlatformGroupModern: return @"Modern";
		case PlatformGroupLegacy: return @"Legacy";
		default: return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case PlatformGroupModern: return _modernPlatforms.count;
		case PlatformGroupLegacy: return _legacyPlatforms.count;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Platform *platform;
	
	switch (indexPath.section) {
		case PlatformGroupModern: platform = _modernPlatforms[indexPath.row]; break;
		case PlatformGroupLegacy: platform = _legacyPlatforms[indexPath.row]; break;
		default: break;
	}
	
	SettingsPlatformCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:platform.name];
	[cell.abbreviationLabel setText:platform.abbreviation];
	[cell.abbreviationLabel setBackgroundColor:platform.color];
	[cell.switchControl setOn:([[Session gamer].platforms containsObject:platform]) ? YES : NO];
	[cell.switchControl setTag:indexPath.row];
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
	return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
	return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath{
	// Prevent moving to other sections
	if (sourceIndexPath.section != proposedDestinationIndexPath.section){
		NSInteger row = 0;
		if (sourceIndexPath.section < proposedDestinationIndexPath.section) row = [tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
		return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];
	}
	return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
	// Set platform indexes accordingly
	
	if (sourceIndexPath.section == SectionModern){
		Platform *platform = _modernPlatforms[sourceIndexPath.row];
		
		[_modernPlatforms removeObject:platform];
		[_modernPlatforms insertObject:platform atIndex:destinationIndexPath.row];
		
		for (Platform *platform in _modernPlatforms){
			NSInteger index = [_modernPlatforms indexOfObject:platform];
			
			[platform setIndex:@(index)];
			
			SettingsPlatformCell *cell = (SettingsPlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
			[cell.switchControl setTag:index];
		}
	}
	else{
		Platform *platform = _legacyPlatforms[sourceIndexPath.row];
		
		[_legacyPlatforms removeObject:platform];
		[_legacyPlatforms insertObject:platform atIndex:destinationIndexPath.row];
		
		for (Platform *platform in _legacyPlatforms){
			NSInteger index = [_legacyPlatforms indexOfObject:platform];
			
			[platform setIndex:@(index)];
			
			SettingsPlatformCell *cell = (SettingsPlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
			[cell.switchControl setTag:index];
		}
	}
	
	[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
	}];
}

#pragma mark - Actions

- (IBAction)switchAction:(UISwitch *)sender{
	UITableViewCell *cell = (UITableViewCell *)sender.superview.superview.superview;
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	Platform *platform;
	
	switch (indexPath.section) {
		case PlatformGroupModern: platform = _modernPlatforms[indexPath.row]; break;
		case PlatformGroupLegacy: platform = _legacyPlatforms[indexPath.row]; break;
		default: break;
	}
	
	sender.isOn ? [[Session gamer] addPlatformsObject:platform] : [[Session gamer] removePlatformsObject:platform];
	
	[_context MR_saveToPersistentStoreAndWait];
}

@end
