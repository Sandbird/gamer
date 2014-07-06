//
//  GameController.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "GameController.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "Image.h"
#import "Video.h"
#import "ReleasePeriod.h"
#import "SimilarGame.h"
#import "Release.h"
#import "Region.h"
#import "Metascore.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ImageCollectionCell.h"
#import "VideoCollectionCell.h"
#import "ImageViewerController.h"
#import "PlatformCollectionCell.h"
#import "ContentStatusView.h"
#import "MetacriticController.h"
#import "VideoPlayerController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "SimilarGameCollectionCell.h"
#import "PlatformPickerController.h"
#import "ReleasesController.h"
#import "StarRatingControl.h"
#import "MetascoreController.h"
#import "NotesController.h"
#import "DACircularProgressView+AFNetworking.h"

typedef NS_ENUM(NSInteger, Section){
	SectionCover,
	SectionStatus,
	SectionDetails,
	SectionImages,
	SectionVideos
};

@interface GameController () <UICollectionViewDataSource, UICollectionViewDelegate, PlatformPickerControllerDelegate, ReleasesControllerDelegate, MetascoreControllerDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet DACircularProgressView *progressView;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

@property (nonatomic, strong) IBOutlet UILabel *releaseDateLabel;
@property (nonatomic, strong) IBOutlet UIButton *wishlistButton;
@property (nonatomic, strong) IBOutlet UIButton *libraryButton;
@property (nonatomic, strong) IBOutlet UIButton *editPlatformsButton;

@property (nonatomic, strong) IBOutlet UILabel *releasesLabel;

@property (nonatomic, strong) IBOutlet UICollectionView *selectedPlatformsCollectionView;

@property (nonatomic, strong) IBOutlet UISwitch *preorderedSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *finishedSwitch;
@property (nonatomic, strong) IBOutlet UISegmentedControl *retailDigitalSegmentedControl;
@property (nonatomic, strong) IBOutlet UISegmentedControl *lentBorrowedSegmentedControl;
@property (nonatomic, strong) IBOutlet UIView *ratingView;
@property (nonatomic, strong) StarRatingControl *ratingControl;

@property (nonatomic, strong) IBOutlet UITextView *descriptionTextView;

@property (nonatomic, strong) IBOutlet UILabel *genreFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreSecondLabel;
@property (nonatomic, strong) IBOutlet UILabel *themeFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *themeSecondLabel;
@property (nonatomic, strong) IBOutlet UILabel *developerFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *developerSecondLabel;
@property (nonatomic, strong) IBOutlet UILabel *publisherFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *publisherSecondLabel;
@property (nonatomic, strong) IBOutlet UILabel *franchiseLabel;
@property (nonatomic, strong) IBOutlet UILabel *franchiseTitleLabel;

@property (nonatomic, strong) IBOutlet UICollectionView *platformsCollectionView;

@property (nonatomic, strong) IBOutlet UILabel *criticScoreLabel;
@property (nonatomic, strong) IBOutlet UILabel *userScoreLabel;
@property (nonatomic, strong) IBOutlet UILabel *metascorePlatformLabel;

@property (nonatomic, strong) IBOutlet UICollectionView *similarGamesCollectionView;

@property (nonatomic, strong) IBOutlet UICollectionView *imagesCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *videosCollectionView;

@property (nonatomic, strong) ContentStatusView *imagesStatusView;
@property (nonatomic, strong) ContentStatusView *videosStatusView;

@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) NSArray *selectedPlatforms;
@property (nonatomic, strong) NSArray *selectablePlatforms;
@property (nonatomic, strong) NSArray *platforms;
@property (nonatomic, strong) NSArray *similarGames;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSArray *videos;

@property (nonatomic, strong) UITapGestureRecognizer *dismissTapGesture;

@end

@implementation GameController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	[self.wishlistButton.layer setBorderWidth:1];
	[self.wishlistButton.layer setBorderColor:self.wishlistButton.tintColor.CGColor];
	[self.wishlistButton.layer setCornerRadius:4];
	[self.wishlistButton setBackgroundImage:[Tools imageWithColor:self.wishlistButton.tintColor] forState:UIControlStateHighlighted];
	
	[self.libraryButton.layer setBorderWidth:1];
	[self.libraryButton.layer setBorderColor:self.libraryButton.tintColor.CGColor];
	[self.libraryButton.layer setCornerRadius:4];
	[self.libraryButton setBackgroundImage:[Tools imageWithColor:self.libraryButton.tintColor] forState:UIControlStateHighlighted];
	
	[self.userScoreLabel.layer setCornerRadius:60/2];
	
	[self.progressView setTrackTintColor:[UIColor darkGrayColor]];
	[self.progressView setProgressTintColor:[UIColor whiteColor]];
	[self.progressView setThicknessRatio:0.2];
	
	[self setupRatingControl];
	
	[self.refreshControl setTintColor:[UIColor lightGrayColor]];
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	self.imagesStatusView = [[ContentStatusView alloc] initWithUnavailableTitle:@"No images available"];
	self.videosStatusView = [[ContentStatusView alloc] initWithUnavailableTitle:@"No videos available"];
	[self.imagesCollectionView addSubview:self.imagesStatusView];
	[self.videosCollectionView addSubview:self.videosStatusView];
	
	if (!self.game)
		self.game = [Game MR_findFirstByAttribute:@"identifier" withValue:self.gameIdentifier inContext:self.context];
	
	if (self.game){
		[self refreshAnimated:NO];
	}
	else{
		[self requestGameWithIdentifier:self.gameIdentifier];
	}
	
	[self.similarGamesCollectionView setScrollsToTop:NO];
	[self.imagesCollectionView setScrollsToTop:NO];
	[self.videosCollectionView setScrollsToTop:NO];
}

- (void)viewDidLayoutSubviews{
	[self.imagesStatusView setFrame:self.imagesCollectionView.frame];
	[self.videosStatusView setFrame:self.videosCollectionView.frame];
}

- (void)viewWillAppear:(BOOL)animated{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
	
	[self.wishlistButton setHighlighted:NO];
	[self.libraryButton setHighlighted:NO];
}

