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
#import <MACircleProgressIndicator/MACircleProgressIndicator.h>
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

typedef NS_ENUM(NSInteger, Section){
	SectionCover,
	SectionStatus,
	SectionDetails,
	SectionImages,
	SectionVideos
};

typedef NS_ENUM(NSInteger, ActionSheetTag){
	ActionSheetTagWishlist,
	ActionSheetTagLibrary
};

@interface GameController () <UITextViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, PlatformPickerControllerDelegate, ReleasesControllerDelegate>

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;

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
@property (nonatomic, strong) IBOutlet UITextView *notesTextView;

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

@property (nonatomic, strong) IBOutlet UICollectionView *selectablePlatformsCollectionView;

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
@property (nonatomic, strong) NSArray *similarGames;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSArray *videos;

@property (nonatomic, strong) UITapGestureRecognizer *dismissTapGesture;

@end

@implementation GameController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	[_wishlistButton.layer setBorderWidth:1];
	[_wishlistButton.layer setBorderColor:_wishlistButton.tintColor.CGColor];
	[_wishlistButton.layer setCornerRadius:4];
	[_wishlistButton setBackgroundImage:[Tools imageWithColor:_wishlistButton.tintColor] forState:UIControlStateHighlighted];
	
	[_libraryButton.layer setBorderWidth:1];
	[_libraryButton.layer setBorderColor:_libraryButton.tintColor.CGColor];
	[_libraryButton.layer setCornerRadius:4];
	[_libraryButton setBackgroundImage:[Tools imageWithColor:_libraryButton.tintColor] forState:UIControlStateHighlighted];
	
	[_userScoreLabel.layer setCornerRadius:44/2];
	
	[self setupRatingControl];
	
	[self.refreshControl setTintColor:[UIColor lightGrayColor]];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	_imagesStatusView = [[ContentStatusView alloc] initWithUnavailableTitle:@"No images available"];
	_videosStatusView = [[ContentStatusView alloc] initWithUnavailableTitle:@"No videos available"];
	[_imagesCollectionView addSubview:_imagesStatusView];
	[_videosCollectionView addSubview:_videosStatusView];
	
	if (!_game)
		_game = [Game MR_findFirstByAttribute:@"identifier" withValue:_gameIdentifier inContext:_context];
	
	if (_game){
		[self refreshAnimated:NO];
		
		_images = [self orderedImagesFromGame:_game];
		_videos = [self orderedVideosFromGame:_game];
		
		(_images.count == 0) ? [_imagesStatusView setStatus:ContentStatusUnavailable] : [_imagesStatusView setHidden:YES];
		(_videos.count == 0) ? [_videosStatusView setStatus:ContentStatusUnavailable] : [_videosStatusView setHidden:YES];
	}
	else{
		[_imagesStatusView setStatus:ContentStatusLoading];
		[_videosStatusView setStatus:ContentStatusLoading];
		[self requestGameWithIdentifier:_gameIdentifier];
	}
}

- (void)viewDidLayoutSubviews{
	[_imagesStatusView setFrame:_imagesCollectionView.frame];
	[_videosStatusView setFrame:_videosCollectionView.frame];
}

- (void)viewWillAppear:(BOOL)animated{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
	
	if ([Tools deviceIsiPad]){
		_dismissTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTapGestureAction:)];
		[_dismissTapGesture setNumberOfTapsRequired:1];
		[_dismissTapGesture setCancelsTouchesInView:NO];
		[self.view.window addGestureRecognizer:_dismissTapGesture];
	}
	
	[self.refreshControl endRefreshing];
}

