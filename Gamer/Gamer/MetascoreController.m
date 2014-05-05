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
#import "MetacriticController.h"

@interface MetascoreController () <FetchedTableViewDelegate>

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation MetascoreController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	self.fetchedResultsController = [self fetchData];
	
	if (self.fetchedResultsController.fetchedObjects.count == 1 && _game.platforms.count > 1){
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

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)fetchData{
	if (!self.fetchedResultsController){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game = %@", _game];
		self.fetchedResultsController = [Metascore MR_fetchAllSortedBy:@"platform.group,platform.index" ascending:YES withPredicate:predicate groupBy:nil delegate:self inContext:_context];
	}
	
	return self.fetchedResultsController;
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	MetascoreCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	if ([tableView cellForRowAtIndexPath:indexPath].selectionStyle != UITableViewCellSelectionStyleNone){
		Metascore *metascore = [self.fetchedResultsController objectAtIndexPath:indexPath];
		[self.delegate metascoreController:self didSelectMetascore:metascore];
	}
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	Metascore *metascore = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	MetascoreCell *customCell = (MetascoreCell *)cell;
	[customCell.criticScoreLabel setText:[metascore.criticScore isEqualToNumber:@(0)] ? @"?" : [NSString stringWithFormat:@"%@", metascore.criticScore]];
	[customCell.criticScoreLabel setTextColor:[metascore.criticScore isEqualToNumber:@(0)] ? [UIColor lightGrayColor] : [Networking colorForMetascore:customCell.criticScoreLabel.text]];
	[customCell.userScoreLabel setText:[metascore.userScore isEqual:[NSDecimalNumber zero]] ? @"?" : [NSString stringWithFormat:@"%.1f", metascore.userScore.floatValue]];
	[customCell.userScoreLabel setTextColor:[metascore.userScore isEqual:[NSDecimalNumber zero]] ? [UIColor lightGrayColor] : [Networking colorForMetascore:[customCell.userScoreLabel.text stringByReplacingOccurrencesOfString:@"." withString:@""]]];
	[customCell.platformLabel setText:metascore.platform.abbreviation];
	[customCell.platformLabel setBackgroundColor:metascore.platform.color];
	[customCell setAccessoryType:metascore == _game.selectedMetascore ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
	[customCell setSelectionStyle:[[Session gamer].platforms containsObject:metascore.platform] ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone];
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
//			NSLog(@"%@", responseObject);
			
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
				[self.tableView reloadRowsAtIndexPaths:@[[self.fetchedResultsController indexPathForObject:metascore]] withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView beginUpdates];
				[self.tableView endUpdates];
			}];
		}
		
		[self.refreshControl endRefreshing];
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}];
	[dataTask resume];
}

#pragma mark - Actions

- (IBAction)refreshControlValueChangedAction:(UIRefreshControl *)sender{
	for (Platform *platform in _game.platforms){
		[self requestMetascoreForGame:_game platform:platform];
	}
}

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[self.navigationItem.rightBarButtonItem setEnabled:NO];
	
	for (Platform *platform in _game.platforms){
		[self requestMetascoreForGame:_game platform:platform];
	}
}

- (IBAction)metacriticButtonAction:(UIButton *)sender{
	[self performSegueWithIdentifier:@"MetacriticSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	MetacriticController *destination = segue.destinationViewController;
	[destination setURL:[NSURL URLWithString:_game.selectedMetascore.metacriticURL]];
}

@end