- (void)viewDidAppear:(BOOL)animated{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
	
	if ([Tools deviceIsiPad]){
		self.dismissTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTapGestureAction:)];
		[self.dismissTapGesture setNumberOfTapsRequired:1];
		[self.dismissTapGesture setCancelsTouchesInView:NO];
		[self.view.window addGestureRecognizer:self.dismissTapGesture];
	}
	
	[self.refreshControl endRefreshing];
}

- (void)viewWillDisappear:(BOOL)animated{
	[self.view.window removeGestureRecognizer:self.dismissTapGesture];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	if (self.game){
		[tableView setSeparatorColor:[UIColor darkGrayColor]];
		return [super numberOfSectionsInTableView:tableView];
	}
	else{
		[tableView setSeparatorColor:[UIColor clearColor]];
		return 0;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
	if (section == SectionStatus && [self.game.location isEqualToNumber:@(GameLocationNone)])
		return 0;
	return [super tableView:tableView heightForHeaderInSection:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case SectionCover:
			if ([self.game.location isEqualToNumber:@(GameLocationNone)]){
				if (self.game.releases.count > 0){
					return 3;
				}
				else
					return 2;
			}
			else if (self.selectedPlatforms.count > 0){
				if (self.game.releases.count > 0){
					return 4;
				}
				else
					return 3;
			}
			else{
				return 2;
			}
			break;
		case SectionStatus:
			if ([self.game.location isEqualToNumber:@(GameLocationWishlist)])
				return [self.game.released isEqualToNumber:@(YES)] ? 1 : 2;
			else if ([self.game.location isEqualToNumber:@(GameLocationLibrary)])
				return 5;
			else
				return 0;
			break;
		case SectionDetails:
			return (self.game.metascores.count > 0) + (self.game.platforms.count > 0) + (self.game.similarGames.count > 0) + 2;
			break;
		default:
			break;
	}
	
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case SectionCover:
			if (indexPath.row == 2){
				if (self.game.releases.count > 0)
					return [super tableView:tableView heightForRowAtIndexPath:indexPath];
				else{
					if ([Tools deviceIsiPhone])
						return 20 + 17 + 8 + (ceil((double)self.selectedPlatforms.count/4) * 31) + 20;
					else
						return 20 + 17 + 8 + (ceil((double)self.selectedPlatforms.count/8) * 31) + 20;
				}
			}
			else if (indexPath.row == 3){
				if ([Tools deviceIsiPhone])
					return 20 + 17 + 8 + (ceil((double)self.selectedPlatforms.count/4) * 31) + 20;
				else
					return 20 + 17 + 8 + (ceil((double)self.selectedPlatforms.count/8) * 31) + 20;
			}
			break;
		case SectionStatus:
			// Notes row
			if (([self.game.location isEqualToNumber:@(GameLocationWishlist)] && [self.game.released isEqualToNumber:@(NO)] && indexPath.row == 1) || ([self.game.location isEqualToNumber:@(GameLocationWishlist)] && [self.game.released isEqualToNumber:@(YES)] && indexPath.row == 0) || ([self.game.location isEqualToNumber:@(GameLocationLibrary)] && indexPath.row == 4)){
				return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:SectionStatus]];
			}
			break;
		case SectionDetails:{
			switch (indexPath.row) {
				// Description row
				case 0:{
					CGRect textRect = [self.game.overview boundingRectWithSize:CGSizeMake(self.descriptionTextView.frame.size.width - 10, 50000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil];
					return 20 + textRect.size.height + 20; // Top padding + description text height + bottom padding
				}
				// Info row
				case 1:{
					if ([Tools deviceIsiPhone]){
						CGFloat contentHeight = 0;
						contentHeight += self.game.genres.count > 1 ? 57 : 37; // Labels' height
						contentHeight += 13; // Spacing
						contentHeight += self.game.themes.count > 1 ? 57 : 37; // Labels' height
						contentHeight += 13; // Spacing
						contentHeight += self.game.developers.count > 1 ? 57 : 37; // Labels' height
						contentHeight += 13; // Spacing
						contentHeight += self.game.publishers.count > 1 ? 57 : 37; // Labels' height
						contentHeight += 13; // Spacing
						contentHeight += self.game.franchises.count > 0 ? (13 + 37) : 0; // Extra spacing + labels' height
						return 20 + contentHeight + 20; // Top padding + content height + bottom padding
					}
					else{
						CGFloat leftColumn = 0;
						CGFloat rightColumn = 0;
						
						leftColumn += self.game.genres.count > 1 ? 57 : 37; // Labels' height
						leftColumn += 13; // Spacing
						leftColumn += self.game.themes.count > 1 ? 57 : 37; // Labels' height
						leftColumn += 13; // Spacing
						leftColumn += self.game.franchises.count > 0 ? 37 : 0; // Labels' height
						
						rightColumn += self.game.developers.count > 1 ? 57 : 37; // Labels' height
						rightColumn += 13; // Spacing
						rightColumn += self.game.publishers.count > 1 ? 57 : 37; // Labels' height
						rightColumn += 13; // Spacing
						
						return 20 + fmaxf(leftColumn, rightColumn) + 20; // Top padding + highest column height + bottom padding
					}
					break;
				}
				// Platforms row
				case 2:
					// Similar games row
					if (self.game.platforms.count == 0 && self.game.metascores.count == 0){
						return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:SectionDetails]];
					}
					// Metascore row
					else if (self.game.platforms.count == 0){
						return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:SectionDetails]];
					}
					// Platforms row
					else if (self.platforms.count > 0){
						if ([Tools deviceIsiPhone])
							return 20 + 17 + 8 + (ceil((double)self.platforms.count/4) * 31) + 20; // Top padding + label height + spacing + platforms collection height + bottom padding
						else
							return 20 + 17 + 8 + (ceil((double)self.platforms.count/8) * 31) + 20;
					}
					break;
				case 3:
					if ((self.game.platforms.count == 0 && self.game.metascores.count > 0) || (self.game.platforms.count > 0 && self.game.metascores.count == 0)){
						return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:SectionDetails]];
					}
					break;
				default:
					break;
			}
			break;
		}
		default:
			break;
	}
	
	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case SectionCover:
			if (indexPath.row == 2 && self.game.releases.count == 0 && self.selectedPlatforms.count > 0)
				return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:SectionCover]];
			break;
		case SectionStatus:
			if ([self.game.location isEqualToNumber:@(GameLocationWishlist)]){
				if (([self.game.released isEqualToNumber:@(YES)] && indexPath.row == 0) || ([self.game.released isEqualToNumber:@(NO)] && indexPath.row == 1))
					return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:SectionStatus]];
			}
			else
				return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:SectionStatus]];
			break;
		case SectionDetails:
			if (indexPath.row == 2){
				if (self.game.platforms.count == 0 && self.game.metascores.count == 0){
					// Similar games row
					return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:SectionDetails]];
				}
				else if (self.game.platforms.count == 0){
					// Metascore row
					return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:SectionDetails]];
				}
			}
			else if (indexPath.row == 3){
				if ((self.game.platforms.count == 0 && self.game.metascores.count > 0) || (self.game.platforms.count > 0 && self.game.metascores.count == 0)){
					// Similar games row
					return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:SectionDetails]];
				}
			}
			break;
		default:
			break;
	}
	
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
	if (indexPath.section == SectionVideos) [cell setSeparatorInset:UIEdgeInsetsMake(0, self.tableView.frame.size.width * 2, 0, 0)];
	
	if (indexPath.section == SectionImages){
		if (self.game.images.count == 0 && self.game.videos.count == 0){
			[self requestMediaWithGame:self.game];
			
			if (self.game.similarGames.count == 0){
				[self requestSimilarGamesWithGame:self.game];
			}
		}
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case SectionCover:
			if (indexPath.row == 2 && self.game.releases.count > 0)
				[self performSegueWithIdentifier:@"ReleasesSegue" sender:nil];
			break;
		case SectionStatus:
			if (indexPath.row == ([tableView numberOfRowsInSection:SectionStatus] - 1)){
				[self performSegueWithIdentifier:@"NotesSegue" sender:nil];
			}
			break;
		case SectionDetails:
			if (indexPath.row == 2 && self.game.platforms.count == 0 && self.game.metascores.count > 0){
				[self performSegueWithIdentifier:@"MetascoreSegue" sender:nil];
			}
			else if (indexPath.row == 3 && self.game.platforms.count > 0 && self.game.metascores.count > 0){
				[self performSegueWithIdentifier:@"MetascoreSegue" sender:nil];
			}
			break;
		default:
			break;
	}
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	if (collectionView == self.selectedPlatformsCollectionView)
		return self.selectedPlatforms.count;
	else if (collectionView == self.platformsCollectionView)
		return self.platforms.count;
	else if (collectionView == self.similarGamesCollectionView)
		return self.similarGames.count;
	else if (collectionView == self.imagesCollectionView){
		[collectionView setBounces:(self.images.count == 0) ? NO : YES];
		return self.images.count;
	}
	else{
		[collectionView setBounces:(self.videos.count == 0) ? NO : YES];
		return self.videos.count;
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	if (collectionView == self.selectedPlatformsCollectionView){
		Platform *platform = self.selectedPlatforms[indexPath.item];
		PlatformCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		[cell.platformLabel setText:platform.abbreviation];
		[cell.platformLabel setBackgroundColor:platform.color];
		return cell;
	}
	else if (collectionView == self.platformsCollectionView){
		Platform *platform = self.platforms[indexPath.item];
		PlatformCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		[cell.platformLabel setText:platform.abbreviation];
		[cell.platformLabel setBackgroundColor:platform.color];
		return cell;
	}
	else if (collectionView == self.similarGamesCollectionView){
		SimilarGame *similarGame = self.similarGames[indexPath.row];
		SimilarGameCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		[cell.coverImageView setImageWithURL:[NSURL URLWithString:similarGame.imageURL] placeholderImage:[Tools imageWithColor:[UIColor darkGrayColor]]];
		return cell;
	}
	else if (collectionView == self.imagesCollectionView){
		ImageCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		Image *image = self.images[indexPath.item];
		
		// Download thumbnail
		[cell.activityIndicator startAnimating];
		__weak ImageCollectionCell *cellReference = cell;
		[cell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:image.thumbnailURL]] placeholderImage:[Tools imageWithColor:[UIColor blackColor]] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
			[cellReference.activityIndicator stopAnimating];
			[cellReference.imageView setImage:image];
			[cellReference.imageView.layer addAnimation:[Tools transitionWithType:kCATransitionFade duration:0.2 timingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]] forKey:nil];
		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
			[cellReference.activityIndicator stopAnimating];
		}];
		
		return cell;
	}
	else{
		Video *video = self.videos[indexPath.item];
		
		VideoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		[cell.titleLabel setText:nil];
		[cell.lengthLabel setText:nil];
		[cell.imageView setImage:nil];
		
		[cell.titleLabel setText:[video.title isEqualToString:@"(null)"] ? nil : video.title];
		[cell.lengthLabel setText:[Tools formattedStringForLength:video.length.integerValue]];
		
		// Download thumbnail
		[cell.activityIndicator startAnimating];
		__weak VideoCollectionCell *cellReference = cell;
		[cell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:video.imageURL]] placeholderImage:[Tools imageWithColor:[UIColor blackColor]] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
			[cellReference.activityIndicator stopAnimating];
			[cellReference.imageView setImage:image];
			[cellReference.imageView.layer addAnimation:[Tools transitionWithType:kCATransitionFade duration:0.2 timingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]] forKey:nil];
		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
			[cellReference.activityIndicator stopAnimating];
		}];
		
		return cell;
	}
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	if (collectionView == self.imagesCollectionView){
		Image *image = self.images[indexPath.item];
		[self performSegueWithIdentifier:@"ImageViewerSegue" sender:image];
	}
	else if (collectionView == self.similarGamesCollectionView){
		SimilarGame *similarGame = self.similarGames[indexPath.item];
		[self performSegueWithIdentifier:@"SimilarGameSegue" sender:similarGame.identifier];
	}
	else if (collectionView == self.videosCollectionView){
		Video *video = self.videos[indexPath.item];
		if (video.highQualityURL){
			// Regular player if iPad. Rotation locked player if iPhone.
			if ([Tools deviceIsiPad]){
				MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:video.highQualityURL]];
				[self presentMoviePlayerViewControllerAnimated:player];
			}
			else{
				VideoPlayerController *player = [[VideoPlayerController alloc] initWithContentURL:[NSURL URLWithString:video.highQualityURL]];
				[self presentMoviePlayerViewControllerAnimated:player];
			}
		}
	}
}

