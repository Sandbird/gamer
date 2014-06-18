//
//  SearchController_iPad.m
//  Gamer
//
//  Created by Caio Mello on 01/11/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "SearchController_iPad.h"
#import "GameController.h"
#import "SearchResult.h"
#import "Platform.h"
#import "SearchCollectionCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface SearchController_iPad () <UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSTimer *searchTimer;

@property (nonatomic, strong) NSURLSessionDataTask *runningTask;

@end

@implementation SearchController_iPad

- (void)viewDidLoad{
    [super viewDidLoad];
	
	self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 256, 44)];
	[self.searchBar setPlaceholder:@"Find Games"];
	[self.searchBar setDelegate:self];
	UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
	
	[self.navigationItem setRightBarButtonItem:searchBarItem];
	
	[self.navigationItem setHidesBackButton:YES animated:NO];
	
	[self.searchBar setText:[Session searchQuery]];
	
	if ([Session searchResults])
		self.results = [Session searchResults].mutableCopy;
	else
		self.results = [[NSMutableArray alloc] initWithCapacity:100];
	
	// Add guide view to the view
	self.guideView = [[NSBundle mainBundle] loadNibNamed:@"iPad" owner:self options:nil][2];
	[self.view insertSubview:self.guideView aboveSubview:self.collectionView];
	[self.guideView setFrame:self.view.frame];
	[self.guideView setHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated{
	if ([Session gamer].platforms.count == 0){
		[self.guideView setHidden:NO];
		[self.searchBar setUserInteractionEnabled:NO];
	}
	else{
		[self.guideView setHidden:YES];
		[self.searchBar setUserInteractionEnabled:YES];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.searchBar becomeFirstResponder];
		});
	}
}

- (void)viewWillDisappear:(BOOL)animated{
	[self.runningTask cancel];
}

- (void)viewDidLayoutSubviews{
	[self.guideView setCenter:self.view.center];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	[self.collectionView performBatchUpdates:nil completion:nil];
}

#pragma mark - SearchBar

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
	[self.searchBar setShowsSearchResultsButton:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[self.runningTask cancel];
	
	[Session setSearchQuery:searchText];
	
	[self.searchTimer invalidate];
	
	if (searchText.length > 1){
		self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(delayedSearchWithTimer:) userInfo:searchText repeats:NO];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
	
	[self.runningTask cancel];
	
	[Session setSearchQuery:searchBar.text];
	
	[self searchGamesWithTitle:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
	[self.runningTask cancel];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
	[self.searchBar setShowsSearchResultsButton:NO];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return self.results.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout  *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
	return (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) ? CGSizeMake(369, 80) : CGSizeMake(328, 80);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	SearchResult *result = self.results[indexPath.row];
	
	SearchCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.titleLabel setText:result.title];
	[cell.coverImageView setImageWithURL:[NSURL URLWithString:result.imageURL] placeholderImage:[Tools imageWithColor:[UIColor darkGrayColor]]];
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self.searchBar resignFirstResponder];
	
	SearchResult *result = self.results[indexPath.row];
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
			NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			[self.results removeAllObjects];
			
			for (NSDictionary *dictionary in responseObject[@"results"]){
				SearchResult *result = [SearchResult new];
				[result setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
				[result setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				if (dictionary[@"image"] != [NSNull null]) [result setImageURL:[Tools stringFromSourceIfNotNull:dictionary[@"image"][@"thumb_url"]]];
				[self.results addObject:result];
			}
			
			[Session setSearchResults:self.results];
			
			[self.collectionView reloadData];
		}
	}];
	[dataTask resume];
	self.runningTask = dataTask;
}

#pragma mark - Custom

- (void)searchGamesWithTitle:(NSString *)title{
	NSCharacterSet *alphanumericCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"];
	NSString *query = [[title componentsSeparatedByCharactersInSet:[alphanumericCharacterSet invertedSet]] componentsJoinedByString:@"%"];
	[self requestGamesWithTitlesContainingQuery:query];
}

- (void)delayedSearchWithTimer:(NSTimer *)timer{
	[self searchGamesWithTitle:timer.userInfo];
}

#pragma mark - Actions

- (IBAction)cancelBarButtonAction:(UIBarButtonItem *)sender{
	[self.navigationController popViewControllerAnimated:NO];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		if ([Tools deviceIsiPad]){
			UINavigationController *navigationController = segue.destinationViewController;
			GameController *destination = (GameController *)navigationController.topViewController;
			[destination setGameIdentifier:sender];
		}
		else{
			// Pop other tabs when opening game details
			for (UIViewController *viewController in self.tabBarController.viewControllers){
				[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
			}
			
			GameController *destination = segue.destinationViewController;
			[destination setGameIdentifier:sender];
		}
	}
}

@end
