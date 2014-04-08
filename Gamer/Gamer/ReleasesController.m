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

@interface ReleasesController ()

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation ReleasesController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	_fetchedResultsController = [self fetch];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - Fetch

- (NSFetchedResultsController *)fetch{
	if (!_fetchedResultsController){
		_fetchedResultsController = [Release MR_fetchAllGroupedBy:@"region.name" withPredicate:[NSPredicate predicateWithFormat:@"game = %@", _game] sortedBy:@"region.name,identifier" ascending:YES inContext:_context];
	}
	
	return _fetchedResultsController;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return self.fetchedResultsController.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	NSString *sectionName = [self.fetchedResultsController.sections[section] name];
	return sectionName;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Release *release = [_fetchedResultsController objectAtIndexPath:indexPath];
	
	ReleaseCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:release.title];
	[cell.dateLabel setText:release.releaseDateText];
	[cell.platformLabel setText:release.platform.abbreviation];
	[cell.platformLabel setBackgroundColor:release.platform.color];
	[cell.coverImageView setImageWithURL:[NSURL URLWithString:release.imageURL]];
	[cell.coverImageView setBackgroundColor:release.imageURL ? [UIColor clearColor] : [UIColor darkGrayColor]];
	[cell.regionImageView setImage:[UIImage imageNamed:release.region.imageName]];
	return cell;
}

@end