#pragma mark - Networking

- (void)requestGameWithIdentifier:(NSNumber *)identifier{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes,images,videos,releases"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Game", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			[self.navigationItem.rightBarButtonItem setEnabled:YES];
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Game - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				self.game = [Game MR_findFirstByAttribute:@"identifier" withValue:identifier inContext:self.context];
				if (!self.game) self.game = [Game MR_createInContext:self.context];
				
				[Networking updateGame:self.game withResults:responseObject[@"results"] context:self.context];
				
				[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					// Refresh UI
					[self refreshAnimated:NO];
					[self.tableView reloadData];
					
					// Cover image download
					NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
					UIImage *coverImage = [UIImage imageWithContentsOfFile:self.game.imagePath];
					if (!coverImage || !self.game.imagePath || ![self.game.imageURL isEqualToString:coverImageURL]){
						[self downloadCoverImageWithURL:coverImageURL];
					}
					
					// Download releases
					[self requestReleasesWithGame:self.game];
					
					// Download similar games
					[self requestSimilarGamesWithGame:self.game];
					
					// Download videos
					[self requestVideosWithGame:self.game];
					
					// Download Metascore
					if (self.game.selectedMetascore){
						[self requestMetascoreForGame:self.game platform:self.game.selectedMetascore.platform];
					}
					else if (self.selectablePlatforms.count > 0 && [self.game.releasePeriod.identifier compare:@(3)] <= NSOrderedSame){
						[self requestMetascoreForGame:self.game platform:self.selectablePlatforms.firstObject];
					}
				}];
			}
		}
		
		[self.refreshControl endRefreshing];
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}];
	[dataTask resume];
}

