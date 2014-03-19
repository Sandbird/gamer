//
//  GameTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "GameTableViewController.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "Image.h"
#import "Video.h"
#import "ReleasePeriod.h"
#import "CoverImage.h"
#import "ReleaseDate.h"
#import "SimilarGame.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ImageCollectionCell.h"
#import "VideoCollectionCell.h"
#import <MACircleProgressIndicator/MACircleProgressIndicator.h>
#import "ImageViewerViewController.h"
#import "PlatformCollectionCell.h"
#import "ContentStatusView.h"
#import "MetacriticViewController.h"
#import "TrailerViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "SimilarGameCollectionCell.h"

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

@interface GameTableViewController () <UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

@property (nonatomic, strong) IBOutlet UILabel *releaseDateLabel;
@property (nonatomic, strong) IBOutlet UIButton *wishlistButton;
@property (nonatomic, strong) IBOutlet UIButton *libraryButton;

@property (nonatomic, strong) IBOutlet UISwitch *preorderedSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *completedSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *loanedSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *digitalSwitch;

@property (nonatomic, strong) IBOutlet UITextView *descriptionTextView;

@property (nonatomic, strong) IBOutlet UIButton *metascoreButton;
@property (nonatomic, strong) IBOutlet UILabel *metascorePlatformLabel;
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
@property (nonatomic, strong) IBOutlet UICollectionView *similarGamesCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *imagesCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *videosCollectionView;

@property (nonatomic, strong) ContentStatusView *imagesStatusView;
@property (nonatomic, strong) ContentStatusView *videosStatusView;

@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) NSArray *platforms;
@property (nonatomic, strong) NSArray *similarGames;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSArray *videos;

@property (nonatomic, strong) NSArray *selectablePlatforms;

@property (nonatomic, strong) UITapGestureRecognizer *dismissTapGesture;

@end

@implementation GameTableViewController

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
	
	[Tools setMaskToView:_metascoreButton roundCorners:UIRectCornerAllCorners radius:32];
	
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

