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
#import <AFNetworking/AFNetworking.h>
#import "SimilarGameCollectionCell.h"

enum {
    SectionCover,
    SectionStatus,
	SectionDetails,
	SectionImages,
	SectionVideos
};

@interface GameTableViewController () <UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet MACircleProgressIndicator *progressIndicator;
@property (nonatomic, strong) IBOutlet UIButton *metascoreButton;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *releaseDateLabel;
@property (nonatomic, strong) IBOutlet UIButton *wishlistButton;
@property (nonatomic, strong) IBOutlet UIButton *libraryButton;
@property (nonatomic, strong) IBOutlet UISwitch *preorderedSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *completedSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *loanedSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *digitalSwitch;
@property (nonatomic, strong) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, strong) IBOutlet UILabel *genreFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreSecondLabel;
@property (nonatomic, strong) IBOutlet UILabel *themeFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *themeSecondLabel;
@property (nonatomic, strong) IBOutlet UILabel *franchiseLabel;
@property (nonatomic, strong) IBOutlet UILabel *developerLabel;
@property (nonatomic, strong) IBOutlet UILabel *publisherLabel;
@property (nonatomic, strong) IBOutlet UICollectionView *platformsCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *similarGamesCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *imagesCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *videosCollectionView;

@property (nonatomic, strong) ContentStatusView *imagesStatusView;
@property (nonatomic, strong) ContentStatusView *videosStatusView;

@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSOperationQueue *videosOperationQueue;

@property (nonatomic, strong) NSArray *platforms;
@property (nonatomic, strong) NSArray *similarGames;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSArray *videos;

@property (nonatomic, strong) NSArray *selectablePlatforms;

@end