- (void)downloadCoverImageWithURL:(NSString *)URLString{
	if (!URLString) return;
	
	[self.progressView setHidden:NO];
	[self.progressView.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
	
	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [Tools imagesDirectory], request.URL.lastPathComponent]];
		return fileURL;
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Cover Image", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Cover Image - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			[self.game setImagePath:[NSString stringWithFormat:@"%@/%@", [Tools imagesDirectory], request.URL.lastPathComponent]];
			[self.game setImageURL:URLString];
			
			[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"CoverImageDownloaded" object:nil];
				[self displayCoverImage];
			}];
		}
		
		[self.progressView setHidden:YES];
		[self.progressView.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	}];
	[self.progressView setProgressWithDownloadProgressOfTask:downloadTask animated:YES];
	[downloadTask resume];
}

- (void)requestReleasesWithGame:(Game *)game{
	NSURLRequest *request = [Networking requestForReleasesWithGameIdentifier:game.identifier fields:@"id,name,platform,region,release_date,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Releases", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Releases - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				for (NSDictionary *dictionary in responseObject[@"results"]){
					NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
					Release *release = [game.releases.allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]].firstObject;
					
					[Networking updateRelease:release withResults:dictionary context:self.context];
					
					if (!game.selectedRelease){
						for (Release *release in game.releases){
							NSArray *reversedIndexSelectablePlatforms = [[self.selectablePlatforms reverseObjectEnumerator] allObjects];
							
							// If game not added, release region is selected region, release platform is in selectable platforms
							if (release.region == [Session gamer].region && [reversedIndexSelectablePlatforms containsObject:release.platform]){
								[game setSelectedRelease:release];
								[game setReleasePeriod:[Networking releasePeriodForGameOrRelease:release context:self.context]];
							}
						}
					}
				}
				
				[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					[self.releaseDateLabel setText:self.game.selectedRelease ? self.game.selectedRelease.releaseDateText : self.game.releaseDateText];
					[self.releasesLabel setText:[NSString stringWithFormat:self.game.releases.count > 1 ? @"%lu Releases" : @"%lu Release", (unsigned long)self.game.releases.count]];
					
					[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionCover] withRowAnimation:UITableViewRowAnimationAutomatic];
					[self.tableView beginUpdates];
					[self.tableView endUpdates];
				}];
			}
		}
	}];
	[dataTask resume];
}

- (void)requestSimilarGamesWithGame:(Game *)game{
	NSArray *identifiers = [game.similarGames.allObjects valueForKey:@"identifier"];
	
	NSURLRequest *request = [Networking requestForGamesWithIdentifiers:identifiers fields:@"id,image"];
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Similar Games", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Similar Games - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				for (NSDictionary *dictionary in responseObject[@"results"]){
					NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
					SimilarGame *similarGame = [game.similarGames.allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]].firstObject;
					
					if (dictionary[@"image"] != [NSNull null]){
						[similarGame setImageURL:[Tools stringFromSourceIfNotNull:dictionary[@"image"][@"thumb_url"]]];
					}
				}
				
				[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					self.similarGames = [self orderedSimilarGamesFromGame:game];
					[self.similarGamesCollectionView setContentOffset:CGPointZero animated:NO];
					[self.similarGamesCollectionView reloadData];
					
					[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionDetails] withRowAnimation:UITableViewRowAnimationAutomatic];
					[self.tableView beginUpdates];
					[self.tableView endUpdates];
				}];
			}
		}
	}];
	[dataTask resume];
}

