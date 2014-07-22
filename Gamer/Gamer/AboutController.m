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

@property (nonatomic, strong) NSArray *aboutDictionaries;

@end

@implementation AboutController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	self.aboutDictionaries = @[@{@"title":@"Game Information", @"body":@"The information you see in the game screen (excluding Metascores) comes from the GiantBomb Wiki at giantbomb.com. This app is only possible because of their awesome API and users that contribute to the Wiki."},
							   @{@"title":@"Game Releases", @"body":@"Releases represent the different versions of a game. They're separated by platform and region and have a specific title, release date and box art. When you open or refresh a game, the app will automatically select the correct release based on the order of your platforms and your selected region. If a release is selected, the appropriate title and release date will be displayed on the wishlist."},
							   @{@"title":@"Metascores", @"body":@"Metascores come from metacritic.com. The Metascore displayed on the wishlist and game screen is the selected Metascore for that game. You can select a Metascore at anytime. When first opening a game, the app will automatically select it based on your platforms."},
							   @{@"title":@"Background Refresh", @"body":@"Once a day the app will refresh all games in your wishlist, getting new information and updating Metascores."},
							   @{@"title":@"Exporting & Importing", @"body":@"Exporting creates a file named Backup.gamer with all the games in your wishlist and library with your custom info (pre-ordered, finished, digital, lent, borrowed, rented, rating, notes), then attaches that file to an email you can send to yourself for safekeeping. To import just open a .gamer file in your iOS device and the app will show you the list of all games in that backup file and download their information and images. If you choose to save, those games will be added."}];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return self.aboutDictionaries.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	NSString *body = self.aboutDictionaries[indexPath.row][@"body"];
	
	CGRect bodyRect = [body boundingRectWithSize:CGSizeMake((self.view.frame.size.width - 30) - 45, 50000) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil];
	
	CGFloat height = 41 + bodyRect.size.height + 21;
	if ([Tools deviceIsiPad]) height += 17;
	
	return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	NSDictionary *aboutDictionary = self.aboutDictionaries[indexPath.row];
	
	AboutCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:aboutDictionary[@"title"]];
	[cell.textView setText:aboutDictionary[@"body"]];
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor clearColor]];
	
	BOOL lastRow = (indexPath.row >= ([tableView numberOfRowsInSection:indexPath.section] - 1)) ? YES : NO;
	[cell setSeparatorInset:UIEdgeInsetsMake(0, (lastRow ? (tableView.frame.size.width * 2) : 21), 0, 0)];
}

@end