@implementation GameTableViewController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	[_wishlistButton setBackgroundImage:[[UIImage imageNamed:@"AddButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateNormal];
	[_wishlistButton setBackgroundImage:[[UIImage imageNamed:@"AddButtonHighlighted"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateHighlighted];
	[_libraryButton setBackgroundImage:[[UIImage imageNamed:@"AddButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateNormal];
	[_libraryButton setBackgroundImage:[[UIImage imageNamed:@"AddButtonHighlighted"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateHighlighted];
	
	[Tools setMaskToView:_metascoreButton roundCorners:UIRectCornerAllCorners radius:32];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	_operationQueue = [[NSOperationQueue alloc] init];
	[_operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
	
	_imagesStatusView = [[ContentStatusView alloc] initWithUnavailableTitle:@"No images available"];
	_videosStatusView = [[ContentStatusView alloc] initWithUnavailableTitle:@"No videos available"];
	[_imagesCollectionView addSubview:_imagesStatusView];
	[_videosCollectionView addSubview:_videosStatusView];
	
	if (!_game)
		_game = [Game findFirstByAttribute:@"identifier" withValue:_searchResult.identifier];
	if (_game){
		[self refreshAnimated:NO];
		
		_platforms = [Platform findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self IN %@", _game.platforms]];
		
		_selectablePlatforms = [Platform findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self in %@ AND self in %@", [SessionManager gamer].platforms, _game.platforms]];
		
		_similarGames = [SimilarGame findAllSortedBy:@"title" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self in %@", _game.similarGames]];
		
		_images = [Image findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game.identifier = %@", _game.identifier]];
		_videos = [Video findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game.identifier = %@ AND type = %@", _game.identifier, @"Trailers"]];
		
		(_images.count == 0) ? [_imagesStatusView setStatus:ContentStatusUnavailable] : [_imagesStatusView setHidden:YES];
		(_videos.count == 0) ? [_videosStatusView setStatus:ContentStatusUnavailable] : [_videosStatusView setHidden:YES];
		
		[_context saveToPersistentStoreAndWait];
	}
	else{
		[_imagesStatusView setStatus:ContentStatusLoading];
		[_videosStatusView setStatus:ContentStatusLoading];
		[self requestGameWithIdentifier:_searchResult.identifier];
	}
	
	[_progressIndicator setColor:[UIColor whiteColor]];
}

- (void)viewDidLayoutSubviews{
	[_imagesStatusView setFrame:_imagesCollectionView.frame];
	[_videosStatusView setFrame:_videosCollectionView.frame];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] set:kGAIScreenName value:@"Game"];
	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
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
	if (section == SectionStatus){
		if ([_game.wanted isEqualToNumber:@(YES)] && [_game.released isEqualToNumber:@(NO)])
			return 1;
		else if ([_game.owned isEqualToNumber:@(YES)])
			return 3;
		else
			return 0;
	}
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	// Description text height
	if (indexPath.section == SectionDetails && indexPath.row == 0){
		CGRect textRect = [_game.overview boundingRectWithSize:CGSizeMake(_descriptionTextView.frame.size.width - 10, 50000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil];
		return textRect.size.height + 40;
	}
	// Platform collection height (iPhone)
	else if (indexPath.section == SectionDetails && indexPath.row == 2 && [Tools deviceIsiPhone])
		return (_platforms.count > 4) ? 123 : 100;
	else if (indexPath.section == SectionDetails && ((indexPath.row == 2 && [Tools deviceIsiPad]) || (indexPath.row == 2 && [Tools deviceIsiPhone])))
		return (_game.similarGames.count > 0) ? 150 : 0;
	// Images collection height (iPad)
	else if ([Tools deviceIsiPad] && indexPath.section == SectionImages && _images.count <= 3)
		return 180;
	else
		return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	if (indexPath.section == SectionStatus && [_game.owned isEqualToNumber:@(YES)])
		return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
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
		// Push game?
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
	NSURLRequest *request = [Networking requestForGameWithIdentifier:identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Game - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
//		NSLog(@"%@", JSON);
		
		_game = [Game findFirstByAttribute:@"identifier" withValue:identifier];
		if (!_game) _game = [Game createInContext:_context];
		
		[Networking updateGame:_game withDataFromJSON:JSON context:_context];
		for (SimilarGame *similarGame in _game.similarGames)
			[self requestImageForSimilarGame:similarGame];
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			NSString *coverImageURL = [Tools stringFromSourceIfNotNull:JSON[@"results"][@"image"][@"super_url"]];
			if (!_game.thumbnailWishlist || !_game.thumbnailLibrary || !_game.coverImage.data || ![_game.coverImage.url isEqualToString:coverImageURL])
				[self downloadImageForCoverImage:_game.coverImage];
			else
				[self requestMediaForGame:_game];
			
			[self refreshAnimated:NO];
			
			_platforms = [Platform findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self IN %@", _game.platforms]];
			[_platformsCollectionView reloadData];
			
			_similarGames = [SimilarGame findAllSortedBy:@"title" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self in %@", _game.similarGames]];
			[_similarGamesCollectionView reloadData];
			
			[self.tableView reloadData];
			
			_selectablePlatforms = [Platform findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self in %@ AND self in %@", [SessionManager gamer].platforms, _game.platforms]];
			
			// If game is released and has at least one platform, request metascore
			if ([_game.releasePeriod.identifier isEqualToNumber:@(1)] && _selectablePlatforms.count > 0)
				[self requestMetascoreForGameWithTitle:_game.title platform:_selectablePlatforms[0]];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Game", self, response.statusCode);
		
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}];
	[_operationQueue addOperation:operation];
}

- (void)downloadImageForCoverImage:(CoverImage *)coverImage{
	[_progressIndicator setValue:0];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:coverImage.url]];
	[request setHTTPMethod:@"GET"];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:^UIImage *(UIImage *image) {
		[self requestMediaForGame:_game];
		
		if (image.size.width > image.size.height){
			[coverImage setData:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:_coverImageView.frame.size.width])];
			[_game setThumbnailWishlist:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:[Tools deviceIsiPad] ? 216 : 50])];
			[_game setThumbnailLibrary:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:[Tools deviceIsiPad] ? 140 : 92])];
		}
		else{
			[coverImage setData:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:_coverImageView.frame.size.height])];
			[_game setThumbnailWishlist:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:[Tools deviceIsiPad] ? 140 : 50])];
			[_game setThumbnailLibrary:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:[Tools deviceIsiPad] ? 176 : 116])];
		}
		return nil;
	} success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"CoverImageDownloaded" object:nil];
			[self setCoverImageAnimated:YES];
		}];
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
		[self requestMediaForGame:_game];
	}];
	[operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
		//		NSLog(@"Received %lld of %lld bytes", totalBytesRead, totalBytesExpectedToRead);
		[_progressIndicator setValue:(float)totalBytesRead/(float)totalBytesExpectedToRead];
	}];
	[_operationQueue addOperation:operation];
}

