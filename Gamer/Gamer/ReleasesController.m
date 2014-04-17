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
		_fetchedResultsController = [Release MR_fetchAllGroupedBy:@"platform.identifier" withPredicate:[NSPredicate predicateWithFormat:@"game = %@", _game] sortedBy:@"platform.identifier,releaseDate" ascending:YES inContext:_context];
	}
	
	return _fetchedResultsController;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return self.fetchedResultsController.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	NSString *sectionName = [self.fetchedResultsController.sections[section] name];
	Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:sectionName inContext:_context];
	return platform.name;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Release *release = [_fetchedResultsController objectAtIndexPath:indexPath];
	
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	if ([tableView cellForRowAtIndexPath:indexPath].selectionStyle != UITableViewCellSelectionStyleNone){
		Release *release = [_fetchedResultsController objectAtIndexPath:indexPath];
		[self.delegate releasesController:self didSelectRelease:release == _game.selectedRelease ? nil : release];
	}
}

@end
