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
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface SearchViewController () <UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSURLSessionDataTask *runningTask;

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
	
	[_searchBar setText:[Session searchQuery]];
	
	if ([Session searchResults])
		_results = [Session searchResults].mutableCopy;
	else
		_results = [[NSMutableArray alloc] initWithCapacity:100];
	
	// Add guide view to the view
	_guideView = [[NSBundle mainBundle] loadNibNamed:@"iPad" owner:self options:nil][2];
	[self.view insertSubview:_guideView aboveSubview:_collectionView];
	[_guideView setFrame:self.view.frame];
	[_guideView setHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated{
	if ([Session gamer].platforms.count == 0){
		[_guideView setHidden:NO];
		[_searchBar setUserInteractionEnabled:NO];
	}
	else{
		[_guideView setHidden:YES];
		[_searchBar setUserInteractionEnabled:YES];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_searchBar becomeFirstResponder];
		});
	}
}

- (void)viewWillDisappear:(BOOL)animated{
	[_runningTask cancel];
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
	[_runningTask cancel];
	
	[Session setSearchQuery:searchText];
	
	if (searchText.length > 0){
		NSCharacterSet *alphanumericCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"];
		NSString *query = [[searchText componentsSeparatedByCharactersInSet:[alphanumericCharacterSet invertedSet]] componentsJoinedByString:@"%"];
		[self requestGamesWithTitlesContainingQuery:query];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
	
	[_runningTask cancel];
	
	[Session setSearchQuery:searchBar.text];
	
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
	[_searchBar resignFirstResponder];
	
	SearchResult *result = _results[indexPath.row];
	[self performSegueWithIdentifier:@"GameSegue" sender:result.identifier];
}

#pragma mark - Networking

- (void)requestGamesWithTitlesContainingQuery:(NSString *)query{
	NSURLRequest *request = [Networking requestForGamesWithTitle:query fields:@"id,name,image" platforms:[Session gamer].platforms.allObjects];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Error: %@", self, (long)((NSHTTPURLResponse *)response).statusCode, error.description);
		}
		else{
//			NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			[_results removeAllObjects];
			
			for (NSDictionary *dictionary in responseObject[@"results"]){
				SearchResult *result = [SearchResult new];
				[result setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
				[result setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				if (dictionary[@"image"] != [NSNull null]) [result setImageURL:[Tools stringFromSourceIfNotNull:dictionary[@"image"][@"thumb_url"]]];
				[_results addObject:result];
			}
			
			[Session setSearchResults:_results];
			
			[_collectionView reloadData];
		}
	}];
	[dataTask resume];
	_runningTask = dataTask;
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