- (void)viewWillDisappear:(BOOL)animated{
	[self.view.window removeGestureRecognizer:_dismissTapGesture];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	if (_game){
		[tableView setSeparatorColor:[UIColor darkGrayColor]];
		return [super numberOfSectionsInTableView:tableView];
	}
	else{
		[tableView setSeparatorColor:[UIColor clearColor]];
		return 0;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
	if (section == SectionStatus && [_game.location isEqualToNumber:@(GameLocationNone)])
		return 0;
	return [super tableView:tableView heightForHeaderInSection:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case SectionCover:
			if ([_game.location isEqualToNumber:@(GameLocationNone)]){
				if (_game.releases.count > 0){
					return 3;
				}
				else
					return 2;
			}
			else if (_selectedPlatforms.count > 0){
				if (_game.releases.count > 0){
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
			if ([_game.location isEqualToNumber:@(GameLocationWishlist)])
				return [_game.released isEqualToNumber:@(YES)] ? 1 : 2;
			else if ([_game.location isEqualToNumber:@(GameLocationLibrary)])
				return 5;
			else
				return 0;
			break;
		case SectionDetails:
			if ([Tools deviceIsiPhone]){
				NSLog(@"%d", (_game.metascores.count > 0) + (_game.platforms.count > 0) + (_game.similarGames.count > 0) + 2);
				return (_game.metascores.count > 0) + (_game.platforms.count > 0) + (_game.similarGames.count > 0) + 2;
				break;
			}
			else if (_game.similarGames.count == 0)
				return 3;
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
				if (_game.releases.count > 0)
					return [super tableView:tableView heightForRowAtIndexPath:indexPath];
				else
					return 20 + 17 + 13 + ((_selectedPlatforms.count/5 + 1) * 31) + 20;
			}
			else if (indexPath.row == 3){
				return 20 + 17 + 13 + ((_selectedPlatforms.count/5 + 1) * 31) + 20;
			}
			break;
		case SectionStatus:
			if (([_game.location isEqualToNumber:@(GameLocationWishlist)] && [_game.released isEqualToNumber:@(NO)] && indexPath.row == 1) || ([_game.location isEqualToNumber:@(GameLocationWishlist)] && [_game.released isEqualToNumber:@(YES)] && indexPath.row == 0) || ([_game.location isEqualToNumber:@(GameLocationLibrary)] && indexPath.row == 4)){
				CGRect textRect = [_game.notes boundingRectWithSize:CGSizeMake(_notesTextView.frame.size.width - 15, 50000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil];
				return 45 + 20 + textRect.size.height + 20; // Top padding + note text height + bottom padding
			}
			break;
		case SectionDetails:{
			switch (indexPath.row) {
				// Description row
				case 0:{
					CGRect textRect = [_game.overview boundingRectWithSize:CGSizeMake(_descriptionTextView.frame.size.width - 10, 50000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil];
					return 20 + textRect.size.height + 20; // Top padding + description text height + bottom padding
				}
				// Info row
				case 1:{
					if ([Tools deviceIsiPhone]){
						CGFloat contentHeight = 0;
						contentHeight += _game.genres.count > 1 ? 57 : 37; // Labels' height
						contentHeight += 13; // Spacing
						contentHeight += _game.themes.count > 1 ? 57 : 37; // Labels' height
						contentHeight += 13; // Spacing
						contentHeight += _game.developers.count > 1 ? 57 : 37; // Labels' height
						contentHeight += 13; // Spacing
						contentHeight += _game.publishers.count > 1 ? 57 : 37; // Labels' height
						contentHeight += 13; // Spacing
						contentHeight += _game.franchises.count > 0 ? (13 + 37) : 0; // Extra spacing + labels' height
						return 20 + contentHeight + 20; // Top padding + content height + bottom padding
					}
					else{
						CGFloat leftColumn = 0;
						CGFloat rightColumn = 0;
						
						leftColumn += _game.genres.count > 1 ? 57 : 37; // Labels' height
						leftColumn += 13; // Spacing
						leftColumn += _game.themes.count > 1 ? 57 : 37; // Labels' height
						leftColumn += 13; // Spacing
						leftColumn += _game.franchises.count > 0 ? 37 : 0; // Labels' height
						
						rightColumn += _game.developers.count > 1 ? 57 : 37; // Labels' height
						rightColumn += 13; // Spacing
						rightColumn += _game.publishers.count > 1 ? 57 : 37; // Labels' height
						rightColumn += 13; // Spacing
						
						return 20 + fmaxf(leftColumn, rightColumn) + 20; // Top padding + highest column height + bottom padding
					}
					break;
				}
				// Platforms row
				case 2:
					// Similar games row
					if (_game.platforms.count == 0 && _game.metascores.count == 0){
						return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:SectionDetails]];
					}
					// Metascore row
					else if (_game.platforms.count == 0){
						return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:SectionDetails]];
					}
					// Platforms row
					else{
						if ([Tools deviceIsiPhone] && _selectablePlatforms.count > 0){
							return 20 + 17 + 13 + ((_selectablePlatforms.count/5 + 1) * 31) + 20; // Top padding + label height + spacing + platforms collection height + bottom padding
						}
					}
					break;
				case 3:
					if ((_game.platforms.count == 0 && _game.metascores.count > 0) || (_game.platforms.count > 0 && _game.metascores.count == 0)){
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
			if (indexPath.row == 2 && _game.releases.count == 0 && _selectedPlatforms.count > 0)
				return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:SectionCover]];
			break;
		case SectionStatus:
			if ([_game.location isEqualToNumber:@(GameLocationWishlist)]){
				if (([_game.released isEqualToNumber:@(YES)] && indexPath.row == 0) || ([_game.released isEqualToNumber:@(NO)] && indexPath.row == 1))
					return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:SectionStatus]];
			}
			else
				return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:SectionStatus]];
			break;
		case SectionDetails:
			if (indexPath.row == 2){
				if (_game.platforms.count == 0 && _game.metascores.count == 0){
					// Similar games row
					return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:SectionDetails]];
				}
				else if (_game.platforms.count == 0){
					// Metascore row
					return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:SectionDetails]];
				}
			}
			else if (indexPath.row == 3){
				if ((_game.platforms.count == 0 && _game.metascores.count > 0) || (_game.platforms.count > 0 && _game.metascores.count == 0)){
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case SectionCover:
			if (indexPath.row == 2 && _game.releases.count > 0)
				[self performSegueWithIdentifier:@"ReleasesSegue" sender:nil];
			break;
		case SectionStatus:
			if (indexPath.row == ([tableView numberOfRowsInSection:SectionStatus] - 1)){
				[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
				[_notesTextView becomeFirstResponder];
			}
			break;
		default:
			break;
	}
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	if (collectionView == _selectedPlatformsCollectionView)
		return _selectedPlatforms.count;
	else if (collectionView == _selectablePlatformsCollectionView)
		return _selectablePlatforms.count;
	else if (collectionView == _similarGamesCollectionView)
		return _similarGames.count;
	else if (collectionView == _imagesCollectionView){
		[collectionView setBounces:(_images.count == 0) ? NO : YES];
		return _images.count;
	}
	else{
		[collectionView setBounces:(_videos.count == 0) ? NO : YES];
		return _videos.count;
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	if (collectionView == _selectedPlatformsCollectionView){
		Platform *platform = _selectedPlatforms[indexPath.item];
		PlatformCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		[cell.platformLabel setText:platform.abbreviation];
		[cell.platformLabel setBackgroundColor:platform.color];
		return cell;
	}
	else if (collectionView == _selectablePlatformsCollectionView){
		Platform *platform = _selectablePlatforms[indexPath.item];
		PlatformCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		[cell.platformLabel setText:platform.abbreviation];
		[cell.platformLabel setBackgroundColor:platform.color];
		return cell;
	}
	else if (collectionView == _similarGamesCollectionView){
		SimilarGame *similarGame = _similarGames[indexPath.row];
		SimilarGameCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		[cell.coverImageView setImageWithURL:[NSURL URLWithString:similarGame.imageURL] placeholderImage:[Tools imageWithColor:[UIColor darkGrayColor]]];
		return cell;
	}
	else if (collectionView == _imagesCollectionView){
		// If before last cell, download image for next cell
		if (_images.count > (indexPath.item + 1)){
			Image *nextImage = _images[indexPath.item + 1];
			ImageCollectionCell *nextCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:[NSIndexPath indexPathForItem:indexPath.item + 1 inSection:0]];
			
			// Download thumbnail
			[nextCell.activityIndicator startAnimating];
			__weak ImageCollectionCell *cellReference = nextCell;
			[nextCell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:nextImage.thumbnailURL]] placeholderImage:[Tools imageWithColor:[UIColor blackColor]] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
				[cellReference.activityIndicator stopAnimating];
				[cellReference.imageView setImage:image];
				[cellReference.imageView.layer addAnimation:[Tools transitionWithType:kCATransitionFade duration:0.2 timingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]] forKey:nil];
			} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
				[cellReference.activityIndicator stopAnimating];
			}];
		}
		
		ImageCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		Image *image = _images[indexPath.item];
		
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
		// If before last cell, download image for next cell
		if (_videos.count > (indexPath.item + 1)){
			Video *nextVideo = _videos[indexPath.item + 1];
			VideoCollectionCell *nextCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:[NSIndexPath indexPathForItem:indexPath.item + 1 inSection:0]];
			
			// Download thumbnail
			[nextCell.activityIndicator startAnimating];
			__weak VideoCollectionCell *cellReference = nextCell;
			[nextCell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:nextVideo.imageURL]] placeholderImage:[Tools imageWithColor:[UIColor blackColor]] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
				[cellReference.activityIndicator stopAnimating];
				[cellReference.imageView setImage:image];
				[cellReference.imageView.layer addAnimation:[Tools transitionWithType:kCATransitionFade duration:0.2 timingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]] forKey:nil];
			} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
				[cellReference.activityIndicator stopAnimating];
			}];
		}
		
		VideoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		Video *video = _videos[indexPath.item];
		[cell.titleLabel setText:video.title];
		[cell.lengthLabel setText:[Tools formattedStringForDuration:video.length.integerValue]];
		
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
	if (collectionView == _imagesCollectionView){
		Image *image = _images[indexPath.item];
		[self performSegueWithIdentifier:@"ViewerSegue" sender:image];
	}
	else if (collectionView == _similarGamesCollectionView){
		SimilarGame *similarGame = _similarGames[indexPath.item];
		[self performSegueWithIdentifier:@"SimilarGameSegue" sender:similarGame.identifier];
	}
	else if (collectionView == _videosCollectionView){
		Video *video = _videos[indexPath.item];
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

#pragma mark - TextView

- (void)textViewDidChange:(UITextView *)textView{
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
	
	[_game setNotes:textView.text];
	[_context MR_saveToPersistentStoreAndWait];
}

#pragma mark - Networking

- (void)requestGameWithIdentifier:(NSNumber *)identifier{
	[self.refreshControl beginRefreshing];
	
	NSURLRequest *request = [Networking requestForGameWithIdentifier:identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Game", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			[self.navigationItem.rightBarButtonItem setEnabled:YES];
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Game - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", responseObject);
			
			_game = [Game MR_findFirstByAttribute:@"identifier" withValue:identifier inContext:_context];
			if (!_game) _game = [Game MR_createInContext:_context];
			
			[Networking updateGameInfoWithGame:_game JSON:responseObject context:_context];
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				// Refresh UI
				[self refreshAnimated:NO];
				[self.tableView reloadData];
				[_selectablePlatformsCollectionView reloadData];
				[_similarGamesCollectionView reloadData];
				
				// Cover image download
				NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
				UIImage *coverImage = [UIImage imageWithContentsOfFile:_game.imagePath];
				if (!coverImage || !_game.imagePath || ![_game.imageURL isEqualToString:coverImageURL]){
					[self downloadCoverImageWithURL:coverImageURL];
				}
				
				[self requestReleasesForGame:_game];
				
				[self requestMediaForGame:_game];
				
				if ([_game.releasePeriod.identifier compare:@(3)] <= NSOrderedSame){
					[self requestMetascoresForGame:_game platform:_selectablePlatforms.firstObject];
				}
				
				for (SimilarGame *similarGame in _game.similarGames){
					[self requestImageForSimilarGame:similarGame];
				}
				
//				if (
				
				// If game is released and has at least one platform, request metascore
//				if (([_game.releasePeriod.identifier isEqualToNumber:@(1)] || [_game.releasePeriod.identifier isEqualToNumber:@(2)]) && _selectablePlatforms.count > 0){
//					[self requestMetascoreForGameWithTitle:_game.title platform:_platforms.firstObject];
//				}
			}];
		}
		
		[self.refreshControl endRefreshing];
	}];
	[dataTask resume];
}

