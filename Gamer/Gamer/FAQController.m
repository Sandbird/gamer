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
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	FAQCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell setBackgroundColor:[UIColor clearColor]];
	
	switch (indexPath.row) {
		case 0:
			[cell.titleLabel setText:@"?"];
			[cell.textView setText:@"bla"];
			break;
		case 1:
			[cell.titleLabel setText:@"?"];
			[cell.textView setText:@"bla"];
			break;
		default:
			break;
	}
	
	return cell;
}

@end
