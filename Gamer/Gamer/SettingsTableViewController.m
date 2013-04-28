//
//  SettingsTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 4/28/13.
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

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
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
		case 0: return @"Plataforms";
		default: return @"";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case 0: return 4;
		case 1: case 2: return 1;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell;
	
	switch (indexPath.section) {
		case 0:
			cell = [tableView dequeueReusableCellWithIdentifier:@"CheckmarkCell" forIndexPath:indexPath];
			switch (indexPath.row) {
				case 0: [cell.textLabel setText:@"Xbox 360"]; break;
				case 1: [cell.textLabel setText:@"PlayStation 3"]; break;
				case 2: [cell.textLabel setText:@"Wii U"]; break;
				case 3: [cell.textLabel setText:@"Nintendo 3DS"]; break;
				default: break;
			}
			break;
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier:@"NavigationCell" forIndexPath:indexPath];
			[cell.textLabel setText:@"Notifications"];
			break;
		case 2:
			cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell" forIndexPath:indexPath];
			[cell.textLabel setText:@"Clear Database"];
			break;
		default:
			break;
	}
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	switch (indexPath.section) {
		case 0:{
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			[cell setAccessoryType:(cell.accessoryType == UITableViewCellAccessoryCheckmark) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark];
			break;
		}
		case 1:
			[self performSegueWithIdentifier:@"NotificationsSegue" sender:nil];
			break;
		case 2:{
			NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
			[Game truncateAll];
			[Genre truncateAll];
			[Platform truncateAll];
			[Developer truncateAll];
			[Publisher truncateAll];
			[Franchise truncateAll];
			[Theme truncateAll];
			[ReleasePeriod truncateAll];
			[context saveToPersistentStoreAndWait];
			break;
		}
		default:
			break;
	}
}

@end