- (void)downloadCoverImageWithURL:(NSString *)URLString{
	if (!URLString) return;
	
	[_activityIndicator startAnimating];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
	
	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [Tools imagesDirectory], request.URL.lastPathComponent]];
		return fileURL;
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		[_activityIndicator stopAnimating];
		
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Cover Image", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Cover Image - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			[_game setImagePath:[NSString stringWithFormat:@"%@/%@", [Tools imagesDirectory], request.URL.lastPathComponent]];
			[_game setImageURL:URLString];
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"CoverImageDownloaded" object:nil];
				[self displayCoverImage];
			}];
		}
	}];
	[downloadTask resume];
}

- (void)requestReleasesForGame:(Game *)game{
	NSURLRequest *request = [Networking requestForReleasesWithGameIdentifier:game.identifier fields:@"id,name,platform,region,release_date,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Releases", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Releases - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			NSLog(@"%@", responseObject);
			
			[game setReleases:nil];
			
			[Networking updateGameReleasesWithGame:game JSON:responseObject context:_context];
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				if (!game.selectedRelease){
					for (Release *release in game.releases){
						if ([game.location isEqualToNumber:@(GameLocationNone)] && release.region == [Session gamer].region && [[[_selectablePlatforms reverseObjectEnumerator] allObjects] containsObject:release.platform]){
							[game setSelectedRelease:release];
							[game setReleasePeriod:[Networking releasePeriodForGameOrRelease:release context:_context]];
							
							[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
								[_releaseDateLabel setText:_game.selectedRelease ? _game.selectedRelease.releaseDateText : _game.releaseDateText];
							}];
						}
					}
				}
				
				[_releasesLabel setText:[NSString stringWithFormat:_game.releases.count > 1 ? @"%lu Releases" : @"%lu Release", (unsigned long)_game.releases.count]];
				
				[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionCover] withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView beginUpdates];
				[self.tableView endUpdates];
			}];
		}
	}];
	[dataTask resume];
}

