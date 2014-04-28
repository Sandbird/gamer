//
//  MetascoreController.m
//  Gamer
//
//  Created by Caio Mello on 03/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "MetascoreController.h"
#import "Platform.h"
#import "Metascore.h"
#import "MetascoreCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "Platform+Library.h"

@interface MetascoreController ()

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation MetascoreController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	[self loadDataSource];
	
	if (_dataSource.count == 1 && _game.platforms.count > 1){
		for (Platform *platform in _game.platforms){
			[self requestMetascoreForGame:_game platform:platform];
		}
	}
}

- (void)viewDidAppear:(BOOL)animated{
	[self.refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - Data Source

- (void)loadDataSource{
	_dataSource = [[NSMutableArray alloc] initWithCapacity:[Session gamer].platforms.count];
	
	NSArray *platforms = [Platform MR_findAllSortedBy:@"group,index" ascending:YES withPredicate:nil inContext:_context];
	
	for (Platform *platform in platforms){
		Metascore *metascore = [platform metascoreWithGame:_game];
		
		if (metascore){
			[_dataSource addObject:@{@"platform":@{@"id":platform.identifier,
												   @"name":platform.name,
												   @"metascore":metascore}}];
		}
	}
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return _dataSource.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return _dataSource[section][@"platform"][@"name"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	Metascore *metascore = _dataSource[indexPath.section][@"platform"][@"metascore"];
	
	MetascoreCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.criticScoreLabel setText:[NSString stringWithFormat:@"%@", metascore.criticScore]];
	[cell.userScoreLabel setText:[NSString stringWithFormat:@"%.1f", metascore.userScore.floatValue]];
	[cell.criticScoreLabel setBackgroundColor:[Networking colorForMetascore:cell.criticScoreLabel.text]];
	[cell.userScoreLabel setBackgroundColor:[Networking colorForMetascore:[cell.userScoreLabel.text stringByReplacingOccurrencesOfString:@"." withString:@""]]];
	[cell.userScoreLabel.layer setCornerRadius:60/2];
	[cell setAccessoryType:metascore == _game.selectedMetascore ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
	[cell setSelectionStyle:[[Session gamer].platforms containsObject:metascore.platform] ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	if ([tableView cellForRowAtIndexPath:indexPath].selectionStyle != UITableViewCellSelectionStyleNone){
		Metascore *metascore = _dataSource[indexPath.section][@"platform"][@"metascore"];
		[self.delegate metascoreController:self didSelectMetascore:metascore];
	}
}

#pragma mark - Networking

- (void)requestMetascoreForGame:(Game *)game platform:(Platform *)platform{
	NSURLRequest *request = [Networking requestForMetascoreWithGame:game platform:platform];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Metascore", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Metascore - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"result"] isKindOfClass:[NSNumber class]])
				return;
			
			NSDictionary *results = responseObject[@"result"];
			
			NSString *metacriticURL = [Tools stringFromSourceIfNotNull:results[@"url"]];
			
			Metascore *metascore = [Metascore MR_findFirstByAttribute:@"metacriticURL" withValue:metacriticURL inContext:_context];
			if (!metascore) metascore = [Metascore MR_createInContext:_context];
			[metascore setCriticScore:[Tools integerNumberFromSourceIfNotNull:results[@"score"]]];
			[metascore setUserScore:[Tools decimalNumberFromSourceIfNotNull:results[@"userscore"]]];
			[metascore setMetacriticURL:metacriticURL];
			[metascore setPlatform:platform];
			[game addMetascoresObject:metascore];
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
//				[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionDetails] withRowAnimation:UITableViewRowAnimationAutomatic];
//				[self.tableView beginUpdates];
//				[self.tableView endUpdates];
				
				[self loadDataSource];
				
				[self.tableView reloadData];
			}];
		}
		
		[self.refreshControl endRefreshing];
	}];
	[dataTask resume];
}

#pragma mark - Actions

- (IBAction)refreshControlValueChangedAction:(UIRefreshControl *)sender{
	for (Platform *platform in _game.platforms){
		[self requestMetascoreForGame:_game platform:platform];
	}
}

@end