- (void)viewDidAppear:(BOOL)animated{
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
	if (section == SectionStatus && ([_game.wanted isEqualToNumber:@(NO)] || ([_game.wanted isEqualToNumber:@(YES)] && [_game.released isEqualToNumber:@(YES)])) && [_game.owned isEqualToNumber:@(NO)])
		return 0;
	return [super tableView:tableView heightForHeaderInSection:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case SectionStatus:
			if ([_game.wanted isEqualToNumber:@(YES)] && [_game.released isEqualToNumber:@(NO)])
				return 1;
			else if ([_game.owned isEqualToNumber:@(YES)])
				return 3;
			else
				return 0;
			break;
		case SectionDetails:
			if ([Tools deviceIsiPhone]){
				if (_game.platforms.count == 0 && _game.similarGames.count == 0)
					return 2;
				else if (_game.platforms.count == 0 || _game.similarGames.count == 0)
					return 3;
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
					if ([Tools deviceIsiPhone]){
						if (_game.platforms.count > 0)
							return 20 + 17 + 13 + ((_game.platforms.count/5 + 1) * 31) + 20; // Top padding + label height + spacing + platforms collection height + bottom padding
						else
							return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:SectionDetails]];
					}
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
	if (indexPath.section == SectionStatus && [_game.owned isEqualToNumber:@(YES)])
		return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
	else if (indexPath.section == SectionDetails && indexPath.row == 2){
		if (_game.platforms.count == 0)
			return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:indexPath.section]];
	}
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell setBackgroundColor:[UIColor colorWithRed:.164705882 green:.164705882 blue:.164705882 alpha:1]];
	if (indexPath.section == SectionVideos) [cell setSeparatorInset:UIEdgeInsetsMake(0, self.tableView.frame.size.width * 2, 0, 0)];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	if (collectionView == _platformsCollectionView)
		return _platforms.count;
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
	if (collectionView == _platformsCollectionView){
		Platform *platform = _platforms[indexPath.item];
		PlatformCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		[cell.platformLabel setText:platform.abbreviation];
		[cell.platformLabel setBackgroundColor:platform.color];
		return cell;
	}
	else if (collectionView == _similarGamesCollectionView){
		SimilarGame *similarGame = _similarGames[indexPath.row];
		SimilarGameCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		[cell.coverImageView setImageWithURL:[NSURL URLWithString:similarGame.thumbnailURL] placeholderImage:[Tools imageWithColor:[UIColor darkGrayColor]]];
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
			[nextCell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:nextVideo.thumbnailURL]] placeholderImage:[Tools imageWithColor:[UIColor blackColor]] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
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
		[cell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:video.thumbnailURL]] placeholderImage:[Tools imageWithColor:[UIColor blackColor]] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
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
				TrailerViewController *player = [[TrailerViewController alloc] initWithContentURL:[NSURL URLWithString:video.highQualityURL]];
				[self presentMoviePlayerViewControllerAnimated:player];
			}
		}
	}
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
			//		NSLog(@"%@", JSON);
			
			_game = [Game MR_findFirstByAttribute:@"identifier" withValue:identifier inContext:_context];
			if (!_game) _game = [Game MR_createInContext:_context];
			
			[Networking updateGame:_game withDataFromJSON:responseObject context:_context];
			for (SimilarGame *similarGame in _game.similarGames)
				[self requestImageForSimilarGame:similarGame];
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
				
				UIImage *coverImage = [UIImage imageWithData:_game.coverImage.data];
				CGSize optimalSize = [Session optimalCoverImageSizeForImage:coverImage type:GameImageTypeCover];
				
				if (!_game.thumbnailWishlist || !_game.thumbnailLibrary || !_game.coverImage.data || ![_game.coverImage.url isEqualToString:coverImageURL] || (coverImage.size.width != optimalSize.width || coverImage.size.height != optimalSize.height)){
					[self downloadImageForCoverImage:_game.coverImage];
				}
				
				[self requestMediaForGame:_game];
				
				[self refreshAnimated:NO];
				
				[self.tableView reloadData];
				
				[_platformsCollectionView reloadData];
				[_similarGamesCollectionView reloadData];
				
				// If game is released and has at least one platform, request metascore
				if ([_game.releasePeriod.identifier isEqualToNumber:@(1)] && _selectablePlatforms.count > 0){
					[self requestMetascoreForGameWithTitle:_game.title platform:_selectablePlatforms.firstObject];
				}
			}];
		}
		
		[self.refreshControl endRefreshing];
	}];
	[dataTask resume];
}

- (void)downloadImageForCoverImage:(CoverImage *)coverImage{
	if (!coverImage.url) return;
	
	[_activityIndicator startAnimating];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:coverImage.url]];
	
	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), request.URL.lastPathComponent]];
		[[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
		return fileURL;
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		[_activityIndicator stopAnimating];
		
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Cover Image", self, (long)((NSHTTPURLResponse *)response).statusCode);
		}
		else{
			NSLog(@"Success in %@ - Status code: %ld - Cover Image - Size: %lld bytes", self, (long)((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			NSData *downloadedData = [NSData dataWithContentsOfURL:filePath];
			UIImage *downloadedImage = [UIImage imageWithData:downloadedData];
			
			[coverImage setData:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeCover])];
			[_game setThumbnailWishlist:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeWishlist])];
			[_game setThumbnailLibrary:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeLibrary])];
			
			[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"CoverImageDownloaded" object:nil];
				[self setCoverImageAnimated:YES];
			}];
		}
	}];
	[downloadTask resume];
}