- (void)requestMetascoresForGame:(Game *)game platform:(Platform *)platform{
	NSURLRequest *request = [Networking requestForMetascoreWithGame:game platform:platform];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Metascore", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Metascore - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			NSLog(@"%@", responseObject);
			
			NSDictionary *results = responseObject[@"result"];
			
			NSString *metacriticURL = [Tools stringFromSourceIfNotNull:results[@"url"]];
			
			Metascore *metascore = [Metascore MR_findFirstByAttribute:@"metacriticURL" withValue:metacriticURL inContext:_context];
			if (!metascore) metascore = [Metascore MR_createInContext:_context];
			[metascore setCriticScore:[Tools integerNumberFromSourceIfNotNull:results[@"score"]]];
			[metascore setUserScore:[Tools decimalNumberFromSourceIfNotNull:results[@"userscore"]]];
			[metascore setMetacriticURL:metacriticURL];
			[metascore setPlatform:platform];
			[game addMetascoresObject:metascore];
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[_criticScoreLabel setText:[NSString stringWithFormat:@"%@", metascore.criticScore]];
				[_userScoreLabel setText:[NSString stringWithFormat:@"%.1f", metascore.userScore.floatValue]];
				[_metascorePlatformLabel setText:platform.abbreviation];
				[_metascorePlatformLabel setBackgroundColor:platform.color];
				
				[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionDetails] withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView beginUpdates];
				[self.tableView endUpdates];
			}];
		}
	}];
	[dataTask resume];
}

//- (void)requestMetascoreForGameWithTitle:(NSString *)title platform:(Platform *)platform{
//	NSURLRequest *request = [Networking requestForMetascoreForGameWithTitle:title platform:platform];
//	
//	if (request.URL){
//		NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
//			NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject, request.URL.lastPathComponent]];
//			return fileURL;
//		} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//			if (error){
//				NSLog(@"Failure in %@ - Metascore", self);
//			}
//			else{
//				NSLog(@"Success in %@ - Metascore - %@", self, request.URL);
//				
//				NSString *HTML = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:filePath] encoding:NSUTF8StringEncoding];
//				//			NSLog(@"HTML: %@", HTML);
//				
//				[_game setMetacriticURL:request.URL.absoluteString];
//				
//				if (HTML){
//					NSString *metascore = [Networking retrieveMetascoreFromHTML:HTML];
//					[_game setMetascore:metascore];
//					
//					[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
//						[_metascoreButton setHidden:NO];
//						[_metascoreButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
//						
//						if (metascore.length > 0 && [[NSScanner scannerWithString:metascore] scanInteger:nil]){
//							[_metascoreButton setBackgroundColor:[Networking colorForMetascore:metascore]];
//							[_metascoreButton.titleLabel setFont:[UIFont boldSystemFontOfSize:30]];
//							[_metascoreButton setTitle:metascore forState:UIControlStateNormal];
//							
//							[_metascorePlatformLabel setText:platform.name];
//							[_metascorePlatformLabel setHidden:NO];
//							[_metascorePlatformLabel.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
//							
//							[_game setMetacriticURL:request.URL.absoluteString];
//							[_game setMetascorePlatform:platform];
//							
//							if (_game.wishlistPlatform && _game.wishlistPlatform == _game.metascorePlatform){
//								[_game setWishlistMetascore:metascore];
//								[_game setWishlistMetascorePlatform:platform];
//								[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
//							}
//						}
//						else{
//							if (_selectablePlatforms.count > ([_selectablePlatforms indexOfObject:platform] + 1))
//								[self requestMetascoreForGameWithTitle:title platform:_selectablePlatforms[[_selectablePlatforms indexOfObject:platform] + 1]];
//							else{
//								[_metascoreButton setBackgroundColor:[UIColor darkGrayColor]];
//								[_metascoreButton.titleLabel setFont:[UIFont boldSystemFontOfSize:10]];
//								[_metascoreButton setTitle:@"Metacritic" forState:UIControlStateNormal];
//								[_metascoreButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
//							}
//						}
//					}];
//				}
//				else if (_selectablePlatforms.count > ([_selectablePlatforms indexOfObject:platform] + 1))
//					[self requestMetascoreForGameWithTitle:title platform:_selectablePlatforms[[_selectablePlatforms indexOfObject:platform] + 1]];
//				else
//					[_context MR_saveToPersistentStoreAndWait];
//			}
//		}];
//		[downloadTask resume];
//	}
//}

- (void)requestImageForSimilarGame:(SimilarGame *)similarGame{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:similarGame.identifier fields:@"image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Similar Game Image", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			[self.navigationItem.rightBarButtonItem setEnabled:YES];
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Similar Game Image - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			//		NSLog(@"%@", JSON);
			
			NSDictionary *results = responseObject[@"results"];
			
			if (results[@"image"] != [NSNull null])
				[similarGame setImageURL:[Tools stringFromSourceIfNotNull:results[@"image"][@"thumb_url"]]];
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[_similarGamesCollectionView reloadData];
			}];
		}
	}];
	[dataTask resume];
}

