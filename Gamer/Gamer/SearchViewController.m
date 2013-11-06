//
//  SearchViewController.m
//  Gamer
//
//  Created by Caio Mello on 01/11/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SearchViewController.h"
#import "GameTableViewController.h"
#import "SearchResult.h"
#import "Platform.h"
#import "SearchCollectionCell.h"
#import <AFNetworking/AFNetworking.h>

@interface SearchViewController () <UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSOperation *previousOperation;

@end

@implementation SearchViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	_searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 256, 44)];
//	[_searchBar setSearchBarStyle:UISearchBarStyleMinimal];
//	[[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor lightGrayColor]];
	[_searchBar setPlaceholder:@"Find Games"];
	[_searchBar setDelegate:self];
	UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:_searchBar];
	
	[self.navigationItem setRightBarButtonItem:searchBarItem];
	
	[self.navigationItem setHidesBackButton:YES animated:NO];
	
	[_searchBar setText:[SessionManager searchQuery]];
	
	if ([SessionManager searchResults])
		_results = [SessionManager searchResults].mutableCopy;
	else
		_results = [[NSMutableArray alloc] initWithCapacity:100];
	
	if ([SessionManager gamer].platforms.count == 0){
		[_guideView setHidden:NO];
		[_searchBar setUserInteractionEnabled:NO];
	}
	else{
		[_guideView setHidden:YES];
		[_searchBar setUserInteractionEnabled:YES];
		[_searchBar becomeFirstResponder];
	}
	
	// Add guide view to the view
	_guideView = [[NSBundle mainBundle] loadNibNamed:@"iPad" owner:self options:nil][2];
	[self.view insertSubview:_guideView aboveSubview:_collectionView];
	[_guideView setFrame:self.view.frame];
	[_guideView setHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] set:kGAIScreenName value:@"Search"];
	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated{
	[_previousOperation cancel];
}

- (void)viewDidLayoutSubviews{
	[_guideView setCenter:self.view.center];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	[self.collectionView performBatchUpdates:nil completion:nil];
}

#pragma mark - SearchBar

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
	[_searchBar setShowsSearchResultsButton:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[_previousOperation cancel];
	
	[SessionManager setSearchQuery:searchText];
	
	if (searchText.length > 0){
		NSString *query = [searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"];
		[self requestGamesWithTitlesContainingQuery:query];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
	
	[_previousOperation cancel];
	
	[SessionManager setSearchQuery:searchBar.text];
	
	NSString *query = [searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	[self requestGamesWithTitlesContainingQuery:query];
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

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return _results.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout  *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
	return (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) ? CGSizeMake(369, 80) : CGSizeMake(328, 80);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	SearchResult *result = _results[indexPath.row];
	
	SearchCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:result.title];
	[cell.coverImageView setImageWithURL:[NSURL URLWithString:result.imageURL] placeholderImage:[Tools imageWithColor:[UIColor darkGrayColor]]];
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	SearchResult *result = _results[indexPath.row];
	[self performSegueWithIdentifier:@"GameSegue" sender:result.identifier];
}

#pragma mark - Networking

- (void)requestGamesWithTitlesContainingQuery:(NSString *)query{
	NSURLRequest *request = [Networking requestForGamesWithTitle:query fields:@"id,name,image" platforms:[SessionManager gamer].platforms.allObjects];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		//		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		[_results removeAllObjects];
		
//		NSLog(@"%@", JSON);
		
		for (NSDictionary *dictionary in JSON[@"results"]){
			SearchResult *result = [[SearchResult alloc] init];
			[result setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[result setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			if (dictionary[@"image"] != [NSNull null]) [result setImageURL:[Tools stringFromSourceIfNotNull:dictionary[@"image"][@"thumb_url"]]];
			[_results addObject:result];
		}
		
		[SessionManager setSearchResults:_results];
		
		[_collectionView reloadData];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Error: %@", self, response.statusCode, error.description);
	}];
	[operation start];
	_previousOperation = operation;
}

#pragma mark - Actions

- (IBAction)cancelBarButtonAction:(UIBarButtonItem *)sender{
	[self.navigationController popViewControllerAnimated:NO];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		if ([Tools deviceIsiPad]){
			UINavigationController *navigationController = segue.destinationViewController;
			GameTableViewController *destination = (GameTableViewController *)navigationController.topViewController;
			[destination setGameIdentifier:sender];
		}
		else{
			// Pop other tabs when opening game details
			for (UIViewController *viewController in self.tabBarController.viewControllers){
				[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
			}
			
			GameTableViewController *destination = segue.destinationViewController;
			[destination setGameIdentifier:sender];
		}
	}
}

@end
