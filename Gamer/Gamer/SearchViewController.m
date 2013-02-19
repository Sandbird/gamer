//
//  SearchViewController.m
//  Gamer
//
//  Created by Caio Mello on 2/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SearchViewController.h"
#import "SearchResult.h"
#import "GameViewController.h"

@interface SearchViewController ()

@end

@implementation SearchViewController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	// Search bar setup
	_searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 252, 44)];
	[_searchBar setPlaceholder:@"Search for games"];
	[_searchBar setDelegate:self];
	
	// Remove search bar background
	for (id backgroundImage in _searchBar.subviews)
        if ([backgroundImage isKindOfClass:NSClassFromString(@"UISearchBarBackground")])
			[backgroundImage removeFromSuperview];
	
	// Add search bar to navigation bar
	UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:_searchBar];
	[self.navigationItem setRightBarButtonItem:searchBarItem];
	
	_results = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated{
	[_searchBar becomeFirstResponder];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark SearchBar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[_previousOperation cancel];
	NSString *query = [searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	[self requestSearchResultsWithQuery:query];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[_previousOperation cancel];
	NSString *query = [searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	[self requestSearchResultsWithQuery:query];
}

#pragma mark -
#pragma mark TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return _results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
	
	SearchResult *result = _results[indexPath.row];
	[cell.textLabel setText:result.title];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Networking

- (void)requestSearchResultsWithQuery:(NSString *)query{
	[_results removeAllObjects];
	
//	NSLog(@"Query: %@", query);
	
	NSString *url = [NSString stringWithFormat:@"http://www.giantbomb.com/api/search/?api_key=d92c258adb509ded409d28f4e51de2c83e297011&limit=20&field_list=id,name,platforms&resources=game&format=json&query=%@", query];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
//		NSLog(@"%@", JSON);
		
		for (NSDictionary *dictionary in JSON[@"results"]){
			SearchResult *result = [[SearchResult alloc] init];
			[result setTitle:dictionary[@"name"]];
			[result setIdentifier:dictionary[@"id"]];
			
			if (dictionary[@"platforms"] != [NSNull null]){
				for (NSDictionary *platform in dictionary[@"platforms"]){
					if ([platform[@"platform"][@"name"] isEqualToString:@"Xbox 360"] ||
						[platform[@"platform"][@"name"] isEqualToString:@"PlayStation 3"] ||
						[platform[@"platform"][@"name"] isEqualToString:@"PC"] ||
						[platform[@"platform"][@"name"] isEqualToString:@"Wii U"]){
						
						[_results addObject:result];
						break;
					}
				}
			}
			else{
				[_results addObject:result];
			}
		}
		
		[_tableView reloadData];
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Error: %@", self, response.statusCode, error.description);
		[_results removeAllObjects];
		[_tableView reloadData];
	}];
	
	[operation start];
	_previousOperation = operation;
}

#pragma mark -
#pragma mark Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	GameViewController *destination = segue.destinationViewController;
	[destination setSearchResult:_results[_tableView.indexPathForSelectedRow.row]];
}

@end