- (void)requestMetascoreForGameWithTitle:(NSString *)title platform:(Platform *)platform{
	NSURLRequest *request = [Networking requestForMetascoreForGameWithTitle:title platform:platform];
	
	if (request.URL){
		NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
			NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), request.URL.lastPathComponent]];
			[[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
			return fileURL;
		} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
			if (error){
				NSLog(@"Failure in %@ - Metascore", self);
			}
			else{
				NSLog(@"Success in %@ - Metascore - %@", self, request.URL);
				
				NSString *HTML = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:filePath] encoding:NSUTF8StringEncoding];
				//			NSLog(@"HTML: %@", HTML);
				
				[_game setMetacriticURL:request.URL.absoluteString];
				
				if (HTML){
					NSString *metascore = [Networking retrieveMetascoreFromHTML:HTML];
					[_game setMetascore:metascore];
					
					[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
						[_metascoreButton setHidden:NO];
						[_metascoreButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
						
						if (metascore.length > 0 && [[NSScanner scannerWithString:metascore] scanInteger:nil]){
							[_metascoreButton setBackgroundColor:[Networking colorForMetascore:metascore]];
							[_metascoreButton.titleLabel setFont:[UIFont boldSystemFontOfSize:30]];
							[_metascoreButton setTitle:metascore forState:UIControlStateNormal];
							
							[_metascorePlatformLabel setText:platform.name];
							[_metascorePlatformLabel setHidden:NO];
							[_metascorePlatformLabel.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
							
							[_game setMetacriticURL:request.URL.absoluteString];
							[_game setMetascorePlatform:platform];
							
							if (_game.wishlistPlatform && _game.wishlistPlatform == _game.metascorePlatform){
								[_game setWishlistMetascore:metascore];
								[_game setWishlistMetascorePlatform:platform];
								[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
							}
						}
						else{
							if (_selectablePlatforms.count > ([_selectablePlatforms indexOfObject:platform] + 1))
								[self requestMetascoreForGameWithTitle:title platform:_selectablePlatforms[[_selectablePlatforms indexOfObject:platform] + 1]];
							else{
								[_metascoreButton setBackgroundColor:[UIColor darkGrayColor]];
								[_metascoreButton.titleLabel setFont:[UIFont boldSystemFontOfSize:10]];
								[_metascoreButton setTitle:@"Metacritic" forState:UIControlStateNormal];
								[_metascoreButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
							}
						}
					}];
				}
				else if (_selectablePlatforms.count > ([_selectablePlatforms indexOfObject:platform] + 1))
					[self requestMetascoreForGameWithTitle:title platform:_selectablePlatforms[[_selectablePlatforms indexOfObject:platform] + 1]];
				else
					[_context MR_saveToPersistentStoreAndWait];
			}
		}];
		[downloadTask resume];
	}
}

- (void)requestImageForSimilarGame:(SimilarGame *)similarGame{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:similarGame.identifier fields:@"image"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %ld - Game", self, (long)((NSHTTPURLResponse *)response).statusCode);
			
			[self.navigationItem.rightBarButtonItem setEnabled:YES];
		}
		else{
//			NSLog(@"Success in %@ - Status code: %d - Similar Game Image - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			//		NSLog(@"%@", JSON);
			
			NSDictionary *results = responseObject[@"results"];
			
			if (results[@"image"] != [NSNull null])
				[similarGame setThumbnailURL:[Tools stringFromSourceIfNotNull:results[@"image"][@"thumb_url"]]];
			
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
				[video setThumbnailURL:[Tools stringFromSourceIfNotNull:results[@"image"][@"super_url"]]];
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

#pragma mark - ActionSheet

// REWRITE

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex){
		if (actionSheet.tag == ActionSheetTagWishlist)
			[self addGameToWishlistWithPlatform:_selectablePlatforms[buttonIndex]];
		else
			[self addGameToLibraryWithPlatform:_selectablePlatforms[buttonIndex]];
	}
	else{
		dispatch_async(dispatch_get_main_queue(), ^{
			[_wishlistButton setHighlighted:NO];
			[_libraryButton setHighlighted:NO];
		});
	}
}

#pragma mark - Custom