- (void)requestMediaForGame:(Game *)game{
	[_imagesStatusView setStatus:ContentStatusLoading];
	[_videosStatusView setStatus:ContentStatusLoading];
	
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"images,videos"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			[self.navigationItem.rightBarButtonItem setEnabled:YES];
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Media - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			//		NSLog(@"%@", JSON);
			
			[_game setImages:nil];
			[_game setVideos:nil];
			
			NSDictionary *results = responseObject[@"results"];
			
			// Images
			if (results[@"images"] != [NSNull null]){
				NSInteger index = 0;
				for (NSDictionary *dictionary in results[@"images"]){
					NSString *stringURL = [Tools stringFromSourceIfNotNull:dictionary[@"super_url"]];
					Image *image = [Image MR_findFirstByAttribute:@"thumbnailURL" withValue:stringURL inContext:_context];
					if (!image){
						image = [Image MR_createInContext:_context];
						
						[image setThumbnailURL:stringURL];
						[image setOriginalURL:[stringURL stringByReplacingOccurrencesOfString:@"scale_large" withString:@"original"]];
					}
					
					[image setIndex:@(index)];
					[game addImagesObject:image];
					
					index++;
				}
				
				_images = [self orderedImagesFromGame:game];
				
				// No images available
				if (index == 0){
					[_imagesStatusView setStatus:ContentStatusUnavailable];
				}
				[_imagesStatusView setHidden:(index == 0) ? NO : YES];
			}
			
			// Videos
			if (results[@"videos"] != [NSNull null]){
				NSInteger index = 0;
				for (NSDictionary *dictionary in results[@"videos"]){
					NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
					Video *video = [Video MR_findFirstByAttribute:@"identifier" withValue:identifier inContext:_context];
					if (!video){
						video = [Video MR_createInContext:_context];
						[video setIdentifier:identifier];
					}
					
					[video setIndex:@(index)];
					[video setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"title"]]];
					[game addVideosObject:video];
					
					[self requestInformationForVideo:video];
					
					index++;
				}
				
				_videos = [self orderedVideosFromGame:game];
				
				// No videos available
				if (index == 0)
					[_videosStatusView setStatus:ContentStatusUnavailable];
			}
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[self.navigationItem.rightBarButtonItem setEnabled:YES];
				
				[_imagesCollectionView reloadData];
			}];
		}
	}];
	[dataTask resume];
}

- (void)requestInformationForVideo:(Video *)video{
	NSURLRequest *request = [Networking requestForVideoWithIdentifier:video.identifier fields:@"id,name,deck,video_type,length_seconds,publish_date,high_url,low_url,image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			NSLog(@"Failure in %@ - Status code: %ld - Video", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
//			NSLog(@"Success in %@ - Status code: %d - Video - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
//			NSLog(@"%@", JSON);
			
			[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
			
			if ([responseObject[@"status_code"] isEqualToNumber:@(101)]){
				[video MR_deleteEntity];
				[_context MR_saveToPersistentStoreAndWait];
				return;
			}
			
			NSDictionary *results = responseObject[@"results"];
			
			NSString *type = [Tools stringFromSourceIfNotNull:results[@"video_type"]];
			if ([type isEqualToString:@"Trailers"]){
				[video setType:type];
				[video setTitle:[Tools stringFromSourceIfNotNull:results[@"name"]]];
				[video setOverview:[Tools stringFromSourceIfNotNull:results[@"deck"]]];
				[video setLength:[Tools integerNumberFromSourceIfNotNull:results[@"length_seconds"]]];
				[video setPublishDate:[[Tools dateFormatter] dateFromString:results[@"publish_date"]]];
				[video setHighQualityURL:[Tools stringFromSourceIfNotNull:results[@"high_url"]]];
				[video setLowQualityURL:[Tools stringFromSourceIfNotNull:results[@"low_url"]]];
				[video setImageURL:[Tools stringFromSourceIfNotNull:results[@"image"][@"super_url"]]];
				NSLog(@"%@", video.imageURL);
			}
			else
				[video MR_deleteEntity];
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				_videos = [self orderedVideosFromGame:_game];
				
				if (_videos.count == 0){
					[_videosStatusView setStatus:ContentStatusUnavailable];
					[_videosStatusView setHidden:NO];
				}
				else{
					[_videosCollectionView reloadData];
					[_videosStatusView setHidden:YES];
				}
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
		if (_wishlistButton.isHighlighted){
			[self addGameToWishlistWithPlatforms:platforms];
		}
		else if (_libraryButton.isHighlighted){
			[self addGameToLibraryWithPlatforms:platforms];
		}
		else{
			[self changeSelectedPlatformsToPlatforms:platforms];
		}
	}
	
//	dispatch_async(dispatch_get_main_queue(), ^{
//		[_wishlistButton setHighlighted:NO];
//		[_libraryButton setHighlighted:NO];
//	});
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ReleasesController

- (void)releasesController:(ReleasesController *)controller didSelectRelease:(Release *)release{
	[_game setSelectedRelease:release];
	[_game setReleasePeriod:[Networking releasePeriodForGameOrRelease:release context:_context]];
	[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[_releaseDateLabel setText:_game.selectedRelease ? _game.selectedRelease.releaseDateText : _game.releaseDateText];
		[self.navigationController popViewControllerAnimated:YES];
	}];
}

#pragma mark - Custom

- (void)displayCoverImage{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		UIImage *image = [UIImage imageWithContentsOfFile:_game.imagePath];
		
		CGSize imageSize = image.size.width > image.size.height ? [Tools sizeOfImage:image aspectFitToWidth:_coverImageView.frame.size.width] : [Tools sizeOfImage:image aspectFitToHeight:_coverImageView.frame.size.height];
		
		UIGraphicsBeginImageContext(imageSize);
		[image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[_coverImageView setImage:[UIImage imageWithContentsOfFile:_game.imagePath]];
			[_coverImageView.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
			[Tools addDropShadowToView:_coverImageView color:[UIColor blackColor] opacity:1 radius:10 offset:CGSizeMake(0, 5) bounds:[Tools frameForImageInImageView:_coverImageView]];
		});
	});
}