- (void)requestMediaWithGame:(Game *)game{
	[self.imagesStatusView setStatus:ContentStatusLoading];
	[self.videosStatusView setStatus:ContentStatusLoading];
	
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"similar_games,images,videos"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Media", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Media - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				NSDictionary *results = responseObject[@"results"];
				
				// Similar games
				if (results[@"similar_games"] != [NSNull null]){
					for (NSDictionary *dictionary in results[@"similar_games"]){
						SimilarGame *similarGame = [SimilarGame MR_findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:self.context];
						if (!similarGame) similarGame = [SimilarGame MR_createInContext:self.context];
						[similarGame setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
						[similarGame setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
						[game addSimilarGamesObject:similarGame];
					}
				}
				
				// Images
				if (results[@"images"] != [NSNull null]){
					NSInteger index = 0;
					for (NSDictionary *dictionary in results[@"images"]){
						NSString *stringURL = [Tools stringFromSourceIfNotNull:dictionary[@"super_url"]];
						Image *image = [Image MR_findFirstByAttribute:@"thumbnailURL" withValue:stringURL inContext:self.context];
						if (!image) image = [Image MR_createInContext:self.context];
						[image setThumbnailURL:stringURL];
						[image setOriginalURL:[stringURL stringByReplacingOccurrencesOfString:@"scale_large" withString:@"original"]];
						[image setIndex:@(index)];
						[game addImagesObject:image];
						
						index++;
					}
				}
				
				// Videos
				if (results[@"videos"] != [NSNull null]){
					NSInteger index = 0;
					for (NSDictionary *dictionary in results[@"videos"]){
						NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
						Video *video = [Video MR_findFirstByAttribute:@"identifier" withValue:identifier inContext:self.context];
						if (!video) video = [Video MR_createInContext:self.context];
						[video setIdentifier:identifier];
						[video setIndex:@(index)];
						[video setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"title"]]];
						[game addVideosObject:video];
						
						index++;
					}
				}
				
				[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					self.images = [self orderedImagesFromGame:game];
					[self.imagesCollectionView setContentOffset:CGPointZero animated:NO];
					[self.imagesCollectionView reloadData];
					(self.images.count == 0) ? [self.imagesStatusView setStatus:ContentStatusUnavailable] : [self.imagesStatusView setHidden:YES];
					
					[self requestSimilarGamesWithGame:game];
					[self requestVideosWithGame:game];
				}];
			}
		}
	}];
	[dataTask resume];
}

- (void)requestVideosWithGame:(Game *)game{
	NSArray *identifiers = [game.videos.allObjects valueForKey:@"identifier"];
	
	NSURLRequest *request = [Networking requestForVideosWithIdentifiers:identifiers fields:@"id,name,deck,video_type,length_seconds,publish_date,high_url,low_url,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Videos", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Videos - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			//					NSLog(@"%@", responseObject);
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
				for (NSDictionary *dictionary in responseObject[@"results"]){
					NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
					Video *video = [game.videos.allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]].firstObject;
					
					[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
					
					// Update video
					[video setType:[Tools stringFromSourceIfNotNull:dictionary[@"video_type"]]];
					[video setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
					[video setOverview:[Tools stringFromSourceIfNotNull:dictionary[@"deck"]]];
					[video setLength:[Tools integerNumberFromSourceIfNotNull:dictionary[@"length_seconds"]]];
					[video setPublishDate:[[Tools dateFormatter] dateFromString:dictionary[@"publish_date"]]];
					[video setHighQualityURL:[Tools stringFromSourceIfNotNull:dictionary[@"high_url"]]];
					[video setLowQualityURL:[Tools stringFromSourceIfNotNull:dictionary[@"low_url"]]];
					[video setImageURL:[Tools stringFromSourceIfNotNull:dictionary[@"image"][@"super_url"]]];
				}
				
				[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					self.videos = [self orderedVideosFromGame:game];
					[self.videosCollectionView setContentOffset:CGPointZero animated:NO];
					[self.videosCollectionView reloadData];
					(self.videos.count == 0) ? [self.videosStatusView setStatus:ContentStatusUnavailable] : [self.videosStatusView setHidden:YES];
				}];
			}
		}
	}];
	[dataTask resume];
}

- (void)requestMetascoreForGame:(Game *)game platform:(Platform *)platform{
	NSURLRequest *request = [Networking requestForMetascoreWithGame:game platform:platform];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Metascore", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Metascore - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			if ([responseObject[@"result"] isKindOfClass:[NSNumber class]])
				return;
			
			NSDictionary *results = responseObject[@"result"];
			
			NSString *metacriticURL = [Tools stringFromSourceIfNotNull:results[@"url"]];
			
			Metascore *metascore = [Metascore MR_findFirstByAttribute:@"metacriticURL" withValue:metacriticURL inContext:self.context];
			if (!metascore) metascore = [Metascore MR_createInContext:self.context];
			[metascore setCriticScore:[Tools integerNumberFromSourceIfNotNull:results[@"score"]]];
			[metascore setUserScore:[Tools decimalNumberFromSourceIfNotNull:results[@"userscore"]]];
			[metascore setMetacriticURL:metacriticURL];
			[metascore setPlatform:platform];
			[game addMetascoresObject:metascore];
			[game setSelectedMetascore:metascore];
			
			[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[self refreshMetascore];
				
				[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionDetails] withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView beginUpdates];
				[self.tableView endUpdates];
			}];
		}
	}];
	[dataTask resume];
}

#pragma mark - PlatformPicker

- (void)platformPicker:(PlatformPickerController *)picker didSelectPlatforms:(NSArray *)platforms{
	if (!platforms || platforms.count == 0){
		[self removeGameFromWishlistOrLibrary];
	}
	else{
		if (self.wishlistButton.isHighlighted){
			[self addGameToWishlistWithPlatforms:platforms];
		}
		else if (self.libraryButton.isHighlighted){
			[self addGameToLibraryWithPlatforms:platforms];
		}
		else{
			[self changeSelectedPlatformsToPlatforms:platforms];
		}
	}
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ReleasesController

- (void)releasesController:(ReleasesController *)controller didSelectRelease:(Release *)release{
	[self.game setSelectedRelease:release];
	[self.game setReleasePeriod:[Networking releasePeriodForGameOrRelease:release context:self.context]];
	[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[self.releaseDateLabel setText:self.game.selectedRelease ? self.game.selectedRelease.releaseDateText : self.game.releaseDateText];
	}];
}

#pragma mark - MetascoreController

- (void)metascoreController:(MetascoreController *)controller didSelectMetascore:(Metascore *)metascore{
	[self.game setSelectedMetascore:metascore];
	[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[self refreshMetascore];
	}];
}

#pragma mark - Custom

- (void)displayCoverImage{
	__block UIImage *image = [UIImage imageWithContentsOfFile:self.game.imagePath];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		CGSize imageSize = image.size.width > image.size.height ? [Tools sizeOfImage:image aspectFitToWidth:self.coverImageView.frame.size.width] : [Tools sizeOfImage:image aspectFitToHeight:self.coverImageView.frame.size.height];
		
		UIGraphicsBeginImageContext(imageSize);
		[image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.coverImageView setImage:image];
			[self.coverImageView.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
			[Tools addDropShadowToView:self.coverImageView color:[UIColor blackColor] opacity:1 radius:10 offset:CGSizeMake(0, 5) bounds:[Tools frameForImageInImageView:self.coverImageView]];
		});
	});
}

