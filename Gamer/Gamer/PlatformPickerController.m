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
	return _selectablePlatforms.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Platform *platform = _selectablePlatforms[indexPath.row];
	
	PlatformPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:platform.name];
	[cell.abbreviationLabel setText:platform.abbreviation];
	[cell.abbreviationLabel setBackgroundColor:platform.color];
	[cell setAccessoryType:[_selectedPlatforms containsObject:_selectablePlatforms[indexPath.row]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	if (cell.accessoryType == UITableViewCellAccessoryCheckmark){
		[cell setAccessoryType:UITableViewCellAccessoryNone];
		[_selectedPlatforms removeObject:_selectablePlatforms[indexPath.row]];
	}
	else{
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		[_selectedPlatforms addObject:_selectablePlatforms[indexPath.row]];
	}
}

#pragma mark - Actions

- (IBAction)doneBarButtonAction:(UIBarButtonItem *)sender{
	[self.delegate platformPicker:self didSelectPlatforms:_selectedPlatforms];
}

- (IBAction)cancelBarButtonAction:(UIBarButtonItem *)sender{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
