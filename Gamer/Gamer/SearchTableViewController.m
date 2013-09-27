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
#import <AFNetworking/AFNetworking.h>

@interface SearchTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *localResults;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSOperation *previousOperation;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation SearchTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	// Search bar setup
	_searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 300, 44)];
	[_searchBar setPlaceholder:@"Find games"];
	[_searchBar setDelegate:self];
	
	[self.navigationItem setTitleView:_searchBar];
	
	[self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
	
	_operationQueue = [[NSOperationQueue alloc] init];
	[_operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
	
	_results = [[NSMutableArray alloc] initWithCapacity:100];
}

- (void)viewWillAppear:(BOOL)animated{
	[_searchBar setText:@""];
	
	// Show guide view if no platform is selected
	if ((_localResults.count + _results.count == 0) && [SessionManager gamer].platforms.count == 0){
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
	[[SessionManager tracker] set:kGAIScreenName value:@"Search"];
	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated{
	[_previousOperation cancel];
	[_operationQueue cancelAllOperations];
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
		_localResults = [Game findAllSortedBy:@"title" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"title CONTAINS[c] %@", searchText]];
		[self.tableView reloadData];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
	
	[_previousOperation cancel];
	
	NSString *query = [searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	[self requestGamesWithTitlesContainingQuery:query];
	
	_localResults = [Game findAllSortedBy:@"title" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"title CONTAINS[c] %@", searchBar.text]];
	[self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
	[_previousOperation cancel];
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
	return (indexPath.row < _localResults.count) ? 70 : tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	BOOL lastRow = (indexPath.row == ([tableView numberOfRowsInSection:indexPath.section] - 1)) ? YES : NO;
	
	if (indexPath.row < _localResults.count){
		Game *game = _localResults[indexPath.row];
		
		SearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocalCell"];
		[cell.coverImageView setImage:[UIImage imageWithData:game.thumbnail]];
		[cell.titleLabel setText:game.title];
		[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
		[cell setSeparatorInset:UIEdgeInsetsMake(0, (lastRow ? (tableView.frame.size.width * 2) : 68), 0, 0)];
		
		return cell;
	}
	
	SearchResult *result = _results[indexPath.row - _localResults.count];
	
	SearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:result.title];
	[cell.coverImageView setImage:result.image];
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
	[cell setSeparatorInset:UIEdgeInsetsMake(0, (lastRow ? tableView.frame.size.width * 2 : 58), 0, 0)];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Networking

- (void)requestGamesWithTitlesContainingQuery:(NSString *)query{
	NSURLRequest *request = [SessionManager requestForGamesWithTitle:query fields:@"id,name,image" platforms:[SessionManager gamer].platforms.allObjects];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		[_results removeAllObjects];
		
//		NSLog(@"%@", JSON);
		
		NSArray *localIdentifiers = [_localResults valueForKey:@"identifier"];
		
		for (NSDictionary *dictionary in JSON[@"results"]){
			SearchResult *result = [[SearchResult alloc] init];
			[result setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[result setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			if (dictionary[@"image"] != [NSNull null]) [result setImageURL:[Tools stringFromSourceIfNotNull:dictionary[@"image"][@"icon_url"]]];
			[self downloadImageForSearchResult:result];
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

- (void)downloadImageForSearchResult:(SearchResult *)result{
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:result.imageURL]];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
		[result setImage:image];
		[self.tableView reloadData];
	}];
	[_operationQueue addOperation:operation];
}

#pragma mark - Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		// Pop other tabs when opening game details
		for (UIViewController *viewController in self.tabBarController.viewControllers){
			[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
		}
		
		GameTableViewController *destination = segue.destinationViewController;
		[destination setSearchResult:(self.tableView.indexPathForSelectedRow.row < _localResults.count) ? _localResults[self.tableView.indexPathForSelectedRow.row] : _results[self.tableView.indexPathForSelectedRow.row - _localResults.count]];
	}
}

@end
