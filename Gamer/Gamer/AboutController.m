//
//  AboutController.m
//  Gamer
//
//  Created by Caio Mello on 15/03/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "AboutController.h"
#import "AboutCell.h"

@interface AboutController ()

@end

@implementation AboutController

- (void)viewDidLoad{
	[super viewDidLoad];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.row) {
		case 0: return [Tools deviceIsiPhone] ? 278 : 163;
		case 1: return [Tools deviceIsiPhone] ? 128 : 111;
		case 2: return [Tools deviceIsiPhone] ? 145 : 111;
		case 3: return [Tools deviceIsiPhone] ? 178 : 128;
		case 4: return [Tools deviceIsiPhone] ? 228 : 145;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	AboutCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	switch (indexPath.row) {
		case 0:
			[cell.titleLabel setText:@"Exporting & Importing"];
			[cell.textView setText:@"Exporting creates a file named Backup.gamer with all the games in your wishlist and library with their status (finished, digital, lent, pre-ordered), then attaches that file to an email you can send to yourself for safekeeping. To import just open a .gamer file in your iOS device and the app will show you the list of all games in that backup file and download their information and cover image. If you choose to save, those games will be added to your current games."];
			break;
		case 1:
			[cell.titleLabel setText:@"Background Refresh"];
			[cell.textView setText:@"Once a day the app will refresh all games in the wishlist, getting new information and updating Metascores of released games."];
			break;
		case 2:
			[cell.titleLabel setText:@"Wishlist & Library Refresh"];
			[cell.textView setText:@"When you refresh your wishlist or library, the app updates the information and downloads the cover image (if there’s a new one) of each game."];
			break;
		case 3:
			[cell.titleLabel setText:@"Game Information"];
			[cell.textView setText:@"The information you see in the game screen (except Metascore) comes from the GiantBomb Wiki at giantbomb.com. This app is only possible because of their awesome API and users that contribute to the Wiki."];
			break;
		case 4:
			[cell.titleLabel setText:@"Metascore"];
			[cell.textView setText:@"Metascores come from metacritic.com. The score is retrieved when the game has already been released, and it is displayed only when the app is able to get it, if not it'll still display the Metacritic button so you can still check on it or search for the game in Metacritic itself. The current implementation is not very reliable, but it will be remade from scratch very soon."];
			break;
		default:
			break;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor clearColor]];
	
	BOOL lastRow = (indexPath.row >= ([tableView numberOfRowsInSection:indexPath.section] - 1)) ? YES : NO;
	[cell setSeparatorInset:UIEdgeInsetsMake(0, (lastRow ? (tableView.frame.size.width * 2) : 21), 0, 0)];
}

@end
