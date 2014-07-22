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
	
	[self.refreshControl setTintColor:[UIColor lightGrayColor]];
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	[self loadDataSource];
	
	if (self.game.releases.count == 1){
		[self requestReleasesWithGame:self.game];
	}
}

- (void)viewDidAppear:(BOOL)animated{
	[self.refreshControl endRefreshing];
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
	[cell setSelectionStyle:[self.selectablePlatforms containsObject:release.platform] ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone];
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

#pragma mark - Networking

- (void)requestReleasesWithGame:(Game *)game{
	NSURLRequest *request = [Networking requestForReleasesWithGameIdentifier:game.identifier fields:@"id,name,platform,region,release_date,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Releases", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Releases - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				for (NSDictionary *dictionary in responseObject[@"results"]){
					Release *release = [Release MR_findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:self.context];
					if (!release) release = [Release MR_createInContext:self.context];
					
					Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:dictionary[@"platform"][@"id"] inContext:self.context];
					if (platform){
						[Networking updateRelease:release withResults:dictionary context:self.context];
						[game addReleasesObject:release];
					}
					else{
						[release MR_deleteInContext:self.context];
					}
				}
				
				if (!game.selectedRelease){
					NSArray *reversedIndexSelectablePlatforms = [[self.selectablePlatforms reverseObjectEnumerator] allObjects];
					
					for (Release *release in game.releases){
						// If game not added, release region is selected region, release platform is in selectable platforms
						if (release.region == [Session gamer].region && [reversedIndexSelectablePlatforms containsObject:release.platform]){
							[game setSelectedRelease:release];
							[game setReleasePeriod:[Networking releasePeriodForGameOrRelease:release context:self.context]];
						}
					}
				}
			}
		}
		
		[self.refreshControl endRefreshing];
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
		
		[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self.delegate releasesControllerDidDownloadReleases:self];
			
			[self loadDataSource];
			[self.tableView reloadData];
		}];
	}];
	[dataTask resume];
}

#pragma mark - Custom

- (void)loadDataSource{
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

#pragma mark - Actions

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[sender setEnabled:NO];
	[self requestReleasesWithGame:self.game];
}

- (IBAction)refreshControlValueChangedAction:(UIRefreshControl *)sender{
	[self requestReleasesWithGame:self.game];
}

@end