- (void)setCoverImageAnimated:(BOOL)animated{
	if (animated){
		[_coverImageView setImage:[UIImage imageWithData:_game.coverImage.data]];
		[_coverImageView.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	}
	else
		[_coverImageView setImage:[UIImage imageWithData:_game.coverImage.data]];
	
	[Tools addDropShadowToView:_coverImageView color:[UIColor blackColor] opacity:1 radius:10 offset:CGSizeMake(0, 5) bounds:[Tools frameForImageInImageView:_coverImageView]];
}

- (void)refreshAnimated:(BOOL)animated{
	[self setCoverImageAnimated:animated];
	
	[_titleLabel setText:_game.title];
	
	[_releaseDateLabel setText:_game.releaseDateText];
	
	_platforms = [self orderedPlatformsFromGame:_game];
	
	_selectablePlatforms = [self selectablePlatformsFromGame:_game];
	
	_similarGames = [self orderedSimilarGamesFromGame:_game];
	
	[self refreshAddButtonsAnimated:animated];
	
	[_preorderedSwitch setOn:_game.preordered.boolValue animated:animated];
	[_completedSwitch setOn:_game.completed.boolValue animated:animated];
	[_loanedSwitch setOn:_game.loaned.boolValue animated:animated];
	[_digitalSwitch setOn:_game.digital.boolValue animated:animated];
	
	if (_game.metascore.length > 0){
		[_metascoreButton setBackgroundColor:[Networking colorForMetascore:_game.metascore]];
		[_metascoreButton.titleLabel setFont:[UIFont boldSystemFontOfSize:30]];
		[_metascoreButton setTitle:_game.metascore forState:UIControlStateNormal];
		[_metascorePlatformLabel setText:_game.metascorePlatform.name];
	}
	else if (_game.metacriticURL.length > 0){
		[_metascoreButton setBackgroundColor:[UIColor darkGrayColor]];
		[_metascoreButton.titleLabel setFont:[UIFont boldSystemFontOfSize:10]];
		[_metascoreButton setTitle:@"Metacritic" forState:UIControlStateNormal];
		[_metascorePlatformLabel setHidden:YES];
	}
	else{
		[_metascoreButton setHidden:YES];
		[_metascorePlatformLabel setHidden:YES];
	}
	
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
		[_libraryButton setHidden:([_game.released isEqualToNumber:@(YES)] || [_game.owned isEqualToNumber:@(YES)]) ? NO : YES];
	}
	else{
		[_wishlistButton setHidden:[_game.wanted isEqualToNumber:@(YES)] ? NO : YES];
		[_libraryButton setHidden:[_game.owned isEqualToNumber:@(YES)] ? NO : YES];
	}
	
	[_wishlistButton setTitle:[_game.wanted isEqualToNumber:@(YES)] ? @"REMOVE FROM WISHLIST" : @"ADD TO WISHLIST" forState:UIControlStateNormal];
	[_libraryButton setTitle:[_game.owned isEqualToNumber:@(YES)] ? @"REMOVE FROM LIBRARY" : @"ADD TO LIBRARY" forState:UIControlStateNormal];
	
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
		return [platform1.index compare:platform2.index] == NSOrderedAscending;
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

- (void)addGameToWishlistWithPlatform:(Platform *)platform{
	[_game setWishlistPlatform:platform];
	[_game setLibraryPlatform:nil];
	
	// If release period is collapsed, set game to hidden
	if ([_game.releasePeriod.placeholderGame.hidden isEqualToNumber:@(NO)]){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (hidden = %@ AND wanted = %@)", _game.releasePeriod.identifier, @(NO), @(YES)];
		NSInteger gamesCount = [Game MR_countOfEntitiesWithPredicate:predicate];
		[_game setHidden:(gamesCount == 0) ? @(YES) : @(NO)];
	}
	
	[_game setWanted:@(YES)];
	[_game setOwned:@(NO)];
	
	[_game setPreordered:@(NO)];
	[_game setCompleted:@(NO)];
	[_game setLoaned:@(NO)];
	[_game setDigital:@(NO)];
	
	[_game setWishlistMetascore:(_game.wishlistPlatform && _game.wishlistPlatform == _game.metascorePlatform) ? _game.metascore : nil];
	
	[self saveAndRefreshAfterStateChange];
}

- (void)addGameToLibraryWithPlatform:(Platform *)platform{
	[_game setWishlistPlatform:nil];
	[_game setLibraryPlatform:platform];
	
	[_game setWanted:@(NO)];
	[_game setOwned:@(YES)];
	
	[_game setPreordered:@(NO)];
	[_game setCompleted:@(NO)];
	[_game setLoaned:@(NO)];
	[_game setDigital:@(NO)];
	
	[self saveAndRefreshAfterStateChange];
}

- (void)removeGameFromWishlistOrLibrary{
	[_game setWanted:@(NO)];
	[_game setOwned:@(NO)];
	
	[_game setWishlistPlatform:nil];
	[_game setLibraryPlatform:nil];
	
	[_game setPreordered:@(NO)];
	[_game setCompleted:@(NO)];
	[_game setLoaned:@(NO)];
	[_game setDigital:@(NO)];
	
	[self saveAndRefreshAfterStateChange];
}

- (void)saveAndRefreshAfterStateChange{
	[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		[self refreshAddButtonsAnimated:YES];
		
		[_preorderedSwitch setOn:_game.preordered.boolValue animated:YES];
		[_completedSwitch setOn:_game.completed.boolValue animated:YES];
		[_loanedSwitch setOn:_game.loaned.boolValue animated:YES];
		[_digitalSwitch setOn:_game.digital.boolValue animated:YES];
		
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionStatus] withRowAnimation:UITableViewRowAnimationAutomatic];
		
		[_wishlistButton setHighlighted:NO];
		[_libraryButton setHighlighted:NO];
		
		NSIndexPath *lastStatusIndexPath = [NSIndexPath indexPathForRow:([self.tableView numberOfRowsInSection:SectionStatus] - 1) inSection:SectionStatus];
		if ((([_game.wanted isEqualToNumber:@(YES)] && [_game.released isEqualToNumber:@(NO)]) || [_game.owned isEqualToNumber:@(YES)]) && ![self.tableView.indexPathsForVisibleRows containsObject:lastStatusIndexPath])
			[self.tableView scrollToRowAtIndexPath:lastStatusIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
	}];
}