- (void)refreshAnimated:(BOOL)animated{
	[self displayCoverImage];
	
	[self.titleLabel setText:self.game.title];
	
	[self.releaseDateLabel setText:self.game.selectedRelease ? self.game.selectedRelease.releaseDateText : self.game.releaseDateText];
	
	[self.releasesLabel setText:[NSString stringWithFormat:self.game.releases.count > 1 ? @"%lu Releases" : @"%lu Release", (unsigned long)self.game.releases.count]];
	
	self.selectablePlatforms = [self selectablePlatformsFromGame:self.game];
	
	self.selectedPlatforms = [self orderedSelectedPlatformsFromGame:self.game];
	
	self.platforms = [self orderedPlatformsFromGame:self.game];
	
	self.similarGames = [self orderedSimilarGamesFromGame:self.game];
	
	[self.editPlatformsButton setHidden:([self.game.location isEqualToNumber:@(GameLocationNone)] || self.selectablePlatforms.count <= 1) ? YES : NO];
	
	[self refreshAddButtonsAnimated:animated];
	
	[self.platformsCollectionView reloadData];
	
	[self.similarGamesCollectionView setContentOffset:CGPointZero animated:NO];
	[self.similarGamesCollectionView reloadData];
	
	// Set status switches' position
	[self.preorderedSwitch setOn:self.game.preordered.boolValue animated:animated];
	[self.finishedSwitch setOn:self.game.finished.boolValue animated:animated];
	
	// Set retailDigitalSegmentedControl selection
	if ([self.game.digital isEqualToNumber:@(YES)]){
		[self.retailDigitalSegmentedControl setSelectedSegmentIndex:1];
		[self.lentBorrowedSegmentedControl setSelectedSegmentIndex:0];
	}
	else{
		[self.retailDigitalSegmentedControl setSelectedSegmentIndex:0];
	}
	
	// Set lentBorrowedSegmentedControl selection
	if ([self.game.lent isEqualToNumber:@(YES)]){
		[self.lentBorrowedSegmentedControl setSelectedSegmentIndex:1];
		[self.retailDigitalSegmentedControl setSelectedSegmentIndex:0];
	}
	else if ([self.game.borrowed isEqualToNumber:@(YES)]){
		[self.lentBorrowedSegmentedControl setSelectedSegmentIndex:2];
		[self.retailDigitalSegmentedControl setSelectedSegmentIndex:0];
	}
	else{
		[self.lentBorrowedSegmentedControl setSelectedSegmentIndex:0];
	}
	
	[self.ratingControl setRating:self.game.personalRating.floatValue];
	
	if (self.game.selectedMetascore){
		[self refreshMetascore];
	}
	
	// Details
	[self.descriptionTextView setText:self.game.overview];
	[self.genreFirstLabel setText:(self.game.genres.count > 0) ? [self.game.genres.allObjects.firstObject name] : @"Not available"];
	[self.genreSecondLabel setText:(self.game.genres.count > 1) ? [self.game.genres.allObjects[1] name] : @""];
	[self.themeFirstLabel setText:(self.game.themes.count > 0) ? [self.game.themes.allObjects.firstObject name] : @"Not available"];
	[self.themeSecondLabel setText:(self.game.themes.count > 1) ? [self.game.themes.allObjects[1] name] : @""];
	[self.developerFirstLabel setText:(self.game.developers.count > 0) ? [self.game.developers.allObjects.firstObject name] : @"Not available"];
	[self.developerSecondLabel setText:(self.game.developers.count > 1) ? [self.game.developers.allObjects[1] name] : @""];
	[self.publisherFirstLabel setText:(self.game.publishers.count > 0) ? [self.game.publishers.allObjects.firstObject name] : @"Not available"];
	[self.publisherSecondLabel setText:(self.game.publishers.count > 1) ? [self.game.publishers.allObjects[1] name] : @""];
	
	if (self.game.franchises.count == 0){
		[self.franchiseLabel setHidden:YES];
		[self.franchiseTitleLabel setHidden:YES];
	}
	else{
		[self.franchiseLabel setHidden:NO];
		[self.franchiseTitleLabel setHidden:NO];
		[self.franchiseTitleLabel setText:[self.game.franchises.allObjects.firstObject name]];
	}
	
	// Media
	self.images = [self orderedImagesFromGame:self.game];
	self.videos = [self orderedVideosFromGame:self.game];
	
	[self.imagesCollectionView setContentOffset:CGPointZero animated:NO];
	[self.imagesCollectionView reloadData];
	
	[self.videosCollectionView setContentOffset:CGPointZero animated:NO];
	[self.videosCollectionView reloadData];
	
	(self.images.count == 0) ? [self.imagesStatusView setStatus:ContentStatusUnavailable] : [self.imagesStatusView setHidden:YES];
	(self.videos.count == 0) ? [self.videosStatusView setStatus:ContentStatusUnavailable] : [self.videosStatusView setHidden:YES];
}

- (void)refreshMetascore{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
	
	[self.criticScoreLabel setText:[self.game.selectedMetascore.criticScore isEqualToNumber:@(0)] ? @"?" : [NSString stringWithFormat:@"%@", self.game.selectedMetascore.criticScore]];
	[self.criticScoreLabel setBackgroundColor:[self.game.selectedMetascore.criticScore isEqualToNumber:@(0)] ? [UIColor lightGrayColor] : [Networking colorForMetascore:self.criticScoreLabel.text]];
	
	[self.userScoreLabel setText:[self.game.selectedMetascore.userScore isEqual:[NSDecimalNumber zero]] ? @"?" : [NSString stringWithFormat:@"%.1f", self.game.selectedMetascore.userScore.floatValue]];
	[self.userScoreLabel setBackgroundColor:[self.game.selectedMetascore.userScore isEqual:[NSDecimalNumber zero]] ? [UIColor lightGrayColor] : [Networking colorForMetascore:[self.userScoreLabel.text stringByReplacingOccurrencesOfString:@"." withString:@""]]];
	
	[self.metascorePlatformLabel setText:self.game.selectedMetascore.platform.abbreviation];
	[self.metascorePlatformLabel setBackgroundColor:self.game.selectedMetascore.platform.color];
}