- (void)refreshAnimated:(BOOL)animated{
	[self displayCoverImage];
	
	[_titleLabel setText:_game.title];
	
	[_releaseDateLabel setText:_game.selectedRelease ? _game.selectedRelease.releaseDateText : _game.releaseDateText];
	
	[_releasesLabel setText:[NSString stringWithFormat:_game.releases.count > 1 ? @"%lu Releases" : @"%lu Release", (unsigned long)_game.releases.count]];
	
	_selectablePlatforms = [self selectablePlatformsFromGame:_game];
	
	_selectedPlatforms = [self orderedSelectedPlatformsFromGame:_game];
	
	_similarGames = [self orderedSimilarGamesFromGame:_game];
	
	[_editPlatformsButton setHidden:([_game.location isEqualToNumber:@(GameLocationNone)] || _selectablePlatforms.count <= 1) ? YES : NO];
	
	[self refreshAddButtonsAnimated:animated];
	
	// Set status switches' position
	[_preorderedSwitch setOn:_game.preordered.boolValue animated:animated];
	[_finishedSwitch setOn:_game.finished.boolValue animated:animated];
	
	// Set retailDigitalSegmentedControl selection
	if ([_game.digital isEqualToNumber:@(YES)]){
		[_retailDigitalSegmentedControl setSelectedSegmentIndex:1];
		[_lentBorrowedSegmentedControl setSelectedSegmentIndex:0];
	}
	else{
		[_retailDigitalSegmentedControl setSelectedSegmentIndex:0];
	}
	
	// Set lentBorrowedSegmentedControl selection
	if ([_game.lent isEqualToNumber:@(YES)]){
		[_lentBorrowedSegmentedControl setSelectedSegmentIndex:1];
		[_retailDigitalSegmentedControl setSelectedSegmentIndex:0];
	}
	else if ([_game.borrowed isEqualToNumber:@(YES)]){
		[_lentBorrowedSegmentedControl setSelectedSegmentIndex:2];
		[_retailDigitalSegmentedControl setSelectedSegmentIndex:0];
	}
	else{
		[_lentBorrowedSegmentedControl setSelectedSegmentIndex:0];
	}
	
	[_ratingControl setRating:_game.personalRating.floatValue];
	
	[_notesTextView setText:_game.notes];
	
	if (_game.metascores.count > 0){
		[_criticScoreLabel setText:[NSString stringWithFormat:@"%@", [_game.metascores.allObjects[0] criticScore]]];
		[_userScoreLabel setText:[NSString stringWithFormat:@"%.1f", [[_game.metascores.allObjects[0] userScore] floatValue]]];
		[_metascorePlatformLabel setText:[_selectablePlatforms.firstObject abbreviation]];
		[_metascorePlatformLabel setBackgroundColor:[_selectablePlatforms.firstObject color]];
	}
	
//	if (_game.metascore.length > 0){
//		[_metascoreButton setBackgroundColor:[Networking colorForMetascore:_game.metascore]];
//		[_metascoreButton.titleLabel setFont:[UIFont boldSystemFontOfSize:30]];
//		[_metascoreButton setTitle:_game.metascore forState:UIControlStateNormal];
//		[_metascorePlatformLabel setText:_game.metascorePlatform.name];
//	}
//	else if (_game.metacriticURL.length > 0){
//		[_metascoreButton setBackgroundColor:[UIColor darkGrayColor]];
//		[_metascoreButton.titleLabel setFont:[UIFont boldSystemFontOfSize:10]];
//		[_metascoreButton setTitle:@"Metacritic" forState:UIControlStateNormal];
//		[_metascorePlatformLabel setHidden:YES];
//	}
//	else{
//		[_metascoreButton setHidden:YES];
//		[_metascorePlatformLabel setHidden:YES];
//	}
	
	[_descriptionTextView setText:_game.overview];
	[_genreFirstLabel setText:(_game.genres.count > 0) ? [_game.genres.allObjects.firstObject name] : @"Not available"];
	[_genreSecondLabel setText:(_game.genres.count > 1) ? [_game.genres.allObjects[1] name] : @""];
	[_themeFirstLabel setText:(_game.themes.count > 0) ? [_game.themes.allObjects.firstObject name] : @"Not available"];
	[_themeSecondLabel setText:(_game.themes.count > 1) ? [_game.themes.allObjects[1] name] : @""];
	[_developerFirstLabel setText:(_game.developers.count > 0) ? [_game.developers.allObjects.firstObject name] : @"Not available"];
	[_developerSecondLabel setText:(_game.developers.count > 1) ? [_game.developers.allObjects[1] name] : @""];
	[_publisherFirstLabel setText:(_game.publishers.count > 0) ? [_game.publishers.allObjects.firstObject name] : @"Not available"];
	[_publisherSecondLabel setText:(_game.publishers.count > 1) ? [_game.publishers.allObjects[1] name] : @""];
	
	if (_game.franchises.count == 0){
		[_franchiseLabel setHidden:YES];
		[_franchiseTitleLabel setHidden:YES];
	}
	else{
		[_franchiseLabel setHidden:NO];
		[_franchiseTitleLabel setHidden:NO];
		[_franchiseTitleLabel setText:[_game.franchises.allObjects.firstObject name]];
	}
}

