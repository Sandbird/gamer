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

@interface SettingsTableViewController ()

@property (nonatomic, strong) NSMutableArray *platforms;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	_platforms = [Platform findAllSortedBy:@"index" ascending:YES withPredicate:nil].mutableCopy;
	
	[self.tableView setEditing:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] set:kGAIScreenName value:@"More"];
	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
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
		case 0: return @"Platforms";
		default: return @"";
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
	switch (section) {
		case 0: return @"Select your platforms. This affects search results. Reordering affects the Library.";
		default: return @"";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case 0: return _platforms.count;
		case 1: return 1;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case 0:{
			PlatformCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlatformCell" forIndexPath:indexPath];
			[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
			
			Platform *platform = _platforms[indexPath.row];
			[cell.titleLabel setText:platform.name];
			[cell.abbreviationLabel setText:platform.abbreviation];
			[cell.abbreviationLabel setBackgroundColor:platform.color];
			[cell.switchControl setOn:([[SessionManager gamer].platforms containsObject:platform]) ? YES : NO];
			[cell.switchControl setTag:indexPath.row];
			
			return cell;
		}
		case 1:{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell" forIndexPath:indexPath];
			[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
			[cell.textLabel setText:@"Delete all data"];
			return cell;
		}
		default:
			return nil;
	}
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
	Platform *platform = _platforms[sourceIndexPath.row];
	
	[_platforms removeObject:platform];
	[_platforms insertObject:platform atIndex:destinationIndexPath.row];
	
	for (Platform *platform in _platforms){
		NSInteger index = [_platforms indexOfObject:platform];
		
		[platform setIndex:@(index)];
		
		PlatformCell *cell = (PlatformCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
		[cell.switchControl setTag:index];
	}
	[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
	}];
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

#pragma mark - Actions

- (IBAction)switchAction:(UISwitch *)sender{
	Platform *platform = _platforms[sender.tag];
	
	sender.isOn ? [[SessionManager gamer] addPlatformsObject:platform] : [[SessionManager gamer] removePlatformsObject:platform];
	
	[_context saveToPersistentStoreAndWait];
}

@end
