//
//  PlatformPickerController.m
//  Gamer
//
//  Created by Caio Mello on 04/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "PlatformPickerController.h"
#import "Platform.h"
#import "PlatformPickerCell.h"

@interface PlatformPickerController ()

@end

@implementation PlatformPickerController

- (void)viewDidLoad{
	[super viewDidLoad];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return self.selectablePlatforms.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Platform *platform = self.selectablePlatforms[indexPath.row];
	
	PlatformPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:platform.name];
	[cell.abbreviationLabel setText:platform.abbreviation];
	[cell.abbreviationLabel setBackgroundColor:platform.color];
	[cell setAccessoryType:[self.selectedPlatforms containsObject:self.selectablePlatforms[indexPath.row]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	if (cell.accessoryType == UITableViewCellAccessoryCheckmark){
		[cell setAccessoryType:UITableViewCellAccessoryNone];
		[self.selectedPlatforms removeObject:self.selectablePlatforms[indexPath.row]];
	}
	else{
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		[self.selectedPlatforms addObject:self.selectablePlatforms[indexPath.row]];
	}
}

#pragma mark - Actions

- (IBAction)doneBarButtonAction:(UIBarButtonItem *)sender{
	[self.delegate platformPicker:self didSelectPlatforms:self.selectedPlatforms];
}

- (IBAction)cancelBarButtonAction:(UIBarButtonItem *)sender{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
