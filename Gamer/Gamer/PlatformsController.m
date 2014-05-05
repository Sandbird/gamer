//
//  PlatformsController.m
//  Gamer
//
//  Created by Caio Mello on 09/03/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "PlatformsController.h"
#import "Platform.h"
#import "PlatformCell.h"

typedef NS_ENUM(NSInteger, Section){
	Section8thGen,
	Section7thGen,
	Section6thGen,
	Section5thGen
};

@interface PlatformsController () <UISplitViewControllerDelegate>

@property (nonatomic, strong) UIPopoverController *menuPopoverController;

@property (nonatomic, strong) NSMutableArray *eighthGenPlatforms;
@property (nonatomic, strong) NSMutableArray *seventhGenPlatforms;
@property (nonatomic, strong) NSMutableArray *sixthGenPlatforms;
@property (nonatomic, strong) NSMutableArray *fifthGenPlatforms;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation PlatformsController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	if ([Tools deviceIsiPad])
		[self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:.125490196 green:.125490196 blue:.125490196 alpha:1]];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	_eighthGenPlatforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"group = %@", @(0)] inContext:_context].mutableCopy;
	_seventhGenPlatforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"group = %@", @(1)] inContext:_context].mutableCopy;
	_sixthGenPlatforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"group = %@", @(2)] inContext:_context].mutableCopy;
	_fifthGenPlatforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"group = %@", @(3)] inContext:_context].mutableCopy;
	
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
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section) {
		case Section8thGen: return @"8th Generation";
		case Section7thGen: return @"7th Generation";
		case Section6thGen: return @"6th Generation";
		case Section5thGen: return @"5th Generation";
		default: return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case Section8thGen: return _eighthGenPlatforms.count;
		case Section7thGen: return _seventhGenPlatforms.count;
		case Section6thGen: return _sixthGenPlatforms.count;
		case Section5thGen: return _fifthGenPlatforms.count;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Platform *platform;
	
	switch (indexPath.section) {
		case Section8thGen: platform = _eighthGenPlatforms[indexPath.row]; break;
		case Section7thGen: platform = _seventhGenPlatforms[indexPath.row]; break;
		case Section6thGen: platform = _sixthGenPlatforms[indexPath.row]; break;
		case Section5thGen: platform = _fifthGenPlatforms[indexPath.row]; break;
		default: break;
	}
	
	PlatformCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:platform.name];
	[cell.abbreviationLabel setText:platform.abbreviation];
	[cell.abbreviationLabel setBackgroundColor:platform.color];
	[cell.switchControl setOn:([[Session gamer].platforms containsObject:platform]) ? YES : NO];
	[cell.switchControl setTag:indexPath.row];
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
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
	switch (sourceIndexPath.section) {
		case Section8thGen:{
			Platform *platform = _eighthGenPlatforms[sourceIndexPath.row];
			
			[_eighthGenPlatforms removeObject:platform];
			[_eighthGenPlatforms insertObject:platform atIndex:destinationIndexPath.row];
			
			for (Platform *platform in _eighthGenPlatforms){
				NSInteger index = [_eighthGenPlatforms indexOfObject:platform];
				
				[platform setIndex:@(index)];
				
				PlatformCell *cell = (PlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
				[cell.switchControl setTag:index];
			}
			break;
		}
		case Section7thGen:{
			Platform *platform = _seventhGenPlatforms[sourceIndexPath.row];
			
			[_seventhGenPlatforms removeObject:platform];
			[_seventhGenPlatforms insertObject:platform atIndex:destinationIndexPath.row];
			
			for (Platform *platform in _seventhGenPlatforms){
				NSInteger index = [_seventhGenPlatforms indexOfObject:platform];
				
				[platform setIndex:@(index)];
				
				PlatformCell *cell = (PlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
				[cell.switchControl setTag:index];
			}
			break;
		}
		case Section6thGen:{
			Platform *platform = _sixthGenPlatforms[sourceIndexPath.row];
			
			[_sixthGenPlatforms removeObject:platform];
			[_sixthGenPlatforms insertObject:platform atIndex:destinationIndexPath.row];
			
			for (Platform *platform in _sixthGenPlatforms){
				NSInteger index = [_sixthGenPlatforms indexOfObject:platform];
				
				[platform setIndex:@(index)];
				
				PlatformCell *cell = (PlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
				[cell.switchControl setTag:index];
			}
			break;
		}
		case Section5thGen:{
			Platform *platform = _fifthGenPlatforms[sourceIndexPath.row];
			
			[_fifthGenPlatforms removeObject:platform];
			[_fifthGenPlatforms insertObject:platform atIndex:destinationIndexPath.row];
			
			for (Platform *platform in _fifthGenPlatforms){
				NSInteger index = [_fifthGenPlatforms indexOfObject:platform];
				
				[platform setIndex:@(index)];
				
				PlatformCell *cell = (PlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
				[cell.switchControl setTag:index];
			}
			break;
		}
		default:
			break;
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
		case Section8thGen: platform = _eighthGenPlatforms[indexPath.row]; break;
		case Section7thGen: platform = _seventhGenPlatforms[indexPath.row]; break;
		case Section6thGen: platform = _sixthGenPlatforms[indexPath.row]; break;
		case Section5thGen: platform = _fifthGenPlatforms[indexPath.row]; break;
		default: break;
	}
	
	sender.isOn ? [[Session gamer] addPlatformsObject:platform] : [[Session gamer] removePlatformsObject:platform];
	
	[_context MR_saveToPersistentStoreAndWait];
}

@end