- (void)requestMetascoreForGameWithTitle:(NSString *)title platform:(Platform *)platform{
	NSString *formattedTitle = title.lowercaseString;
	formattedTitle = [formattedTitle stringByReplacingOccurrencesOfString:@"'" withString:@""];
	formattedTitle = [formattedTitle stringByReplacingOccurrencesOfString:@":" withString:@""];
	formattedTitle = [formattedTitle stringByReplacingOccurrencesOfString:@"& " withString:@""];
	formattedTitle = [formattedTitle stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	
	NSString *formattedPlatform = platform.name.lowercaseString;
	formattedPlatform = [formattedPlatform stringByReplacingOccurrencesOfString:@"nintendo " withString:@""];
	formattedPlatform = [formattedPlatform stringByReplacingOccurrencesOfString:@"'" withString:@""];
	formattedPlatform = [formattedPlatform stringByReplacingOccurrencesOfString:@":" withString:@""];
	formattedPlatform = [formattedPlatform stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	
	NSString *url = [NSString stringWithFormat:@"http://www.metacritic.com/game/%@/%@", formattedPlatform, formattedTitle];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"Success in %@ - Metascore - %@", self, request.URL);
		
		NSString *html = [NSString stringWithUTF8String:[responseObject bytes]];
		
//		NSLog(@"%@", html);
		
		if (html){
			// Regex magic
			NSRegularExpression *firstExpression = [NSRegularExpression regularExpressionWithPattern:@"ratingValue\">" options:NSRegularExpressionCaseInsensitive error:nil];
			NSTextCheckingResult *firstResult = [firstExpression firstMatchInString:html options:NSMatchingReportProgress range:NSMakeRange(0, html.length)];
			NSUInteger startIndex = firstResult.range.location + firstResult.range.length;
			
			NSRegularExpression *secondExpression = [NSRegularExpression regularExpressionWithPattern:@"<" options:NSRegularExpressionCaseInsensitive error:nil];
			NSTextCheckingResult *secondResult = [secondExpression firstMatchInString:html options:NSMatchingReportProgress range:NSMakeRange(startIndex, html.length - startIndex)];
			NSUInteger endIndex = secondResult.range.location;
			
			NSString *metascore = [html substringWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
			
			NSLog(@"Metascore: %@", metascore);
			
			[_game setMetascore:metascore];
			[_game setMetacriticURL:url];
			
			[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				if (metascore.length > 0){
					[_metascoreButton setBackgroundColor:[self colorForMetascore:metascore]];
					[_metascoreButton setHidden:NO];
					[_metascoreButton setTitle:metascore forState:UIControlStateNormal];
				}
				else{
					if (_selectablePlatforms.count > ([_selectablePlatforms indexOfObject:platform] + 1))
						[self requestMetascoreForGameWithTitle:title platform:_selectablePlatforms[[_selectablePlatforms indexOfObject:platform] + 1]];
					else
						[_metascoreButton setHidden:YES];
				}
				[_metascoreButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
			}];
		}
		else{
			if (_selectablePlatforms.count > ([_selectablePlatforms indexOfObject:platform] + 1))
				[self requestMetascoreForGameWithTitle:title platform:_selectablePlatforms[[_selectablePlatforms indexOfObject:platform] + 1]];
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Failure in %@ - Metascore", self);
	}];
	[_operationQueue addOperation:operation];
}

- (void)requestImageForSimilarGame:(SimilarGame *)similarGame{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:similarGame.identifier fields:@"image"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Similar Game - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
//		NSLog(@"%@", JSON);
		
		NSDictionary *results = JSON[@"results"];
		
		if (results[@"image"] != [NSNull null])
			[similarGame setThumbnailURL:[Tools stringFromSourceIfNotNull:results[@"image"][@"thumb_url"]]];
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[_similarGamesCollectionView reloadData];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Game", self, response.statusCode);
		
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}];
	[_operationQueue addOperation:operation];
}

