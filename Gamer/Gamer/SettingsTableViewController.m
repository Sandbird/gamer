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
#import "SettingsPlatformCell.h"
#import "SettingsSegmentedControlCell.h"
#import <MessageUI/MFMailComposeViewController.h>
#include <sys/sysctl.h>

@interface SettingsTableViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *platforms;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	_platforms = [Platform MR_findAllSortedBy:@"index" ascending:YES withPredicate:nil inContext:_context].mutableCopy;
	
	[self.tableView setEditing:YES animated:NO];
	
	if (![Session gamer].librarySize){
		[[Session gamer] setLibrarySize:@(1)];
		[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
		}];
	}
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
		case 0: return @"Platforms";
		case 1: return @"Settings";
		case 2: return @"Even More";
		default: return nil;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
	switch (section) {
		case 0: return @"Select your platforms. This affects search results. Reordering affects the Library and the game screen.";
		case 1: return @"Library game size.";
		case 2: return @"Save all your games to a backup file. To import just open the file in your iOS device.";
		case 3: return @"Tell me about bugs, ask for a feature you would like, give me some suggestions!";
		default: return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case 0: return _platforms.count;
		case 1: case 2: case 3: return 1;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case 0:{
			Platform *platform = _platforms[indexPath.row];
			
			SettingsPlatformCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlatformCell" forIndexPath:indexPath];
			[cell.titleLabel setText:platform.name];
			[cell.abbreviationLabel setText:platform.abbreviation];
			[cell.abbreviationLabel setBackgroundColor:platform.color];
			[cell.switchControl setOn:([[Session gamer].platforms containsObject:platform]) ? YES : NO];
			[cell.switchControl setTag:indexPath.row];
			[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
			
			return cell;
		}
		case 1:{
			SettingsSegmentedControlCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SliderCell" forIndexPath:indexPath];
			[cell.segmentedControl setSelectedSegmentIndex:[Session gamer].librarySize.integerValue];
			[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
			return cell;
		}
		case 2:{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell" forIndexPath:indexPath];
			[cell.textLabel setText:@"Export Games"];
			[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
			return cell;
		}
		case 3:{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell" forIndexPath:indexPath];
			[cell.textLabel setText:@"Feedback"];
			[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
			return cell;
		}
		default:
			return nil;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case 2:
			[self exportGames];
			break;
		case 3:{
			MFMailComposeViewController *mailComposeViewController = [MFMailComposeViewController new];
			[mailComposeViewController setMailComposeDelegate:self];
			[mailComposeViewController setToRecipients:@[@"gamer.app@icloud.com"]];
			[mailComposeViewController setSubject:@"Feedback"];
			[mailComposeViewController setMessageBody:[NSString stringWithFormat:@"\n\n\n------\nGamer %@\n%@\niOS %@", [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"], [self device], [UIDevice currentDevice].systemVersion] isHTML:NO];
			
			[self presentViewController:mailComposeViewController animated:YES completion:^{
				[tableView deselectRowAtIndexPath:indexPath animated:YES];
			}];
			
			break;
		}
		default:
			break;
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

#pragma mark - Export

- (void)exportGames{
	NSArray *games = [Game MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"identifier != nil AND (wanted = %@ OR owned = %@)", @(YES), @(YES)] inContext:_context];
	
	NSMutableArray *gameDictionaries = [[NSMutableArray alloc] initWithCapacity:games.count];
	
	for (Game *game in games){
		NSMutableArray *platformDictionaries = [[NSMutableArray alloc] initWithCapacity:game.platforms.count];
		[platformDictionaries addObject:@{@"id":game.wishlistPlatform ? game.wishlistPlatform.identifier : game.libraryPlatform.identifier}];
		
		NSDictionary *gameDictionary = @{@"id":game.identifier,
										 @"title":game.title,
										 @"location":[game.wanted isEqualToNumber:@(YES)] ? @(GameLocationWishlist) : @(GameLocationLibrary),
										 @"selectedPlatforms":platformDictionaries,
										 @"finished":game.completed,
										 @"digital":game.digital,
										 @"lent":game.loaned,
										 @"preordered":game.preordered};
		
		[gameDictionaries addObject:gameDictionary];
	}
	
	NSDictionary *backupDictionary = @{@"version":[NSBundle mainBundle].infoDictionary[@"CFBundleVersion"],
									   @"games":gameDictionaries};
	
	NSLog(@"%@", backupDictionary);
	
	NSData *backupData = [NSJSONSerialization dataWithJSONObject:backupDictionary options:0 error:nil];
	
	MFMailComposeViewController *mailComposeViewController = [MFMailComposeViewController new];
	[mailComposeViewController setMailComposeDelegate:self];
	[mailComposeViewController setSubject:@"Gamer App Backup"];
	[mailComposeViewController setMessageBody:@"You can send this file to yourself and keep it in a safe place in case you ever lose your data." isHTML:NO];
	[mailComposeViewController addAttachmentData:backupData mimeType:@"application/gamer" fileName:@"Backup.gamer"];
	
	[self presentViewController:mailComposeViewController animated:YES completion:^{
		[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
	}];
}

#pragma mark - MailComposeViewController

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Custom

- (NSString *)device{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *machine = malloc(size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
	NSString *platform = [NSString stringWithUTF8String:machine];
	free(machine);
	return platform;
}

#pragma mark - Actions

- (IBAction)switchAction:(UISwitch *)sender{
	Platform *platform = _platforms[sender.tag];
	
	sender.isOn ? [[Session gamer] addPlatformsObject:platform] : [[Session gamer] removePlatformsObject:platform];
	
	[_context MR_saveToPersistentStoreAndWait];
}

- (IBAction)segmentedControlValueChangedAction:(UISegmentedControl *)sender{
	[[Session gamer] setLibrarySize:@(sender.selectedSegmentIndex)];
	[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
	}];
}

@end