- (void)refreshAddButtonsAnimated:(BOOL)animated{
	if (self.selectablePlatforms.count > 0){
		[self.wishlistButton setHidden:NO];
		[self.libraryButton setHidden:([self.game.released isEqualToNumber:@(YES)] || [self.game.location isEqualToNumber:@(GameLocationLibrary)]) ? NO : YES];
	}
	else{
		[self.wishlistButton setHidden:[self.game.location isEqualToNumber:@(GameLocationWishlist)] ? NO : YES];
		[self.libraryButton setHidden:[self.game.location isEqualToNumber:@(GameLocationLibrary)] ? NO : YES];
	}
	
	[self.wishlistButton setTitle:[self.game.location isEqualToNumber:@(GameLocationWishlist)] ? @"REMOVE FROM WISHLIST" : @"ADD TO WISHLIST" forState:UIControlStateNormal];
	[self.libraryButton setTitle:[self.game.location isEqualToNumber:@(GameLocationLibrary)] ? @"REMOVE FROM LIBRARY" : @"ADD TO LIBRARY" forState:UIControlStateNormal];
	
	if (animated){
		[self.wishlistButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
		[self.libraryButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	}
}

- (NSArray *)orderedPlatformsFromGame:(Game *)game{
	NSSortDescriptor *groupSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES];
	NSSortDescriptor *indexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
	return [game.platforms.allObjects sortedArrayUsingDescriptors:@[groupSortDescriptor, indexSortDescriptor]];
}

- (NSArray *)orderedSelectedPlatformsFromGame:(Game *)game{
	NSSortDescriptor *groupSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES];
	NSSortDescriptor *indexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
	return [game.selectedPlatforms.allObjects sortedArrayUsingDescriptors:@[groupSortDescriptor, indexSortDescriptor]];
}

- (NSArray *)selectablePlatformsFromGame:(Game *)game{
	NSArray *selectablePlatforms = [game.platforms.allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", [Session gamer].platforms.allObjects]];
	
	NSSortDescriptor *groupSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES];
	NSSortDescriptor *indexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
	return [selectablePlatforms sortedArrayUsingDescriptors:@[groupSortDescriptor, indexSortDescriptor]];
}

- (NSArray *)orderedSimilarGamesFromGame:(Game *)game{
	NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
	return [game.similarGames.allObjects sortedArrayUsingDescriptors:@[titleSortDescriptor]];
}

- (NSArray *)orderedImagesFromGame:(Game *)game{
	NSSortDescriptor *indexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
	return [game.images.allObjects sortedArrayUsingDescriptors:@[indexSortDescriptor]];
}

- (NSArray *)orderedVideosFromGame:(Game *)game{
	NSSortDescriptor *indexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
	return [game.videos.allObjects sortedArrayUsingDescriptors:@[indexSortDescriptor]];
}

- (void)addGameToWishlistWithPlatforms:(NSArray *)platforms{
	[self.game setSelectedPlatforms:[NSSet setWithArray:platforms]];
	[self.game setLocation:@(GameLocationWishlist)];
	
	[self.game setPreordered:@(NO)];
	[self.game setFinished:@(NO)];
	[self.game setDigital:@(NO)];
	[self.game setLent:@(NO)];
	[self.game setBorrowed:@(NO)];
	
	[self saveAndRefreshAfterLocationChange];
}

- (void)addGameToLibraryWithPlatforms:(NSArray *)platforms{
	[self.game setSelectedPlatforms:[NSSet setWithArray:platforms]];
	[self.game setLocation:@(GameLocationLibrary)];
	
	[self.game setPreordered:@(NO)];
	[self.game setFinished:@(NO)];
	[self.game setDigital:@(NO)];
	[self.game setLent:@(NO)];
	[self.game setBorrowed:@(NO)];
	
	[self saveAndRefreshAfterLocationChange];
}

- (void)changeSelectedPlatformsToPlatforms:(NSArray *)platforms{
	[self.game setSelectedPlatforms:[NSSet setWithArray:platforms]];
	[self saveAndRefreshAfterLocationChange];
}

- (void)removeGameFromWishlistOrLibrary{
	[self.game setSelectedPlatforms:nil];
	[self.game setLocation:@(GameLocationNone)];
	
	[self.game setPreordered:@(NO)];
	[self.game setFinished:@(NO)];
	[self.game setDigital:@(NO)];
	[self.game setLent:@(NO)];
	[self.game setBorrowed:@(NO)];
	
	[self saveAndRefreshAfterLocationChange];
}

- (void)saveAndRefreshAfterLocationChange{
	[self.context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[self refreshAddButtonsAnimated:YES];
		
		// Update selected platforms
		self.selectedPlatforms = [self orderedSelectedPlatformsFromGame:self.game];
		[self.selectedPlatformsCollectionView reloadData];
		
		// Hide platform change if game not added
		[self.editPlatformsButton setHidden:([self.game.location isEqualToNumber:@(GameLocationNone)] || self.selectablePlatforms.count <= 1) ? YES : NO];
		
		// Auto-select release based on top selected platform and region
		for (Release *release in self.game.releases){
			if (release.platform == self.selectedPlatforms.firstObject && release.region == [Session gamer].region){
				[self.game setSelectedRelease:release];
				[self.game setReleasePeriod:[Networking releasePeriodForGameOrRelease:release context:self.context]];
			}
		}
		
		// Update release date
		[self.releaseDateLabel setText:self.game.selectedRelease ? self.game.selectedRelease.releaseDateText : self.game.releaseDateText];
		
		// Update statuses
		[self.preorderedSwitch setOn:self.game.preordered.boolValue animated:YES];
		[self.finishedSwitch setOn:self.game.finished.boolValue animated:YES];
		
		if ([self.game.lent isEqualToNumber:@(YES)])
			[self.lentBorrowedSegmentedControl setSelectedSegmentIndex:1];
		else if ([self.game.borrowed isEqualToNumber:@(YES)])
			[self.lentBorrowedSegmentedControl setSelectedSegmentIndex:2];
		else
			[self.lentBorrowedSegmentedControl setSelectedSegmentIndex:0];
		
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
		[self.tableView beginUpdates];
		[self.tableView endUpdates];
		
		[self.wishlistButton setHighlighted:NO];
		[self.libraryButton setHighlighted:NO];
		
		// Scroll to last row of status section if game added to library
		if ([self.game.location isEqualToNumber:@(GameLocationLibrary)]){
			[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:SectionStatus] atScrollPosition:UITableViewScrollPositionTop animated:YES];
		}
		
		if ([Tools deviceIsiPad]) [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
	}];
}