- (void)requestMediaForGame:(Game *)game{
	[_imagesStatusView setStatus:ContentStatusLoading];
	[_videosStatusView setStatus:ContentStatusLoading];
	
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"images,videos"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Media - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		//		NSLog(@"%@", JSON);
		
		NSDictionary *results = JSON[@"results"];
		
		// Images
		if (results[@"images"] != [NSNull null]){
			NSInteger index = 0;
			for (NSDictionary *dictionary in results[@"images"]){
				NSString *stringURL = [Tools stringFromSourceIfNotNull:dictionary[@"super_url"]];
				Image *image = [Image findFirstByAttribute:@"thumbnailURL" withValue:stringURL inContext:_context];
				if (!image){
					image = [Image createInContext:_context];
					
					[image setThumbnailURL:stringURL];
					[image setOriginalURL:[stringURL stringByReplacingOccurrencesOfString:@"scale_large" withString:@"original"]];
				}
				
				[image setIndex:@(index)];
				[game addImagesObject:image];
				
				index++;
			}
			
			// No images available
			if (index == 0){
				[_imagesStatusView setStatus:ContentStatusUnavailable];
			}
			[_imagesStatusView setHidden:(index == 0) ? NO : YES];
		}
		
		_videosOperationQueue = [[NSOperationQueue alloc] init];
		[_videosOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
		
		// Videos
		if (results[@"videos"] != [NSNull null]){
			NSInteger index = 0;
			for (NSDictionary *dictionary in results[@"videos"]){
				NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
				Video *video = [Video findFirstByAttribute:@"identifier" withValue:identifier inContext:_context];
				if (!video){
					video = [Video createInContext:_context];
					[video setIdentifier:identifier];
				}
				
				[video setIndex:@(index)];
				[video setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"title"]]];
				[game addVideosObject:video];
				
				[self requestInformationForVideo:video];
				
				index++;
			}
			
			// No videos available
			if (index == 0)
				[_videosStatusView setStatus:ContentStatusUnavailable];
		}
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self.navigationItem.rightBarButtonItem setEnabled:YES];
			
			_images = [Image findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game.identifier = %@", game.identifier]];
			if ([Tools deviceIsiPad]){
				[self.tableView beginUpdates];
				[self.tableView endUpdates];
			}
			[_imagesCollectionView reloadData];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d", self, response.statusCode);
		
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}];
	[_operationQueue addOperation:operation];
}

