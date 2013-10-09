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
@property (nonatomic, strong) IBOutlet UILabel *developerLabel;
@property (nonatomic, strong) IBOutlet UILabel *publisherLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreSecondLabel;
@property (nonatomic, strong) IBOutlet UICollectionView *platformsCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *imagesCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *videosCollectionView;

@property (nonatomic, strong) ContentStatusView *imagesStatusView;
@property (nonatomic, strong) ContentStatusView *videosStatusView;

@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSOperationQueue *videosOperationQueue;

@property (nonatomic, strong) NSArray *platforms;
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
		
		_platforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self IN %@", _game.platforms]];
		
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
	else if (indexPath.section == SectionDetails && indexPath.row == 2)
		return (_platforms.count > 4) ? 120 : 100;
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
		PlatformCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		Platform *platform = _platforms[indexPath.item];
		[cell.platformLabel setText:platform.abbreviation];
		[cell.platformLabel setBackgroundColor:platform.color];
		return cell;
	}
	else if (collectionView == _imagesCollectionView){
		// If before last cell, download image for next cell
		if (_images.count > (indexPath.item + 1)){
			Image *nextImage = _images[indexPath.item + 1];
			ImageCollectionCell *nextCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:[NSIndexPath indexPathForItem:indexPath.item + 1 inSection:0]];
			
			// Download image
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
		
		// Download image
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
			
			// Download image
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
		
		// Download image
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
	NSURLRequest *request = [SessionManager requestForGameWithIdentifier:identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Game - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		//		NSLog(@"%@", JSON);
		
		[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		NSDictionary *results = JSON[@"results"];
		
		// Set game
		_game = [Game findFirstByAttribute:@"identifier" withValue:identifier];
		if (!_game) _game = [Game createInContext:_context];
		
		// Main info
		[_game setIdentifier:identifier];
		[_game setTitle:[Tools stringFromSourceIfNotNull:results[@"name"]]];
		[_game setOverview:[Tools stringFromSourceIfNotNull:results[@"deck"]]];
		
		// Cover image
		if (results[@"image"] != [NSNull null]){
			NSString *stringURL = [Tools stringFromSourceIfNotNull:results[@"image"][@"super_url"]];
			
			CoverImage *coverImage = [CoverImage findFirstByAttribute:@"url" withValue:stringURL];
			if (!coverImage){
				coverImage = [CoverImage createInContext:_context];
				[coverImage setUrl:stringURL];
			}
			[_game setCoverImage:coverImage];
			
			if (!_game.thumbnail || !coverImage.data || ![coverImage.url isEqualToString:stringURL])
				[self downloadImageForCoverImage:coverImage];
			else
				[self requestMediaForGame:_game];
		}
		
		// Release date
		NSString *originalReleaseDate = [Tools stringFromSourceIfNotNull:results[@"original_release_date"]];
		NSInteger expectedReleaseDay = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_day"]].integerValue;
		NSInteger expectedReleaseMonth = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_month"]].integerValue;
		NSInteger expectedReleaseQuarter = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_quarter"]].integerValue;
		NSInteger expectedReleaseYear = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_year"]].integerValue;
		
		NSCalendar *calendar = [NSCalendar currentCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		
		// Game is released
		if (originalReleaseDate){
			NSDateComponents *originalReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[[Tools dateFormatter] dateFromString:originalReleaseDate]];
			[originalReleaseDateComponents setHour:10];
			[originalReleaseDateComponents setQuarter:[self quarterForMonth:originalReleaseDateComponents.month]];
			
			NSDate *releaseDateFromComponents = [calendar dateFromComponents:originalReleaseDateComponents];
			
			ReleaseDate *releaseDate = [ReleaseDate findFirstByAttribute:@"date" withValue:releaseDateFromComponents];
			if (!releaseDate) releaseDate = [ReleaseDate createInContext:_context];
			[releaseDate setDate:releaseDateFromComponents];
			[releaseDate setDay:@(originalReleaseDateComponents.day)];
			[releaseDate setMonth:@(originalReleaseDateComponents.month)];
			[releaseDate setQuarter:@(originalReleaseDateComponents.quarter)];
			[releaseDate setYear:@(originalReleaseDateComponents.year)];
			
			[[Tools dateFormatter] setDateFormat:@"d MMMM yyyy"];
			[_game setReleaseDateText:[[Tools dateFormatter] stringFromDate:releaseDateFromComponents]];
			[_game setReleased:@(YES)];
			
			[_game setReleaseDate:releaseDate];
			[_game.releaseDate setDefined:@(YES)];
			[_game setReleasePeriod:[self releasePeriodForReleaseDate:releaseDate]];
		}
		// Game is not yet released
		else{
			NSDateComponents *expectedReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
			[expectedReleaseDateComponents setHour:10];
			
			BOOL defined = NO;
			
			// Exact release date is known
			if (expectedReleaseDay){
				[expectedReleaseDateComponents setDay:expectedReleaseDay];
				[expectedReleaseDateComponents setMonth:expectedReleaseMonth];
				[expectedReleaseDateComponents setQuarter:[self quarterForMonth:expectedReleaseMonth]];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Tools dateFormatter] setDateFormat:@"d MMMM yyyy"];
				defined = YES;
			}
			// Release month is known
			else if (expectedReleaseMonth){
				[expectedReleaseDateComponents setMonth:expectedReleaseMonth + 1];
				[expectedReleaseDateComponents setDay:0];
				[expectedReleaseDateComponents setQuarter:[self quarterForMonth:expectedReleaseMonth]];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Tools dateFormatter] setDateFormat:@"MMMM yyyy"];
			}
			// Release quarter is known
			else if (expectedReleaseQuarter){
				[expectedReleaseDateComponents setQuarter:expectedReleaseQuarter];
				[expectedReleaseDateComponents setMonth:((expectedReleaseQuarter * 3) + 1)];
				[expectedReleaseDateComponents setDay:0];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Tools dateFormatter] setDateFormat:@"QQQ yyyy"];
			}
			// Release year is known
			else if (expectedReleaseYear){
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[expectedReleaseDateComponents setQuarter:4];
				[expectedReleaseDateComponents setMonth:13];
				[expectedReleaseDateComponents setDay:0];
				[[Tools dateFormatter] setDateFormat:@"yyyy"];
			}
			// Release date is unknown
			else{
				[expectedReleaseDateComponents setYear:2050];
				[expectedReleaseDateComponents setQuarter:4];
				[expectedReleaseDateComponents setMonth:13];
				[expectedReleaseDateComponents setDay:0];
			}
			
			NSDate *expectedReleaseDateFromComponents = [calendar dateFromComponents:expectedReleaseDateComponents];
			
			ReleaseDate *releaseDate = [ReleaseDate findFirstByAttribute:@"date" withValue:expectedReleaseDateFromComponents];
			if (!releaseDate) releaseDate = [ReleaseDate createInContext:_context];
			[releaseDate setDate:expectedReleaseDateFromComponents];
			[releaseDate setDay:@(expectedReleaseDateComponents.day)];
			[releaseDate setMonth:@(expectedReleaseDateComponents.month)];
			[releaseDate setQuarter:@(expectedReleaseDateComponents.quarter)];
			[releaseDate setYear:@(expectedReleaseDateComponents.year)];
			
			[releaseDate setDefined:@(defined)];
			
			[_game setReleaseDateText:(expectedReleaseYear) ? [[Tools dateFormatter] stringFromDate:expectedReleaseDateFromComponents] : @"TBA"];
			[_game setReleased:@(NO)];
			
			[_game setReleaseDate:releaseDate];
			[_game setReleasePeriod:[self releasePeriodForReleaseDate:releaseDate]];
		}
		
        // Platforms
		if (results[@"platforms"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"platforms"]){
				NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
				switch (identifier.integerValue) {
					case 88: identifier = @(35); break;
					case 143: identifier = @(129); break;
					case 86: identifier = @(20); break;
					default: break;
				}
				Platform *platform = [Platform findFirstByAttribute:@"identifier" withValue:identifier inContext:_context];
				if (platform) [_game addPlatformsObject:platform];
			}
		}
        
		// Genres
		if (results[@"genres"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"genres"]){
				Genre *genre = [Genre findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:_context];
				if (genre)
					[genre setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					genre = [Genre createInContext:_context];
					[genre setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[genre setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addGenresObject:genre];
			}
		}
		
		// Developers
		if (results[@"developers"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"developers"]){
				Developer *developer = [Developer findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:_context];
				if (developer)
					[developer setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					developer = [Developer createInContext:_context];
					[developer setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[developer setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addDevelopersObject:developer];
			}
		}
		
		// Publishers
		if (results[@"publishers"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"publishers"]){
				Publisher *publisher = [Publisher findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:_context];
				if (publisher)
					[publisher setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					publisher = [Publisher createInContext:_context];
					[publisher setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[publisher setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addPublishersObject:publisher];
			}
		}
		
		// Franchises
		if (results[@"franchises"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"franchises"]){
				Franchise *franchise = [Franchise findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:_context];
				if (franchise)
					[franchise setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					franchise = [Franchise createInContext:_context];
					[franchise setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[franchise setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addFranchisesObject:franchise];
			}
		}
		
		// Themes
		if (results[@"themes"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"themes"]){
				Theme *theme = [Theme findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:_context];
				if (theme)
					[theme setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					theme = [Theme createInContext:_context];
					[theme setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[theme setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addThemesObject:theme];
			}
		}
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self refreshAnimated:NO];
			
			_platforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self IN %@", _game.platforms]];
			[_platformsCollectionView reloadData];
			
			[self.tableView reloadData];
			
			// If game is released and has at least one platform, request metascore
			if ([_game.releasePeriod.identifier isEqualToNumber:@(1)] && _platforms.count > 0)
				[self requestMetascoreForGameWithTitle:_game.title platform:_platforms[0]];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Game", self, response.statusCode);
		
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}];
	[operation start];
}

- (void)downloadImageForCoverImage:(CoverImage *)coverImage{
	[_progressIndicator setValue:0];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:coverImage.url]];
	[request setHTTPMethod:@"GET"];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:^UIImage *(UIImage *image) {
		[self requestMediaForGame:_game];
		
		if (image.size.width > image.size.height){
			[coverImage setData:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:_coverImageView.frame.size.width])];
			[_game setThumbnail:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:[Tools deviceIsiPad] ? 160 : 50])];
			[_game setThumbnailLarge:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:[Tools deviceIsiPad] ? 140 : 92])];
		}
		else{
			[coverImage setData:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:_coverImageView.frame.size.height])];
			[_game setThumbnail:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:[Tools deviceIsiPad] ? 85 : 50])];
			[_game setThumbnailLarge:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:[Tools deviceIsiPad] ? 176 : 116])];
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
	[operation start];
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
			
			//			NSLog(@"Metascore: %@", metascore);
			
			[_game setMetascore:metascore];
			[_game setMetacriticURL:url];
			
			[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				if (metascore.length > 0){
					[_metascoreButton setBackgroundColor:[self colorForMetascore:metascore]];
					[_metascoreButton setHidden:NO];
					[_metascoreButton setTitle:metascore forState:UIControlStateNormal];
				}
				else{
					if (_platforms.count > ([_platforms indexOfObject:platform] + 1))
						[self requestMetascoreForGameWithTitle:title platform:_platforms[[_platforms indexOfObject:platform] + 1]];
					else
						[_metascoreButton setHidden:YES];
				}
				[_metascoreButton.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
			}];
		}
		else{
			if (_platforms.count > ([_platforms indexOfObject:platform] + 1))
				[self requestMetascoreForGameWithTitle:title platform:_platforms[[_platforms indexOfObject:platform] + 1]];
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Failure in %@ - Metascore", self);
	}];
	[operation start];
}