#pragma mark - Actions

// REWRITE

- (IBAction)addButtonPressAction:(UIButton *)sender{
	dispatch_async(dispatch_get_main_queue(), ^{
		[sender setHighlighted:YES];
	});
	
	// Removing from wishlist or library
	if ((sender == _wishlistButton && [_game.wanted isEqualToNumber:@(YES)]) || (sender == _libraryButton && [_game.owned isEqualToNumber:@(YES)])){
		[self removeGameFromWishlistOrLibrary];
	}
	else{
		// Multiple platforms to select
		if (_selectablePlatforms.count > 1){
			UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
			[actionSheet setTag:(sender == _wishlistButton) ? ActionSheetTagWishlist : ActionSheetTagLibrary];
			
			for (Platform *platform in _selectablePlatforms)
				[actionSheet addButtonWithTitle:platform.name];
			[actionSheet addButtonWithTitle:@"Cancel"];
			[actionSheet setCancelButtonIndex:_selectablePlatforms.count];
			
			[actionSheet showInView:self.view.window];
		}
		// Single platform
		else{
			if (sender == _wishlistButton)
				[self addGameToWishlistWithPlatform:(_selectablePlatforms.count > 0) ? _selectablePlatforms.firstObject : nil];
			else
				[self addGameToLibraryWithPlatform:(_selectablePlatforms.count > 0) ? _selectablePlatforms.firstObject : nil];
		}
	}
}

- (IBAction)statusSwitchAction:(UISwitch *)sender{
	if (sender == _preorderedSwitch)
		[_game setPreordered:@(sender.isOn)];
	else if (sender == _completedSwitch)
		[_game setCompleted:@(sender.isOn)];
	else if (sender == _loanedSwitch){
		[_game setLoaned:@(sender.isOn)];
		if (sender.isOn){
			[_digitalSwitch setOn:NO animated:YES];
			[_game setDigital:@(NO)];
		}
	}
	else if (sender == _digitalSwitch){
		[_game setDigital:@(sender.isOn)];
		if (sender.isOn){
			[_loanedSwitch setOn:NO animated:YES];
			[_game setLoaned:@(NO)];
		}
	}
	
	[_context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		if (sender != _preorderedSwitch)
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
		else
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlist" object:nil];
	}];
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
	if ([segue.identifier isEqualToString:@"ViewerSegue"]){
		Image *image = sender;
		
		ImageViewerViewController *destination = segue.destinationViewController;
		[destination setImage:image];
	}
	else if ([segue.identifier isEqualToString:@"MetacriticSegue"]){
		MetacriticViewController *destination = segue.destinationViewController;
		[destination setURL:[NSURL URLWithString:_game.metacriticURL]];
	}
	else if ([segue.identifier isEqualToString:@"SimilarGameSegue"]){
		GameTableViewController *destination = segue.destinationViewController;
		[destination setGameIdentifier:sender];
	}
}

@end
