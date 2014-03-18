//
//  FAQController.m
//  Gamer
//
//  Created by Caio Mello on 15/03/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "FAQController.h"
#import "FAQCell.h"

@interface FAQController () <UISplitViewControllerDelegate>

@property (nonatomic, strong) UIPopoverController *menuPopoverController;

@end

@implementation FAQController

- (void)viewDidLoad{
	[super viewDidLoad];
	
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.row) {
		case 0: return 270;
		case 1: return 120;
		case 2: return 140;
		case 3: return 170;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	FAQCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell setBackgroundColor:[UIColor clearColor]];
	
	BOOL lastRow = (indexPath.row >= ([tableView numberOfRowsInSection:indexPath.section] - 1)) ? YES : NO;
	[cell setSeparatorInset:UIEdgeInsetsMake(0, (lastRow ? (tableView.frame.size.width * 2) : 21), 0, 0)];
	
	switch (indexPath.row) {
		case 0:
			[cell.titleLabel setText:@"Exporting and importing"];
			[cell.textView setText:@"Exporting creates a file named backup.gamer with all the games in your wishlist and library, with their custom info (finished, digital, lent, pre-ordered), then attaches that file to an email you can send to yourself for safekeeping. To import just open a .gamer file in your iOS device and the app will show you the list of all games in the backup file and download their information and cover image. If you choose to save, those games will be added to your current games."];
			break;
		case 1:
			[cell.titleLabel setText:@"Background refresh"];
			[cell.textView setText:@"Once a day the app will refresh all games in the wishlist, getting new information and updating Metascores of released games."];
			break;
		case 2:
			[cell.titleLabel setText:@"Wishlist and library refresh"];
			[cell.textView setText:@"When you refresh your wishlist or library, the app updates the information and downloads the cover image (if there’s a new one) of each game."];
			break;
		case 3:
			[cell.titleLabel setText:@"Game information"];
			[cell.textView setText:@"The information you see in the game screen (except Metascores) comes from the GiantBomb Wiki at giantbomb.com. This app is only possible because of their awesome API and users that contribute to the Wiki."];
			break;
		default:
			break;
	}
	
	return cell;
}

@end
