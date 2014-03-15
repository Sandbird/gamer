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

@interface PlatformsController ()

@property (nonatomic, strong) NSMutableArray *platforms;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation PlatformsController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	_platforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:nil inContext:_context].mutableCopy;
	
	[self.tableView setEditing:YES animated:NO];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section) {
//		case 0: return @"Current";
//		case 1: return @"Legacy";
		default: return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
//		case 0: return 8;
//		case 1: return 3;
		case 0: return _platforms.count;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Platform *platform = _platforms[indexPath.row];
	
	SettingsPlatformCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:platform.name];
	[cell.abbreviationLabel setText:platform.abbreviation];
	[cell.abbreviationLabel setBackgroundColor:platform.color];
	[cell.switchControl setOn:([[Session gamer].platforms containsObject:platform]) ? YES : NO];
	[cell.switchControl setTag:indexPath.row];
//	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
	return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
	return indexPath.section == 0 ? YES : NO;
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
	Platform *platform = _platforms[sourceIndexPath.row];
	
	[_platforms removeObject:platform];
	[_platforms insertObject:platform atIndex:destinationIndexPath.row];
	
	for (Platform *platform in _platforms){
		NSInteger index = [_platforms indexOfObject:platform];
		
		[platform setIndex:@(index)];
		
		SettingsPlatformCell *cell = (SettingsPlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
		[cell.switchControl setTag:index];
	}
	[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
	}];
}

#pragma mark - Actions

- (IBAction)switchAction:(UISwitch *)sender{
	Platform *platform = _platforms[sender.tag];
	
	sender.isOn ? [[Session gamer] addPlatformsObject:platform] : [[Session gamer] removePlatformsObject:platform];
	
	[_context MR_saveToPersistentStoreAndWait];
}

@end
