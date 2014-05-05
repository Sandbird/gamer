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
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	_dataSource = [[NSMutableArray alloc] initWithCapacity:[Session gamer].platforms.count];
	
	NSArray *platforms = [Platform MR_findAllSortedBy:@"group,index" ascending:YES withPredicate:nil inContext:_context];
	
	for (Platform *platform in platforms){
		if ([platform containsReleasesWithGame:_game]){
			NSArray *releases = [platform sortedReleasesWithGame:_game];
			
			[_dataSource addObject:@{@"platform":@{@"id":platform.identifier,
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
	return _dataSource.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return _dataSource[section][@"platform"][@"name"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return [_dataSource[section][@"platform"][@"releases"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Release *release = _dataSource[indexPath.section][@"platform"][@"releases"][indexPath.row];
	
	ReleaseCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:release.title];
	[cell.dateLabel setText:release.releaseDateText];
	[cell.coverImageView setImageWithURL:[NSURL URLWithString:release.imageURL]];
	[cell.coverImageView setBackgroundColor:release.imageURL ? [UIColor clearColor] : [UIColor darkGrayColor]];
	[cell.regionImageView setImage:[UIImage imageNamed:release.region.imageName]];
	[cell setAccessoryType:release == _game.selectedRelease ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
	[cell setSelectionStyle:[[Session gamer].platforms containsObject:release.platform] ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone];
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	if ([tableView cellForRowAtIndexPath:indexPath].selectionStyle != UITableViewCellSelectionStyleNone){
		Release *release = _dataSource[indexPath.section][@"platform"][@"releases"][indexPath.row];
		[self.delegate releasesController:self didSelectRelease:release == _game.selectedRelease ? nil : release];
	}
}

@end
