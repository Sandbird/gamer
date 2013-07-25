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
#import "SessionManager.h"
#import "WishlistTableViewController.h"
#import "LibraryTableViewController.h"
#import "Platform.h"

@interface SearchTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) AFJSONRequestOperation *previousOperation;

@end

@implementation SearchTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIExtendedEdgeAll];
	
	// Search bar setup
	if (!_searchBar) _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 300, 44)];
	[_searchBar setPlaceholder:@"Search"];
	[_searchBar setDelegate:self];
	
	for(UIView *subView in _searchBar.subviews)
		if([subView isKindOfClass: [UITextField class]])
			[(UITextField *)subView setKeyboardAppearance:UIKeyboardAppearanceDark];
	
	[self.navigationItem setTitleView:_searchBar];
	
	if (!_results) _results = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] sendView:@"Search"];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - SearchBar

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
	[_searchBar setShowsSearchResultsButton:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[_previousOperation cancel];
	if (searchText.length > 0){
		[self requestGamesWithName:[searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
//		NSString *name = [searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"];
//		[self performSelector:@selector(requestGamesWithName:) withObject:name afterDelay:(searchText.length == 1) ? 0 : 1];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
	[_previousOperation cancel];
	[self requestGamesWithName:[searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell setBackgroundColor:[UIColor colorWithRed:.125490196 green:.125490196 blue:.125490196 alpha:1]];
	[cell.textLabel setTextColor:[UIColor lightGrayColor]];
	
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
	NSArray *platforms = [Platform findAllWithPredicate:[NSPredicate predicateWithFormat:@"favorite = %@", @(YES)]];
	
	NSURLRequest *request = [SessionManager URLRequestForGamesWithFields:@"id,name" platforms:platforms name:name];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		[_results removeAllObjects];
		
//		NSLog(@"%@", JSON);
		
		for (NSDictionary *dictionary in JSON[@"results"]){
			SearchResult *result;
			if (!result) result = [[SearchResult alloc] init];
			[result setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[result setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
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
//	[destination setOrigin:_origin];
}

@end
