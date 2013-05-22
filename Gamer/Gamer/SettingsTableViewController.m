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

@property (nonatomic, strong) NSFetchedResultsController *platformsFetch;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
	_platformsFetch = [Platform fetchAllGroupedBy:nil withPredicate:nil sortedBy:@"name" ascending:YES];
	[self.tableView reloadData];
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
	switch (section) {
		case 0: return @"Select the platforms of the games you want to see on search results.";
		default: return @"";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case 0: return [_platformsFetch.sections[section] numberOfObjects];
		case 1: case 2: return 1;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell;
	
	switch (indexPath.section) {
		case 0:{
			cell = [tableView dequeueReusableCellWithIdentifier:@"CheckmarkCell" forIndexPath:indexPath];
			Platform *platform = [_platformsFetch objectAtIndexPath:indexPath];
			[cell.textLabel setText:platform.name];
			[cell setAccessoryType:([platform.favorite isEqualToNumber:@(YES)]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
			break;
		}
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier:@"NavigationCell" forIndexPath:indexPath];
			[cell.textLabel setText:@"Notifications"];
			break;
		case 2:
			cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell" forIndexPath:indexPath];
			[cell.textLabel setText:@"Delete all data"];
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
			
			NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
			Platform *platform = [_platformsFetch objectAtIndexPath:indexPath];
			[platform setFavorite:(cell.accessoryType == UITableViewCellAccessoryCheckmark) ? @(YES) : @(NO)];
			[context saveToPersistentStoreAndWait];
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
			[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				_platformsFetch = [Platform fetchAllGroupedBy:nil withPredicate:nil sortedBy:@"name" ascending:YES];
				[self.tableView reloadData];
			}];
			break;
		}
		default:
			break;
	}
}

#pragma mark - Stuff

- (IBAction)testBarButtonAction:(UIBarButtonItem *)sender{
//	[self.tableView setEditing:YES animated:YES];
	
	[self requestPlatformWithIdentifier:@(139) color:[UIColor colorWithRed:0 green:.509803922 blue:.745098039 alpha:1] completion:^{
		[self requestPlatformWithIdentifier:@(129) color:[UIColor colorWithRed:0 green:.235294118 blue:.705882353 alpha:1] completion:^{
			[self requestPlatformWithIdentifier:@(117) color:[UIColor colorWithRed:.784313725 green:0 blue:0 alpha:1] completion:^{
				[self requestPlatformWithIdentifier:@(35) color:[UIColor colorWithRed:0 green:.117647059 blue:.62745098 alpha:1] completion:^{
					[self requestPlatformWithIdentifier:@(20) color:[UIColor colorWithRed:.31372549 green:.62745098 blue:.117647059 alpha:1] completion:^{
						[self requestPlatformWithIdentifier:@(94) color:[UIColor colorWithRed:.156862745 green:.156862745 blue:.156862745 alpha:1] completion:^{
							[self requestPlatformWithIdentifier:@(146) color:[UIColor colorWithRed:.019607843 green:0 blue:.235294118 alpha:1] completion:^{
								[self requestPlatformWithIdentifier:@(145) color:[UIColor colorWithRed:.058823529 green:.431372549 blue:0 alpha:1] completion:nil];
							}];
						}];
					}];
				}];
			}];
		}];
	}];
}

- (void)requestPlatformWithIdentifier:(NSNumber *)identifier color:(UIColor *)color completion:(void (^)())completion{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.giantbomb.com/platform/3045-%@/?api_key=d92c258adb509ded409d28f4e51de2c83e297011&format=json&field_list=id,name,abbreviation", identifier]]];
	[request setHTTPMethod:@"GET"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//		NSLog(@"%lld bytes", response.expectedContentLength);
//		NSLog(@"%@", JSON);
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		Platform *platform = [Platform findFirstByAttribute:@"identifier" withValue:identifier];
		if (!platform) platform = [[Platform alloc] initWithEntity:[NSEntityDescription entityForName:@"Platform" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		[platform setIdentifier:identifier];
		[platform setName:JSON[@"results"][@"name"]];
		[platform setNameShort:JSON[@"results"][@"abbreviation"]];
		[platform setColor:color];
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			_platformsFetch = [Platform fetchAllGroupedBy:nil withPredicate:nil sortedBy:@"name" ascending:YES];
			[self.tableView reloadData];
		}];
		
		if (completion){
			completion();
		}
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		NSLog(@"Error %d", response.statusCode);
	}];
	[operation start];
}

@end