- (void)refreshAddButtonsAnimated:(BOOL)animated{
	if (_selectablePlatforms.count > 0){
		[_wishlistButton setHidden:NO];
		[_libraryButton setHidden:([_game.released isEqualToNumber:@(YES)] || [_game.location isEqualToNumber:@(GameLocationLibrary)]) ? NO : YES];
	}
	else{
		[_wishlistButton setHidden:[_game.location isEqualToNumber:@(GameLocationWishlist)] ? NO : YES];
		[_libraryButton setHidden:[_game.location isEqualToNumber:@(GameLocationLibrary)] ? NO : YES];
	}
	
	[_wishlistButton setTitle:[_game.location isEqualToNumber:@(GameLocationWishlist)] ? @"REMOVE FROM WISHLIST" : @"ADD TO WISHLIST" forState:UIControlStateNormal];
	[_libraryButton setTitle:[_game.location isEqualToNumber:@(GameLocationLibrary)] ? @"REMOVE FROM LIBRARY" : @"ADD TO LIBRARY" forState:UIControlStateNormal];
	
	if (animated){
		[_wishlistButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
		[_libraryButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	}
}

- (NSArray *)orderedPlatformsFromGame:(Game *)game{
	return [game.platforms.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		Platform *platform1 = (Platform *)obj1;
		Platform *platform2 = (Platform *)obj2;
		return [platform1.index compare:platform2.index] == NSOrderedDescending;
	}];
}

- (NSArray *)orderedSelectedPlatformsFromGame:(Game *)game{
	return [game.selectedPlatforms.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		Platform *platform1 = (Platform *)obj1;
		Platform *platform2 = (Platform *)obj2;
		return [platform1.index compare:platform2.index] == NSOrderedDescending;
	}];
}

- (NSArray *)selectablePlatformsFromGame:(Game *)game{
	NSMutableArray *selectablePlatforms = [[NSMutableArray alloc] initWithCapacity:[Session gamer].platforms.count];
	NSArray *platformIdentifiers = [[Session gamer].platforms valueForKey:@"identifier"];
	
	for (Platform *platform in _game.platforms){
		if ([platformIdentifiers containsObject:platform.identifier]){
			[selectablePlatforms addObject:platform];
		}
	}
	
	return [selectablePlatforms sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		Platform *platform1 = (Platform *)obj1;
		Platform *platform2 = (Platform *)obj2;
		return [platform1.index compare:platform2.index] == NSOrderedDescending;
	}];
}

- (NSArray *)orderedSimilarGamesFromGame:(Game *)game{
	return [game.similarGames.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		SimilarGame *similarGame1 = (SimilarGame *)obj1;
		SimilarGame *similarGame2 = (SimilarGame *)obj2;
		return [similarGame1.title compare:similarGame2.title] == NSOrderedAscending;
	}];
}

- (NSArray *)orderedImagesFromGame:(Game *)game{
	return [game.images.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		Image *image1 = (Image *)obj1;
		Image *image2 = (Image *)obj2;
		return [image1.index compare:image2.index] == NSOrderedDescending;
	}];
}

- (NSArray *)orderedVideosFromGame:(Game *)game{
	return [game.videos.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		Video *video1 = (Video *)obj1;
		Video *video2 = (Video *)obj2;
		return [video1.index compare:video2.index] == NSOrderedDescending;
	}];
}

- (void)addGameToWishlistWithPlatforms:(NSArray *)platforms{
	[_game setSelectedPlatforms:[NSSet setWithArray:platforms]];
	[_game setLocation:@(GameLocationWishlist)];
	
	// If release period is collapsed, set game to hidden
	if ([_game.releasePeriod.placeholderGame.hidden isEqualToNumber:@(NO)]){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod = %@ AND (hidden = %@ AND location = %@)", _game.releasePeriod, @(NO), @(GameLocationWishlist)];
		NSInteger gamesCount = [Game MR_countOfEntitiesWithPredicate:predicate];
		[_game setHidden:(gamesCount == 0) ? @(YES) : @(NO)];
	}
	
	[_game setPreordered:@(NO)];
	[_game setFinished:@(NO)];
	[_game setDigital:@(NO)];
	[_game setLent:@(NO)];
	[_game setBorrowed:@(NO)];
	
	[self saveAndRefreshAfterLocationChange];
}

- (void)addGameToLibraryWithPlatforms:(NSArray *)platforms{
	[_game setSelectedPlatforms:[NSSet setWithArray:platforms]];
	[_game setLocation:@(GameLocationLibrary)];
	
	[_game setPreordered:@(NO)];
	[_game setFinished:@(NO)];
	[_game setDigital:@(NO)];
	[_game setLent:@(NO)];
	[_game setBorrowed:@(NO)];
	
	[self saveAndRefreshAfterLocationChange];
}

- (void)changeSelectedPlatformsToPlatforms:(NSArray *)platforms{
	[_game setSelectedPlatforms:[NSSet setWithArray:platforms]];
	[self saveAndRefreshAfterLocationChange];
}

- (void)removeGameFromWishlistOrLibrary{
	[_game setSelectedPlatforms:nil];
	[_game setLocation:@(GameLocationNone)];
	
	[_game setPreordered:@(NO)];
	[_game setFinished:@(NO)];
	[_game setDigital:@(NO)];
	[_game setLent:@(NO)];
	[_game setBorrowed:@(NO)];
	
	[self saveAndRefreshAfterLocationChange];
}

