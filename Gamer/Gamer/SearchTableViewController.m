//
//  ReleaseSearchTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 4/22/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SearchTableViewController.h"
#import "GameTableViewController.h"
#import "SearchResult.h"
#import "SessionManager.h"
#import "ReleasesTableViewController.h"
#import "LibraryTableViewController.h"
#import "Platform.h"

@interface SearchTableViewController ()

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) AFJSONRequestOperation *previousOperation;

@end

@implementation SearchTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	// Search bar setup
	if (!_searchBar) _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 252, 44)];
	[_searchBar setPlaceholder:@"Search"];
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

- (void)viewDidAppear:(BOOL)animated{
	[_searchBar becomeFirstResponder];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - SearchBar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[_previousOperation cancel];
	if (searchText.length > 0) [self requestGamesWithName:[searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[_previousOperation cancel];
	[self requestGamesWithName:[searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	SearchResult *result = _results[indexPath.row];
	[cell.textLabel setText:result.title];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[_searchBar resignFirstResponder];
}

#pragma mark - Networking

- (void)requestGamesWithName:(NSString *)name{
	NSArray *platforms = [Platform findAllWithPredicate:[NSPredicate predicateWithFormat:@"favorite == %@", @(YES)]];
	
	NSURLRequest *request = [SessionManager URLRequestForGamesWithFields:@"id,name" platforms:platforms name:name];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		[_results removeAllObjects];
		
//		NSLog(@"%@", JSON);
		
		for (NSDictionary *dictionary in JSON[@"results"]){
			SearchResult *result;
			if (!result) result = [[SearchResult alloc] init];
			[result setIdentifier:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[result setTitle:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
			[_results addObject:result];
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
	[destination setOrigin:_origin];
}

@end
