//
//  ReleasesController.m
//  Gamer
//
//  Created by Caio Mello on 03/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "ReleasesController.h"
#import "Release.h"
#import "ReleaseCell.h"
#import "Platform.h"
#import "Region.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "Platform+Library.h"

@interface ReleasesController ()

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation ReleasesController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	NSArray *platforms = [Platform MR_findAllSortedBy:@"group,index" ascending:YES withPredicate:nil inContext:self.context];
	
	self.dataSource = [[NSMutableArray alloc] initWithCapacity:platforms.count];
	
	for (Platform *platform in platforms){
		if ([platform containsReleasesWithGame:self.game]){
			NSArray *releases = [platform sortedReleasesWithGame:self.game];
			
			[self.dataSource addObject:@{@"platform":@{@"id":platform.identifier,
												   @"name":platform.name,
												   @"releases":releases}}];
		}
	}
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return self.dataSource.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return self.dataSource[section][@"platform"][@"name"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return [self.dataSource[section][@"platform"][@"releases"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Release *release = self.dataSource[indexPath.section][@"platform"][@"releases"][indexPath.row];
	
	ReleaseCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:release.title];
	[cell.dateLabel setText:release.releaseDateText];
	[cell.coverImageView setImageWithURL:[NSURL URLWithString:release.imageURL] placeholderImage:[Tools imageWithColor:[UIColor darkGrayColor]]];
	[cell.regionImageView setImage:[UIImage imageNamed:release.region.imageName]];
	[cell setAccessoryType:release == self.game.selectedRelease ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
	[cell setSelectionStyle:[[Session gamer].platforms containsObject:release.platform] ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone];
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	if (cell.selectionStyle != UITableViewCellSelectionStyleNone){
		Release *release = self.dataSource[indexPath.section][@"platform"][@"releases"][indexPath.row];
		[self.delegate releasesController:self didSelectRelease:release == self.game.selectedRelease ? nil : release];
		
		[self.tableView reloadData];
		
		[cell setSelected:YES];
		[cell setSelected:NO animated:YES];
	}
}

@end
