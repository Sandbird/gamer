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

@interface SearchTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *localResults;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) AFJSONRequestOperation *previousOperation;

@end

@implementation SearchTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	// Search bar setup
	_searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 300, 44)];
	[_searchBar setPlaceholder:@"Find games"];
	[_searchBar setDelegate:self];
	
//	for(UIView *subView in _searchBar.subviews)
//		if([subView isKindOfClass: [UITextField class]])
//			[(UITextField *)subView setKeyboardAppearance:UIKeyboardAppearanceDark];
	
	[self.navigationItem setTitleView:_searchBar];
	
	_results = [[NSMutableArray alloc] initWithCapacity:100];
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
		NSString *query = [searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"];
		[self requestGamesWithTitlesContainingQuery:query];
		_localResults = [Game findAllSortedBy:@"title" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"ANY platforms IN %@ AND title CONTAINS[c] %@", [SessionManager gamer].platforms, query]];
		[self.tableView reloadData];
		
//		NSString *name = [searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"];
//		[self performSelector:@selector(requestGamesWithName:) withObject:name afterDelay:(searchText.length == 1) ? 0 : 1];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
	[_previousOperation cancel];
	NSString *query = [searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	[self requestGamesWithTitlesContainingQuery:query];
	_localResults = [Game findAllSortedBy:@"title" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"ANY platforms IN %@ AND title CONTAINS[c] %@", [SessionManager gamer].platforms, query]];
	[self.tableView reloadData];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
	[_searchBar setShowsSearchResultsButton:NO];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _localResults.count + _results.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return (indexPath.row < _localResults.count) ? 60 : tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	if (indexPath.row < _localResults.count){
		SearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
		[cell setSeparatorInset:UIEdgeInsetsMake(0, 63, 0, 0)];
		
		Game *game = _localResults[indexPath.row];
		[cell.coverImageView setImage:[UIImage imageWithData:game.wishlistThumbnail]];
		[cell.titleLabel setText:game.title];
		
		return cell;
	}
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	SearchResult *result = _results[indexPath.row - _localResults.count];
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

- (void)requestGamesWithTitlesContainingQuery:(NSString *)query{
//	NSArray *platforms = [Platform findAllWithPredicate:[NSPredicate predicateWithFormat:@"self in %@", [SessionManager gamer].platforms]];
	
	NSURLRequest *request = [SessionManager URLRequestForGamesWithFields:@"id,name" platforms:[SessionManager gamer].platforms.allObjects title:query];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		[_results removeAllObjects];
		
//		NSLog(@"%@", JSON);
		
		NSArray *localIdentifiers = [_localResults valueForKey:@"identifier"];
		
		for (NSDictionary *dictionary in JSON[@"results"]){
			SearchResult *result = [[SearchResult alloc] init];
			[result setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[result setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			if (![localIdentifiers containsObject:result.identifier]) [_results addObject:result];
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
	[destination setSearchResult:(self.tableView.indexPathForSelectedRow.row < _localResults.count) ? _localResults[self.tableView.indexPathForSelectedRow.row] : _results[self.tableView.indexPathForSelectedRow.row - _localResults.count]];
}

@end