- (void)setupRatingControl{
	self.ratingControl = [[StarRatingControl alloc] initWithLocation:CGPointMake(5, 0) emptyColor:[UIColor orangeColor] solidColor:[UIColor orangeColor] andMaxRating:5];
	[self.ratingView setBackgroundColor:[UIColor clearColor]];
	[self.ratingControl setStarWidthAndHeight:40];
	[self.ratingControl setStarFontSize:30];
	[self.ratingView addSubview:self.ratingControl];
	
	__block Game *game = self.game;
	__block NSManagedObjectContext *context = self.context;
	
	[self.ratingControl setEditingChangedBlock:^(NSUInteger rating){
		[game setPersonalRating:@(rating)];
		[context MR_saveToPersistentStoreAndWait];
	}];
	
	[self.ratingControl setEditingDidEndBlock:^(NSUInteger rating){
		[game setPersonalRating:@(rating)];
		[context MR_saveToPersistentStoreAndWait];
	}];
}

#pragma mark - Actions

- (IBAction)addButtonPressAction:(UIButton *)sender{
	dispatch_async(dispatch_get_main_queue(), ^{
		[sender setHighlighted:YES];
	});
	
	// Removing from wishlist or library
	if ((sender == self.wishlistButton && [self.game.location isEqualToNumber:@(GameLocationWishlist)]) || (sender == self.libraryButton && [self.game.location isEqualToNumber:@(GameLocationLibrary)])){
		[self removeGameFromWishlistOrLibrary];
	}
	else{
		// Multiple platforms to select
		if (self.selectablePlatforms.count > 1){
			[self performSegueWithIdentifier:@"PlatformPickerSegue" sender:nil];
		}
		// Single platform
		else{
			if (sender == self.wishlistButton){
				[self addGameToWishlistWithPlatforms:@[self.selectablePlatforms.firstObject]];
			}
			else{
				[self addGameToLibraryWithPlatforms:@[self.selectablePlatforms.firstObject]];
			}
		}
	}
}

- (IBAction)editPlatformsButtonAction:(UIButton *)sender{
	[self performSegueWithIdentifier:@"PlatformPickerSegue" sender:nil];
}

- (IBAction)segmentedControlValueChangedAction:(UISegmentedControl *)sender{
	if (sender == self.retailDigitalSegmentedControl){
		switch (sender.selectedSegmentIndex) {
			case 0:
				[self.game setDigital:@(NO)];
				break;
			case 1:
				[self.game setDigital:@(YES)];
				[self.game setLent:@(NO)];
				[self.game setBorrowed:@(NO)];
				[self.lentBorrowedSegmentedControl setSelectedSegmentIndex:0];
				break;
			default:
				break;
		}
	}
	else{
		switch (sender.selectedSegmentIndex) {
			case 0:
				[self.game setLent:@(NO)];
				[self.game setBorrowed:@(NO)];
				break;
			case 1:
				[self.game setLent:@(YES)];
				[self.game setBorrowed:@(NO)];
				[self.game setDigital:@(NO)];
				[self.retailDigitalSegmentedControl setSelectedSegmentIndex:0];
				break;
			case 2:
				[self.game setLent:@(NO)];
				[self.game setBorrowed:@(YES)];
				[self.game setDigital:@(NO)];
				[self.retailDigitalSegmentedControl setSelectedSegmentIndex:0];
				break;
			default:
				break;
		}
	}
	
	[self.context MR_saveToPersistentStoreAndWait];
}

- (IBAction)switchValueChangedAction:(UISwitch *)sender{
	if (sender == self.preorderedSwitch)
		[self.game setPreordered:@(sender.isOn)];
	else
		[self.game setFinished:@(sender.isOn)];
	
	[self.context MR_saveToPersistentStoreAndWait];
}

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[sender setEnabled:NO];
	[self requestGameWithIdentifier:self.game.identifier];
}

- (IBAction)refreshControlValueChangedAction:(UIRefreshControl *)sender{
	[self requestGameWithIdentifier:self.game.identifier];
}

- (void)dismissTapGestureAction:(UITapGestureRecognizer *)sender{
	if (sender.state == UIGestureRecognizerStateEnded){
		CGPoint location = [sender locationInView:nil];
		if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil]){
			[self.view.window removeGestureRecognizer:sender];
			[self dismissViewControllerAnimated:YES completion:nil];
		}
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"PlatformPickerSegue"]){
		UINavigationController *navigationController = segue.destinationViewController;
		PlatformPickerController *destination = (PlatformPickerController *)navigationController.topViewController;
		[destination setSelectablePlatforms:self.selectablePlatforms];
		[destination setSelectedPlatforms:self.game.selectedPlatforms.allObjects.mutableCopy];
		[destination setDelegate:self];
	}
	else if ([segue.identifier isEqualToString:@"ReleasesSegue"]){
		ReleasesController *destination = segue.destinationViewController;
		[destination setGame:self.game];
		[destination setDelegate:self];
	}
	else if ([segue.identifier isEqualToString:@"NotesSegue"]){
		NotesController *destination = segue.destinationViewController;
		[destination setGame:self.game];
	}
	else if ([segue.identifier isEqualToString:@"MetascoreSegue"]){
		MetascoreController *destination = segue.destinationViewController;
		[destination setGame:self.game];
		[destination setDelegate:self];
	}
	else if ([segue.identifier isEqualToString:@"ImageViewerSegue"]){
		Image *image = sender;
		
		ImageViewerController *destination = segue.destinationViewController;
		[destination setImage:image];
	}
	else if ([segue.identifier isEqualToString:@"SimilarGameSegue"]){
		GameController *destination = segue.destinationViewController;
		[destination setGameIdentifier:sender];
	}
}

@end