- (void)requestMediaForGame:(Game *)game{
	[_imagesStatusView setStatus:ContentStatusLoading];
	[_videosStatusView setStatus:ContentStatusLoading];
	
	NSURLRequest *request = [SessionManager requestForGameWithIdentifier:game.identifier fields:@"images,videos"];
	
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
	NSURLRequest *request = [SessionManager requestForVideoWithIdentifier:video.identifier fields:@"id,name,deck,video_type,length_seconds,publish_date,high_url,low_url,image"];
	
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

- (NSInteger)quarterForMonth:(NSInteger)month{
	switch (month) {
		case 1: case 2: case 3: return 1;
		case 4: case 5: case 6: return 2;
		case 7: case 8: case 9: return 3;
		case 10: case 11: case 12: return 4;
		default: return 0;
	}
}

- (ReleasePeriod *)releasePeriodForReleaseDate:(ReleaseDate *)releaseDate{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	// Components for today, this month, this quarter, this year
	NSDateComponents *current = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	[current setQuarter:[self quarterForMonth:current.month]];
	
	// Components for next month, next quarter, next year
	NSDateComponents *next = [calendar components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	next.month++;
	[next setQuarter:current.quarter + 1];
	next.year++;
	
	NSInteger period = 0;
	if ([releaseDate.date compare:[calendar dateFromComponents:current]] <= NSOrderedSame) period = 1; // Released
	else{
		if (releaseDate.year.integerValue == 2050)
			period = 9; // TBA
		else if (releaseDate.year.integerValue > next.year)
			period = 8; // Later
		else if (releaseDate.year.integerValue == next.year){
			if (current.month == 12 && releaseDate.month.integerValue == 1)
				period = 3; // Next month
			else if (current.quarter == 4 && releaseDate.quarter.integerValue == 1)
				period = 5; // Next quarter
			else
				period = 7; // Next year
		}
		else if (releaseDate.year.integerValue == current.year){
			if (releaseDate.month.integerValue == current.month)
				period = 2; // This month
			else if (releaseDate.month.integerValue == next.month)
				period = 3; // Next month
			else if (releaseDate.quarter.integerValue == current.quarter)
				period = 4; // This quarter
			else if (releaseDate.quarter.integerValue == next.quarter)
				period = 5; // Next quarter
			else
				period = 6; // This year
		}
	}
	
	return [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(period)];
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
		_selectablePlatforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self in %@ AND self in %@", [SessionManager gamer].platforms, _game.platforms]];
		
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
