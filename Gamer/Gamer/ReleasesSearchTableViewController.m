//
//  ReleaseSearchTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 4/22/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "ReleasesSearchTableViewController.h"
#import "GameTableViewController.h"
#import "SearchResult.h"
#import "SessionManager.h"
#import "Utilities.h"

@interface ReleasesSearchTableViewController ()

@end

@implementation ReleasesSearchTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	// Search bar setup
	if (!_searchBar) _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 252, 44)];
	[_searchBar setPlaceholder:@"Search for upcoming games"];
	[_searchBar setDelegate:self];
	
	// Remove search bar background
	for (id backgroundImage in _searchBar.subviews)
        if ([backgroundImage isKindOfClass:NSClassFromString(@"UISearchBarBackground")])
			[backgroundImage removeFromSuperview];
	
	// Add search bar to navigation bar
	UIBarButtonItem *searchBarItem;
	if (!searchBarItem) searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:_searchBar];
	[self.navigationItem setRightBarButtonItem:searchBarItem];
	
	if (!_results) _results = [[NSMutableArray alloc] init];
}

- (void)viewDidLayoutSubviews{
//	[self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 216, 0)];
}

- (void)viewDidAppear:(BOOL)animated{
	[_searchBar becomeFirstResponder];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - SearchBar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[_previousOperation cancel];
	[self requestSearchResultsWithQuery:[searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[_previousOperation cancel];
	[self requestSearchResultsWithQuery:[searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell" forIndexPath:indexPath];
	
	SearchResult *result = _results[indexPath.row];
	[cell.textLabel setText:result.title];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Networking

- (void)requestSearchResultsWithQuery:(NSString *)query{
	NSURLRequest *request = [SessionManager APISearchRequestWithFields:@"id,name,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,original_release_date,platforms" query:query];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		[_results removeAllObjects];
		
//		NSLog(@"%@", JSON);
		
		for (NSDictionary *dictionary in JSON[@"results"]){
			if (dictionary[@"platforms"] != [NSNull null]){
				for (NSDictionary *platform in dictionary[@"platforms"]){
					if ([platform[@"name"] isEqualToString:@"Xbox 360"] ||
						[platform[@"name"] isEqualToString:@"PlayStation 3"] ||
						[platform[@"name"] isEqualToString:@"PC"] ||
						[platform[@"name"] isEqualToString:@"Wii U"] ||
						[platform[@"name"] isEqualToString:@"Nintendo 3DS"]){
						
						SearchResult *result;
						if (!result) result = [[SearchResult alloc] init];
						[result setTitle:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
						[result setIdentifier:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
						[_results addObject:result];
						break;
					}
				}
			}
		}
		
		[self.tableView reloadData];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Error: %@", self, response.statusCode, error.description);
		
		[_results removeAllObjects];
		[self.tableView reloadData];
	}];
	[operation start];
	_previousOperation = operation;
}

#pragma mark - Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	GameTableViewController *destination = segue.destinationViewController;
	[destination setSearchResult:_results[self.tableView.indexPathForSelectedRow.row]];
	[destination setOrigin:1];
}

@end
