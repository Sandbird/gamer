//
//  SettingsTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "Game.h"
#import "Platform.h"
#import "PlatformsController.h"
#import "FAQController.h"
#import <MessageUI/MFMailComposeViewController.h>
#include <sys/sysctl.h>

@interface SettingsTableViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UISegmentedControl *librarySizeSegmentedControl;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	if (![Session gamer].librarySize){
		[[Session gamer] setLibrarySize:@(1)];
		[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
		}];
	}
	else{
		[_librarySizeSegmentedControl setSelectedSegmentIndex:[Session gamer].librarySize.integerValue];
	}
}

- (void)viewWillAppear:(BOOL)animated{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case 0:{
			if ([Tools deviceIsiPhone]){
				[self performSegueWithIdentifier:@"PlatformsSegue" sender:nil];
			}
			else{
				UIStoryboard *storyboard = [UIApplication sharedApplication].delegate.window.rootViewController.storyboard;
				PlatformsController *platformsController = [storyboard instantiateViewControllerWithIdentifier:@"PlatformsController"];
				[self.splitViewController setViewControllers:@[self.navigationController, platformsController]];
				[tableView deselectRowAtIndexPath:indexPath animated:YES];
			}
			break;
		}
		case 2:
			[self exportGames];
			break;
		case 3:
			if ([Tools deviceIsiPhone]){
				[self performSegueWithIdentifier:@"FAQSegue" sender:nil];
			}
			else{
				UIStoryboard *storyboard = [UIApplication sharedApplication].delegate.window.rootViewController.storyboard;
				FAQController *FAQController = [storyboard instantiateViewControllerWithIdentifier:@"FAQController"];
				[self.splitViewController setViewControllers:@[self.navigationController, FAQController]];
				[tableView deselectRowAtIndexPath:indexPath animated:YES];
			}
			break;
		case 4:{
			MFMailComposeViewController *mailComposeViewController = [MFMailComposeViewController new];
			if (mailComposeViewController){
				[mailComposeViewController setMailComposeDelegate:self];
				[mailComposeViewController setToRecipients:@[@"gamer.app@icloud.com"]];
				[mailComposeViewController setSubject:@"Feedback"];
				[mailComposeViewController setMessageBody:[NSString stringWithFormat:@"\n\n\n------\nGamer %@\n%@\niOS %@", [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"], [self device], [UIDevice currentDevice].systemVersion] isHTML:NO];
				
				[self presentViewController:mailComposeViewController animated:YES completion:^{
					[tableView deselectRowAtIndexPath:indexPath animated:YES];
				}];
			}
			else{
				[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"This device cannot send email" message:@"You need to register an email account on this device to be able to send feedback"  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alertView show];
			}
			
			break;
		}
		default:
			break;
	}
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
	if (mailComposeViewController){
		[mailComposeViewController setMailComposeDelegate:self];
		[mailComposeViewController setSubject:@"Gamer App Backup"];
		[mailComposeViewController setMessageBody:@"You can send this file to yourself and keep it in case you ever lose your data." isHTML:NO];
		[mailComposeViewController addAttachmentData:backupData mimeType:@"application/gamer" fileName:@"Backup.gamer"];
		
		[self presentViewController:mailComposeViewController animated:YES completion:^{
			[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
		}];
	}
	else{
		[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"This device cannot send email" message:@"You need to register an email account on this device to be able to send the backup file"  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
	}
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

- (IBAction)segmentedControlValueChangedAction:(UISegmentedControl *)sender{
	[[Session gamer] setLibrarySize:@(sender.selectedSegmentIndex)];
	[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
	}];
}

@end
