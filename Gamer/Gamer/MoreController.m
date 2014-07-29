//
//  MoreController.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "MoreController.h"
#import "Game.h"
#import "Platform.h"
#import "Release.h"
#import "PlatformsController.h"
#import "RegionsController.h"
#import "AboutController.h"
#import <MessageUI/MFMailComposeViewController.h>
#include <sys/sysctl.h>

typedef NS_ENUM(NSInteger, Section){
	SectionPlatforms,
	SectionRegions,
	SectionLibrarySize,
	SectionFeedback,
	SectionExport,
	SectionAbout
};

@interface MoreController () <MFMailComposeViewControllerDelegate, UISplitViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UISegmentedControl *librarySizeSegmentedControl;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation MoreController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self.splitViewController setDelegate:self];
	
	if ([Tools deviceIsiPad])
		[self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:.125490196 green:.125490196 blue:.125490196 alpha:1]];
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	if (![Session gamer].librarySize){
		[[Session gamer] setLibrarySize:@(LibrarySizeMedium)];
		[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
		}];
	}
	else{
		[self.librarySizeSegmentedControl setSelectedSegmentIndex:[Session gamer].librarySize.integerValue];
	}
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - SplitViewController

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation{
	return NO;
}

#pragma mark - TableView

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case SectionPlatforms:{
			if ([Tools deviceIsiPhone]){
				[self performSegueWithIdentifier:@"PlatformsSegue" sender:nil];
			}
			else{
				UIStoryboard *storyboard = [UIApplication sharedApplication].delegate.window.rootViewController.storyboard;
				PlatformsController *platformsController = [storyboard instantiateViewControllerWithIdentifier:@"PlatformsController"];
				
				UINavigationController *detailController = self.splitViewController.viewControllers[1];
				[detailController setViewControllers:@[platformsController]];
				
				[tableView deselectRowAtIndexPath:indexPath animated:NO];
			}
			break;
		}
		case SectionRegions:{
			if ([Tools deviceIsiPhone]){
				[self performSegueWithIdentifier:@"RegionsSegue" sender:nil];
			}
			else{
				UIStoryboard *storyboard = [UIApplication sharedApplication].delegate.window.rootViewController.storyboard;
				RegionsController *regionsController = [storyboard instantiateViewControllerWithIdentifier:@"RegionsController"];
				
				UINavigationController *detailController = self.splitViewController.viewControllers[1];
				[detailController setViewControllers:@[regionsController]];
				
				[tableView deselectRowAtIndexPath:indexPath animated:NO];
			}
			break;
		}
		case SectionFeedback:{
			switch (indexPath.row) {
				case 0:{
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
				case 1:
					[tableView deselectRowAtIndexPath:indexPath animated:YES];
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id683636311"]];
					break;
				default:
					break;
			}
			
			break;
		}
		case SectionExport:
			[self exportGames];
			break;
		case SectionAbout:
			if ([Tools deviceIsiPhone]){
				[self performSegueWithIdentifier:@"AboutSegue" sender:nil];
			}
			else{
				UIStoryboard *storyboard = [UIApplication sharedApplication].delegate.window.rootViewController.storyboard;
				AboutController *aboutController = [storyboard instantiateViewControllerWithIdentifier:@"AboutController"];
				
				UINavigationController *detailController = self.splitViewController.viewControllers[1];
				[detailController setViewControllers:@[aboutController]];
				
				[tableView deselectRowAtIndexPath:indexPath animated:NO];
			}
			break;
		default:
			break;
	}
}

#pragma mark - Export

- (void)exportGames{
	NSArray *games = [Game MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"identifier != nil AND (inWishlist = %@ OR inLibrary = %@)", @(YES), @(YES)] inContext:self.context];
	
	NSMutableArray *gameDictionaries = [[NSMutableArray alloc] initWithCapacity:games.count];
	
	for (Game *game in games){
		NSArray *libraryPlatformIdentifiers = [game.libraryPlatforms valueForKey:@"identifier"];
		
		NSDictionary *gameDictionary = @{@"id":game.identifier,
										 @"title":game.title ? game.title : @"",
										 @"inWishlist":game.inWishlist,
										 @"inLibrary":game.inLibrary,
										 @"wishlistPlatform":game.wishlistPlatform.identifier ? game.wishlistPlatform.identifier : [NSNull null],
										 @"libraryPlatforms":libraryPlatformIdentifiers ? libraryPlatformIdentifiers : [NSNull null],
										 @"selectedRelease":game.selectedRelease.identifier ? game.selectedRelease.identifier : [NSNull null],
										 @"finished":game.finished ? game.finished : @(0),
										 @"digital":game.digital ? game.digital : @(0),
										 @"lent":game.lent ? game.lent : @(0),
										 @"preordered":game.preordered ? game.preordered : @(0),
										 @"borrowed":game.borrowed ? game.borrowed : @(0),
										 @"rented":game.rented ? game.rented : @(0),
										 @"personalRating":game.personalRating ? game.personalRating : @(0),
										 @"notes":game.notes.length > 0 ? game.notes : @""};
		
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
	[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
	}];
}

@end