- (void)requestInformationForVideo:(Video *)video{
	NSURLRequest *request = [Networking requestForVideoWithIdentifier:video.identifier fields:@"id,name,deck,video_type,length_seconds,publish_date,high_url,low_url,image"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		//		NSLog(@"Success in %@ - Status code: %d - Video - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		//		NSLog(@"%@", JSON);
		
		[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		if ([JSON[@"status_code"] isEqualToNumber:@(101)]){
			[video deleteEntity];
			[_context saveToPersistentStoreAndWait];
			return;
		}
		
		NSDictionary *results = JSON[@"results"];
		
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
			[video deleteEntity];
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			if (_videosOperationQueue.operationCount == 0){
				_videos = [Video findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game.identifier = %@", _game.identifier]];
				
				if (_videos.count == 0){
					[_videosStatusView setStatus:ContentStatusUnavailable];
					[_videosStatusView setHidden:NO];
				}
				else{
					[_videosCollectionView reloadData];
					[_videosStatusView setHidden:YES];
				}
			}
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		NSLog(@"Failure in %@ - Status code: %d - Video", self, response.statusCode);
	}];
	[_videosOperationQueue addOperation:operation];
}

#pragma mark - ActionSheet

// REWRITE

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex){
		if (actionSheet.tag == 1){
			if ([_game.wanted isEqualToNumber:@(YES)]){
				[_game setWanted:@(NO)];
				[_game setOwned:@(NO)];
			}
			else{
				[_game setWishlistPlatform:_selectablePlatforms[buttonIndex]];
				
				if ([_game.releasePeriod.placeholderGame.hidden isEqualToNumber:@(NO)]){
					NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (hidden = %@ AND wanted = %@)", _game.releasePeriod.identifier, @(NO), @(YES)];
					NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
					[_game setHidden:(gamesCount == 0) ? @(YES) : @(NO)];
				}
				
				[_game setWanted:@(YES)];
				[_game setOwned:@(NO)];
			}
		}
		else{
			if ([_game.owned isEqualToNumber:@(YES)]){
				[_game setWanted:@(NO)];
				[_game setOwned:@(NO)];
			}
			else{
				[_game setLibraryPlatform:_selectablePlatforms[buttonIndex]];
				[_game setWanted:@(NO)];
				[_game setOwned:@(YES)];
			}
		}
		
		[_game setPreordered:@(NO)];
		[_game setCompleted:@(NO)];
		[_game setLoaned:@(NO)];
		[_game setDigital:@(NO)];
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[_wishlistButton setTitle:[_game.wanted isEqualToNumber:@(YES)] ? @"REMOVE FROM WISHLIST" : @"ADD TO WISHLIST" forState:UIControlStateNormal];
			[_wishlistButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
			[_libraryButton setTitle:[_game.owned isEqualToNumber:@(YES)] ? @"REMOVE FROM LIBRARY" : @"ADD TO LIBRARY" forState:UIControlStateNormal];
			[_libraryButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
			
			[_preorderedSwitch setOn:_game.preordered.boolValue animated:YES];
			[_completedSwitch setOn:_game.completed.boolValue animated:YES];
			[_loanedSwitch setOn:_game.loaned.boolValue animated:YES];
			[_digitalSwitch setOn:_game.digital.boolValue animated:YES];
			
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionStatus] withRowAnimation:UITableViewRowAnimationAutomatic];
			
			if ([Tools deviceIsiPad]) [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlistCollection" object:nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
		}];
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
	
	[_wishlistButton setHidden:NO];
	[_wishlistButton setTitle:[_game.wanted isEqualToNumber:@(YES)] ? @"REMOVE FROM WISHLIST" : @"ADD TO WISHLIST" forState:UIControlStateNormal];
	[_libraryButton setHidden:([_game.owned isEqualToNumber:@(NO)] && [_game.released isEqualToNumber:@(NO)]) ? YES : NO];
	[_libraryButton setTitle:[_game.owned isEqualToNumber:@(YES)] ? @"REMOVE FROM LIBRARY" : @"ADD TO LIBRARY" forState:UIControlStateNormal];
	
	[_preorderedSwitch setOn:_game.preordered.boolValue animated:animated];
	[_completedSwitch setOn:_game.completed.boolValue animated:animated];
	[_loanedSwitch setOn:_game.loaned.boolValue animated:animated];
	[_digitalSwitch setOn:_game.digital.boolValue animated:animated];
	
	[_metascoreButton setBackgroundColor:[self colorForMetascore:_game.metascore]];
	[_metascoreButton setTitle:_game.metascore forState:UIControlStateNormal];
	[_metascoreButton setHidden:(_game.metascore.length > 0) ? NO : YES];
	
	[_descriptionTextView setText:_game.overview];
	[_genreFirstLabel setText:(_game.genres.count > 0) ? [_game.genres.allObjects[0] name] : @"Not available"];
	[_genreSecondLabel setText:(_game.genres.count > 1) ? [_game.genres.allObjects[1] name] : @""];
	[_themeFirstLabel setText:(_game.themes.count > 0) ? [_game.themes.allObjects[0] name] : @"Not available"];
	[_themeSecondLabel setText:(_game.themes.count > 1) ? [_game.themes.allObjects[1] name] : @""];
	[_franchiseLabel setText:(_game.franchises.count > 0) ? [_game.franchises.allObjects[0] name] : @"Not available"];
	[_developerLabel setText:(_game.developers.count > 0) ? [_game.developers.allObjects[0] name] : @"Not available"];
	[_publisherLabel setText:(_game.publishers.count > 0) ? [_game.publishers.allObjects[0] name] : @"Not available"];
}

