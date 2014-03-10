//
//  SearchTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SearchTableViewController.h"
#import "GameTableViewController.h"
#import "SearchResult.h"
#import "Platform.h"
#import "SearchCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface SearchTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSURLSessionDataTask *runningTask;

@end

@implementation SearchTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	// Search bar setup
	_searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 300, 44)];
	[_searchBar setPlaceholder:@"Find Games"];
	[_searchBar setDelegate:self];
	
	[self.navigationItem setTitleView:_searchBar];
	
	[self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
	
	_results = [[NSMutableArray alloc] initWithCapacity:100];
}

- (void)viewWillAppear:(BOOL)animated{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
	
	[_searchBar setText:@""];
	
	// Show guide view if no platform is selected
	if (_results.count == 0 && [Session gamer].platforms.count == 0){
		UIView *view = [[NSBundle mainBundle] loadNibNamed:[Tools deviceIsiPad] ? @"iPad" : @"iPhone" owner:self options:nil][2];
		[self.tableView setBackgroundView:view];
		[_searchBar setUserInteractionEnabled:NO];
	}
	else{
		[self.tableView setBackgroundView:nil];
		[_searchBar setUserInteractionEnabled:YES];
	}
}

- (void)viewDidAppear:(BOOL)animated{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated{
	[_runningTask cancel];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - SearchBar

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
	[_searchBar setShowsSearchResultsButton:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[_runningTask cancel];
	
	if (searchText.length > 0){
		NSCharacterSet *alphanumericCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"];
		NSString *query = [[searchText componentsSeparatedByCharactersInSet:[alphanumericCharacterSet invertedSet]] componentsJoinedByString:@"%"];
		[self requestGamesWithTitlesContainingQuery:query];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
	
	[_runningTask cancel];
	
	NSCharacterSet *alphanumericCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"];
	NSString *query = [[searchBar.text componentsSeparatedByCharactersInSet:[alphanumericCharacterSet invertedSet]] componentsJoinedByString:@"%"];
	[self requestGamesWithTitlesContainingQuery:query];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
	[_runningTask cancel];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
	[_searchBar setShowsSearchResultsButton:NO];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	BOOL lastRow = (indexPath.row == ([tableView numberOfRowsInSection:indexPath.section] - 1)) ? YES : NO;
	
	SearchResult *result = _results[indexPath.row];
	
	SearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:result.title];
	[cell.coverImageView setImageWithURL:[NSURL URLWithString:result.imageURL] placeholderImage:[Tools imageWithColor:[UIColor darkGrayColor]]];
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
	[cell setSeparatorInset:UIEdgeInsetsMake(0, (lastRow ? tableView.frame.size.width * 2 : 58), 0, 0)];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
}

#pragma mark - Networking

- (void)requestGamesWithTitlesContainingQuery:(NSString *)query{
	NSURLRequest *request = [Networking requestForGamesWithTitle:query fields:@"id,name,image" platforms:[Session gamer].platforms.allObjects];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Error: %@", self, ((NSHTTPURLResponse *)response).statusCode, error);
		}
		else{
//			NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			[_results removeAllObjects];
			
			for (NSDictionary *dictionary in responseObject[@"results"]){
				SearchResult *result = [SearchResult new];
				[result setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
				[result setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				if (dictionary[@"image"] != [NSNull null]) [result setImageURL:[Tools stringFromSourceIfNotNull:dictionary[@"image"][@"icon_url"]]];
				[_results addObject:result];
			}
			
			[self.tableView reloadData];
		}
	}];
	[dataTask resume];
	_runningTask = dataTask;
}

#pragma mark - Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		if ([Tools deviceIsiPad]){
			UINavigationController *navigationController = segue.destinationViewController;
			GameTableViewController *destination = (GameTableViewController *)navigationController.topViewController;
			Game *game = _results[self.tableView.indexPathForSelectedRow.row];
			[destination setGameIdentifier:game.identifier];
		}
		else{
			// Pop other tabs when opening game details
			for (UIViewController *viewController in self.tabBarController.viewControllers){
				[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
			}
			
			GameTableViewController *destination = segue.destinationViewController;
			Game *game = _results[self.tableView.indexPathForSelectedRow.row];
			[destination setGameIdentifier:game.identifier];
		}
	}
}

@end