- (void)saveAndRefreshAfterLocationChange{
	[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[self refreshAddButtonsAnimated:YES];
		
		// Update selected platforms
		_selectedPlatforms = [self orderedSelectedPlatformsFromGame:_game];
		[_selectedPlatformsCollectionView reloadData];
		
		// Hide platform change if game not added
		[_editPlatformsButton setHidden:([_game.location isEqualToNumber:@(GameLocationNone)] || _selectablePlatforms.count <= 1) ? YES : NO];
		
		// Auto-select release based on top selected platform and region
		for (Release *release in _game.releases){
			if (release.platform == _selectedPlatforms.firstObject && release.region == [Session gamer].region){
				[_game setSelectedRelease:release];
				[_game setReleasePeriod:[Networking releasePeriodForGameOrRelease:release context:_context]];
			}
		}
		
		// Update release date
		[_releaseDateLabel setText:_game.selectedRelease ? _game.selectedRelease.releaseDateText : _game.releaseDateText];
		
		// Update statuses
		[_preorderedSwitch setOn:_game.preordered.boolValue animated:YES];
		[_finishedSwitch setOn:_game.finished.boolValue animated:YES];
		
		if ([_game.lent isEqualToNumber:@(YES)])
			[_lentBorrowedSegmentedControl setSelectedSegmentIndex:1];
		else if ([_game.borrowed isEqualToNumber:@(YES)])
			[_lentBorrowedSegmentedControl setSelectedSegmentIndex:2];
		else
			[_lentBorrowedSegmentedControl setSelectedSegmentIndex:0];
		
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
		[self.tableView beginUpdates];
		[self.tableView endUpdates];
		
		[_wishlistButton setHighlighted:NO];
		[_libraryButton setHighlighted:NO];
		
		// Scroll to last row of status section if game added to library
		if ([_game.location isEqualToNumber:@(GameLocationLibrary)]){
			[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:SectionStatus] atScrollPosition:UITableViewScrollPositionTop animated:YES];
		}
		
		if ([Tools deviceIsiPad]) [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
	}];
}

- (void)setupRatingControl{
	_ratingControl = [[StarRatingControl alloc] initWithLocation:CGPointMake(5, 0) emptyColor:[UIColor orangeColor] solidColor:[UIColor orangeColor] andMaxRating:5];
	[_ratingView setBackgroundColor:[UIColor clearColor]];
	[_ratingControl setStarWidthAndHeight:40];
	[_ratingControl setStarFontSize:30];
	[_ratingView addSubview:_ratingControl];
	
	__block Game *game = _game;
	__block NSManagedObjectContext *context = _context;
	
	[_ratingControl setEditingChangedBlock:^(NSUInteger rating){
		[game setPersonalRating:@(rating)];
		[context MR_saveToPersistentStoreAndWait];
	}];
	
	[_ratingControl setEditingDidEndBlock:^(NSUInteger rating){
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
	if ((sender == _wishlistButton && [_game.location isEqualToNumber:@(GameLocationWishlist)]) || (sender == _libraryButton && [_game.location isEqualToNumber:@(GameLocationLibrary)])){
		[self removeGameFromWishlistOrLibrary];
	}
	else{
		// Multiple platforms to select
		if (_selectablePlatforms.count > 1){
			[self performSegueWithIdentifier:@"PlatformPickerSegue" sender:nil];
		}
		// Single platform
		else{
			if (sender == _wishlistButton){
				[self addGameToWishlistWithPlatforms:@[_selectablePlatforms.firstObject]];
			}
			else{
				[self addGameToLibraryWithPlatforms:@[_selectablePlatforms.firstObject]];
			}
		}
	}
}

- (IBAction)editPlatformsButtonAction:(UIButton *)sender{
	[self performSegueWithIdentifier:@"PlatformPickerSegue" sender:nil];
}

- (IBAction)segmentedControlValueChangedAction:(UISegmentedControl *)sender{
	if (sender == _retailDigitalSegmentedControl){
		switch (sender.selectedSegmentIndex) {
			case 0:
				[_game setDigital:@(NO)];
				break;
			case 1:
				[_game setDigital:@(YES)];
				[_game setLent:@(NO)];
				[_game setBorrowed:@(NO)];
				[_lentBorrowedSegmentedControl setSelectedSegmentIndex:0];
				break;
			default:
				break;
		}
	}
	else{
		switch (sender.selectedSegmentIndex) {
			case 0:
				[_game setLent:@(NO)];
				[_game setBorrowed:@(NO)];
				break;
			case 1:
				[_game setLent:@(YES)];
				[_game setBorrowed:@(NO)];
				[_game setDigital:@(NO)];
				[_retailDigitalSegmentedControl setSelectedSegmentIndex:0];
				break;
			case 2:
				[_game setLent:@(NO)];
				[_game setBorrowed:@(YES)];
				[_game setDigital:@(NO)];
				[_retailDigitalSegmentedControl setSelectedSegmentIndex:0];
				break;
			default:
				break;
		}
	}
	
	[_context MR_saveToPersistentStoreAndWait];
}

- (IBAction)switchValueChangedAction:(UISwitch *)sender{
	if (sender == _preorderedSwitch)
		[_game setPreordered:@(sender.isOn)];
	else
		[_game setFinished:@(sender.isOn)];
	
	[_context MR_saveToPersistentStoreAndWait];
}

- (IBAction)metascoreButtonAction:(UIButton *)sender{
	[self performSegueWithIdentifier:@"MetacriticSegue" sender:nil];
}

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[sender setEnabled:NO];
	[self requestGameWithIdentifier:_game.identifier];
}

- (IBAction)refreshControlValueChangedAction:(UIRefreshControl *)sender{
	[self requestGameWithIdentifier:_game.identifier];
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
		[destination setSelectablePlatforms:_selectablePlatforms];
		[destination setSelectedPlatforms:_game.selectedPlatforms.allObjects.mutableCopy];
		[destination setDelegate:self];
	}
	else if ([segue.identifier isEqualToString:@"ReleasesSegue"]){
		ReleasesController *destination = segue.destinationViewController;
		[destination setGame:_game];
		[destination setDelegate:self];
	}
	else if ([segue.identifier isEqualToString:@"ViewerSegue"]){
		Image *image = sender;
		
		ImageViewerController *destination = segue.destinationViewController;
		[destination setImage:image];
	}
	else if ([segue.identifier isEqualToString:@"MetacriticSegue"]){
//		MetacriticController *destination = segue.destinationViewController;
//		[destination setURL:[NSURL URLWithString:_game.metacriticURL]];
	}
	else if ([segue.identifier isEqualToString:@"SimilarGameSegue"]){
		GameController *destination = segue.destinationViewController;
		[destination setGameIdentifier:sender];
	}
}

@end