- (UIColor *)colorForMetascore:(NSString *)metascore{
	if (metascore.integerValue >= 75)
		return [UIColor colorWithRed:.384313725 green:.807843137 blue:.129411765 alpha:1];
	else if (metascore.integerValue >= 50)
		return [UIColor colorWithRed:1 green:.803921569 blue:.058823529 alpha:1];
	else
		return [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
}

#pragma mark - Actions

// REWRITE

- (IBAction)addButtonPressAction:(UIButton *)sender{
	if ((sender == _wishlistButton && [_game.wanted isEqualToNumber:@(YES)]) || (sender == _libraryButton && [_game.owned isEqualToNumber:@(YES)])){
		[_game setWanted:@(NO)];
		[_game setOwned:@(NO)];
		
		[_game setWishlistPlatform:nil];
		[_game setLibraryPlatform:nil];
		
		[_game setPreordered:@(NO)];
		[_game setCompleted:@(NO)];
		[_game setLoaned:@(NO)];
		[_game setDigital:@(NO)];
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[_wishlistButton setTitle:[_game.wanted isEqualToNumber:@(YES)] ? @"REMOVE FROM WISHLIST" : @"ADD TO WISHLIST" forState:UIControlStateNormal];
			[_wishlistButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
			[_libraryButton setTitle:[_game.owned isEqualToNumber:@(YES)] ? @"REMOVE FROM LIBRARY" : @"ADD TO LIBRARY" forState:UIControlStateNormal];
			[_libraryButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
			
			[_preorderedSwitch setOn:_game.preordered.boolValue animated:YES];
			[_completedSwitch setOn:_game.completed.boolValue animated:YES];
			[_loanedSwitch setOn:_game.loaned.boolValue animated:YES];
			[_digitalSwitch setOn:_game.digital.boolValue animated:YES];
			
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionStatus] withRowAnimation:UITableViewRowAnimationAutomatic];
			
			if ([Tools deviceIsiPad]) [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlistCollection" object:nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
		}];
	}
	else{
		if (_selectablePlatforms.count > 1){
			UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
			[actionSheet setTag:(sender == _wishlistButton) ? 1 : 2];
			
			for (Platform *platform in _selectablePlatforms)
				[actionSheet addButtonWithTitle:platform.name];
			[actionSheet addButtonWithTitle:@"Cancel"];
			[actionSheet setCancelButtonIndex:_selectablePlatforms.count];
			
			[actionSheet showInView:self.tabBarController.view];
		}
		else{
			if (sender == _wishlistButton){
				if (_selectablePlatforms.count > 0){
					[_game setWishlistPlatform:_selectablePlatforms[0]];
					[_game setLibraryPlatform:nil];
				}
				
				// If release period is collapsed, set game to hidden
				if ([_game.releasePeriod.placeholderGame.hidden isEqualToNumber:@(NO)]){
					NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (hidden = %@ AND wanted = %@)", _game.releasePeriod.identifier, @(NO), @(YES)];
					NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
					[_game setHidden:(gamesCount == 0) ? @(YES) : @(NO)];
				}
				
				[_game setWanted:@(YES)];
				[_game setOwned:@(NO)];
			}
			else{
				if (_selectablePlatforms.count > 0){
					[_game setWishlistPlatform:nil];
					[_game setLibraryPlatform:_selectablePlatforms[0]];
				}
				
				[_game setWanted:@(NO)];
				[_game setOwned:@(YES)];
			}
			
			[_game setPreordered:@(NO)];
			[_game setCompleted:@(NO)];
			[_game setLoaned:@(NO)];
			[_game setDigital:@(NO)];
			
			[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				[_wishlistButton setTitle:[_game.wanted isEqualToNumber:@(YES)] ? @"REMOVE FROM WISHLIST" : @"ADD TO WISHLIST" forState:UIControlStateNormal];
				[_wishlistButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
				[_libraryButton setTitle:[_game.owned isEqualToNumber:@(YES)] ? @"REMOVE FROM LIBRARY" : @"ADD TO LIBRARY" forState:UIControlStateNormal];
				[_libraryButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
				
				[_preorderedSwitch setOn:_game.preordered.boolValue animated:YES];
				[_completedSwitch setOn:_game.completed.boolValue animated:YES];
				[_loanedSwitch setOn:_game.loaned.boolValue animated:YES];
				[_digitalSwitch setOn:_game.digital.boolValue animated:YES];
				
				[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionStatus] withRowAnimation:UITableViewRowAnimationAutomatic];
				
				if ([Tools deviceIsiPad]) [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlistCollection" object:nil];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
			}];
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
	
	[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		if (sender != _preorderedSwitch)
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshLibrary" object:nil];
		else if ([Tools deviceIsiPhone])
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlistTable" object:nil];
		else
			[[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshWishlistCollection" object:nil];
	}];
}

- (IBAction)metascoreButtonAction:(UIButton *)sender{
	[self performSegueWithIdentifier:@"MetacriticSegue" sender:nil];
}

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[sender setEnabled:NO];
	[self requestGameWithIdentifier:_game.identifier];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"ViewerSegue"]){
		Image *image = sender;
		
		ImageViewerViewController *destination = segue.destinationViewController;
		[destination setImage:image];
	}
	else{
		MetacriticViewController *destination = segue.destinationViewController;
		[destination setURL:[NSURL URLWithString:_game.metacriticURL]];
	}
}

@end
