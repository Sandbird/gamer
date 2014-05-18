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

@interface PlatformsController ()

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
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	self.eighthGenPlatforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"group = %@", @(0)] inContext:self.context].mutableCopy;
	self.seventhGenPlatforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"group = %@", @(1)] inContext:self.context].mutableCopy;
	self.sixthGenPlatforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"group = %@", @(2)] inContext:self.context].mutableCopy;
	self.fifthGenPlatforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"group = %@", @(3)] inContext:self.context].mutableCopy;
	
	[self.tableView setEditing:YES animated:NO];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section) {
		case Section8thGen: return @"Current Generation";
		case Section7thGen: return @"7th Generation";
		case Section6thGen: return @"6th Generation";
		case Section5thGen: return @"5th Generation";
		default: return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case Section8thGen: return self.eighthGenPlatforms.count;
		case Section7thGen: return self.seventhGenPlatforms.count;
		case Section6thGen: return self.sixthGenPlatforms.count;
		case Section5thGen: return self.fifthGenPlatforms.count;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Platform *platform;
	
	switch (indexPath.section) {
		case Section8thGen: platform = self.eighthGenPlatforms[indexPath.row]; break;
		case Section7thGen: platform = self.seventhGenPlatforms[indexPath.row]; break;
		case Section6thGen: platform = self.sixthGenPlatforms[indexPath.row]; break;
		case Section5thGen: platform = self.fifthGenPlatforms[indexPath.row]; break;
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
			Platform *platform = self.eighthGenPlatforms[sourceIndexPath.row];
			
			[self.eighthGenPlatforms removeObject:platform];
			[self.eighthGenPlatforms insertObject:platform atIndex:destinationIndexPath.row];
			
			for (Platform *platform in self.eighthGenPlatforms){
				NSInteger index = [self.eighthGenPlatforms indexOfObject:platform];
				
				[platform setIndex:@(index)];
				
				PlatformCell *cell = (PlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
				[cell.switchControl setTag:index];
			}
			break;
		}
		case Section7thGen:{
			Platform *platform = self.seventhGenPlatforms[sourceIndexPath.row];
			
			[self.seventhGenPlatforms removeObject:platform];
			[self.seventhGenPlatforms insertObject:platform atIndex:destinationIndexPath.row];
			
			for (Platform *platform in self.seventhGenPlatforms){
				NSInteger index = [self.seventhGenPlatforms indexOfObject:platform];
				
				[platform setIndex:@(index)];
				
				PlatformCell *cell = (PlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
				[cell.switchControl setTag:index];
			}
			break;
		}
		case Section6thGen:{
			Platform *platform = self.sixthGenPlatforms[sourceIndexPath.row];
			
			[self.sixthGenPlatforms removeObject:platform];
			[self.sixthGenPlatforms insertObject:platform atIndex:destinationIndexPath.row];
			
			for (Platform *platform in self.sixthGenPlatforms){
				NSInteger index = [self.sixthGenPlatforms indexOfObject:platform];
				
				[platform setIndex:@(index)];
				
				PlatformCell *cell = (PlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
				[cell.switchControl setTag:index];
			}
			break;
		}
		case Section5thGen:{
			Platform *platform = self.fifthGenPlatforms[sourceIndexPath.row];
			
			[self.fifthGenPlatforms removeObject:platform];
			[self.fifthGenPlatforms insertObject:platform atIndex:destinationIndexPath.row];
			
			for (Platform *platform in self.fifthGenPlatforms){
				NSInteger index = [self.fifthGenPlatforms indexOfObject:platform];
				
				[platform setIndex:@(index)];
				
				PlatformCell *cell = (PlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
				[cell.switchControl setTag:index];
			}
			break;
		}
		default:
			break;
	}
	
	[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
	}];
}

#pragma mark - Actions

- (IBAction)switchAction:(UISwitch *)sender{
	UITableViewCell *cell = (UITableViewCell *)sender.superview.superview.superview;
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	Platform *platform;
	
	switch (indexPath.section) {
		case Section8thGen: platform = self.eighthGenPlatforms[indexPath.row]; break;
		case Section7thGen: platform = self.seventhGenPlatforms[indexPath.row]; break;
		case Section6thGen: platform = self.sixthGenPlatforms[indexPath.row]; break;
		case Section5thGen: platform = self.fifthGenPlatforms[indexPath.row]; break;
		default: break;
	}
	
	sender.isOn ? [[Session gamer] addPlatformsObject:platform] : [[Session gamer] removePlatformsObject:platform];
	
	[self.context MR_saveToPersistentStoreAndWait];
}

@end
