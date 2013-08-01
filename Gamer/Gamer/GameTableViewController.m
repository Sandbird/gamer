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
#import "ZoomViewController.h"
#import "PlatformCollectionCell.h"
#import "GameSectionHeaderView.h"

@interface GameTableViewController () <UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet MACircleProgressIndicator *progressIndicator;
@property (nonatomic, strong) IBOutlet UIView *metascoreView;
@property (nonatomic, strong) IBOutlet UILabel *metascoreLabel;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *releaseDateLabel;
@property (nonatomic, strong) IBOutlet UIButton *wishlistButton;
@property (nonatomic, strong) IBOutlet UIButton *libraryButton;
@property (nonatomic, strong) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, strong) IBOutlet UILabel *developerLabel;
@property (nonatomic, strong) IBOutlet UILabel *publisherLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreSecondLabel;
@property (nonatomic, strong) IBOutlet UICollectionView *platformsCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *imagesCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *videosCollectionView;

@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

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
	
	[self.tableView setBackgroundColor:[UIColor colorWithRed:.125490196 green:.125490196 blue:.125490196 alpha:1]];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	_operationQueue = [[NSOperationQueue alloc] init];
	[_operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
	
	if (!_game)
		_game = [Game findFirstByAttribute:@"identifier" withValue:_searchResult.identifier];
	if (_game){
		[self setCoverImageAnimated:NO];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[_metascoreLabel setText:_game.metascore];
			[_titleLabel setText:_game.title];
			
			[_releaseDateLabel setText:_game.releaseDateText];
			[_wishlistButton setEnabled:([_game.wanted isEqualToNumber:@(NO)]) ? YES : NO];
			[_libraryButton setEnabled:([_game.owned isEqualToNumber:@(NO)] && [_game.released isEqualToNumber:@(YES)]) ? YES : NO];
			
			// This mess is just for demo purposes
			[_descriptionTextView setText:_game.overview];
			if (_game.genres.count > 0) [_genreFirstLabel setText:[_game.genres.allObjects[0] name]];
			if (_game.genres.count > 1) [_genreSecondLabel setText:[_game.genres.allObjects[1] name]];
			if (_game.developers.count > 0) [_developerLabel setText:[_game.developers.allObjects[0] name]];
			if (_game.publishers.count > 0) [_publisherLabel setText:[_game.publishers.allObjects[0] name]];
		});
		
		_platforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self IN %@", _game.platforms]];
		
		_images = [Image findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game.identifier = %@", _game.identifier]];
		_videos = [Video findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game.identifier = %@ AND type = %@", _game.identifier, @"Trailers"]];
	}
	else
		[self requestGameWithIdentifier:_searchResult.identifier];
	
	[_progressIndicator setColor:[UIColor whiteColor]];
//	[_metascoreView setHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] sendView:@"Game"];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//	if (section == 2)
//		return [NSString stringWithFormat:@"Images - %d          ", _images.count];
//	else if (section == 3)
//		return [NSString stringWithFormat:@"Videos - %d          ", _videos.count];
//	
//	return [super tableView:tableView titleForHeaderInSection:section];
//}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
	if (section != 0){
		GameSectionHeaderView *headerView = [[GameSectionHeaderView alloc] init];
		switch (section) {
			case 1: [headerView.titleLabel setText:@"Details"]; break;
			case 2: [headerView.titleLabel setText:[NSString stringWithFormat:@"Images - %d", _images.count]]; break;
			case 3: [headerView.titleLabel setText:[NSString stringWithFormat:@"Videos - %d", _videos.count]]; break;
			default: break;
		}
		return headerView;
	}
	else
		return nil;
}

// REFACTOR THIS
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	if (indexPath.section == 1 && indexPath.row == 0){
		CGRect textRect = [_game.overview boundingRectWithSize:CGSizeMake(270, 50000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil];
		return textRect.size.height + 40;
	}
	else if (indexPath.section == 1 && indexPath.row == 2)
		return (_platforms.count > 4) ? 120 : 100;
	else
		return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	if (collectionView == _platformsCollectionView)
		return _platforms.count;
	else if (collectionView == _imagesCollectionView)
		return (_images.count > 0) ? _images.count : 1;
	else
		return (_videos.count > 0) ? _videos.count : 1;
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
		// If array empty, show loading cell
		if (_images.count == 0){
			ImageCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
			[cell.activityIndicator startAnimating];
			return cell;
		}
		
		// If before last cell, download image for next cell
		dispatch_async(dispatch_get_main_queue(), ^{
			if ((_images.count - 1) > indexPath.item){
				Image *nextImage = _images[indexPath.item + 1];
				if (!nextImage.thumbnail && [nextImage.isDownloading isEqualToNumber:@(NO)])
					[self downloadImageWithImageObject:nextImage];
			}
		});
		
		ImageCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		Image *image = _images[indexPath.item];
		[cell.imageView setImage:[UIImage imageWithData:image.thumbnail]];
		if ([image.isDownloading isEqualToNumber:@(YES)] || !image.thumbnail)
			[cell.activityIndicator startAnimating];
		else
			[cell.activityIndicator stopAnimating];
		return cell;
	}
	else{
		if (_videos.count == 0){
			VideoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
			[cell.activityIndicator startAnimating];
			return cell;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if ((_videos.count - 1) > indexPath.item){
				Video *nextVideo = _videos[indexPath.item + 1];
				if (!nextVideo.thumbnail && [nextVideo.isDownloading isEqualToNumber:@(NO)])
					[self downloadThumbnailForVideo:nextVideo];
			}
		});
		
		VideoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
		Video *video = _videos[indexPath.item];
		[cell.imageView setImage:[UIImage imageWithData:video.thumbnail]];
		if ([video.isDownloading isEqualToNumber:@(YES)] || !video.thumbnail)
			[cell.activityIndicator startAnimating];
		else
			[cell.activityIndicator stopAnimating];
		return cell;
	}
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	if (collectionView == _imagesCollectionView){
		Image *image = _images[indexPath.item];
		if (image.data)
			[self performSegueWithIdentifier:@"ZoomSegue" sender:image];
	}
	else if (collectionView == _videosCollectionView){
		Video *video = _videos[indexPath.item];
		if (video.highQualityURL){
			MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:video.highQualityURL]];
			[self presentMoviePlayerViewControllerAnimated:player];
		}
	}
}

#pragma mark - Networking

- (void)requestGameWithIdentifier:(NSNumber *)identifier{
	NSURLRequest *request = [SessionManager URLRequestForGameWithFields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers" identifier:identifier];
	
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
			if (stringURL) stringURL = [stringURL stringByReplacingOccurrencesOfString:@"scale_large" withString:@"original"];
			
			CoverImage *coverImage = [CoverImage findFirstByAttribute:@"url" withValue:stringURL];
			if (!coverImage){
				coverImage = [CoverImage createInContext:_context];
				[coverImage setUrl:stringURL];
			}
			[_game setCoverImage:coverImage];
			
			if (!coverImage.data || ![coverImage.url isEqualToString:stringURL])
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
			[_game setReleasePeriod:[self releasePeriodForReleaseDate:releaseDate]];
		}
		else{
			NSDateComponents *expectedReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
			[expectedReleaseDateComponents setHour:10];
			
			if (expectedReleaseDay){
				[expectedReleaseDateComponents setDay:expectedReleaseDay];
				[expectedReleaseDateComponents setMonth:expectedReleaseMonth];
				[expectedReleaseDateComponents setQuarter:[self quarterForMonth:expectedReleaseMonth]];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Tools dateFormatter] setDateFormat:@"d MMMM yyyy"];
			}
			else if (expectedReleaseMonth){
				[expectedReleaseDateComponents setMonth:expectedReleaseMonth + 1];
				[expectedReleaseDateComponents setDay:0];
				[expectedReleaseDateComponents setQuarter:[self quarterForMonth:expectedReleaseMonth]];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Tools dateFormatter] setDateFormat:@"MMMM yyyy"];
			}
			else if (expectedReleaseQuarter){
				[expectedReleaseDateComponents setQuarter:expectedReleaseQuarter];
				[expectedReleaseDateComponents setMonth:((expectedReleaseQuarter * 3) + 1)];
				[expectedReleaseDateComponents setDay:0];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Tools dateFormatter] setDateFormat:@"QQQ yyyy"];
			}
			else if (expectedReleaseYear){
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[expectedReleaseDateComponents setQuarter:4];
				[expectedReleaseDateComponents setMonth:13];
				[expectedReleaseDateComponents setDay:0];
				[[Tools dateFormatter] setDateFormat:@"yyyy"];
			}
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
			
			[_game setReleaseDateText:(expectedReleaseYear) ? [[Tools dateFormatter] stringFromDate:expectedReleaseDateFromComponents] : @"TBA"];
			[_game setReleased:@(NO)];
			
			[_game setReleaseDate:releaseDate];
			[_game setReleasePeriod:[self releasePeriodForReleaseDate:releaseDate]];
		}
		
        // Platforms
		if (results[@"platforms"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"platforms"]){
				Platform *platform = [Platform findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:_context];
				if (platform){
//					[platform setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
//					[platform setAbbreviation:[Tools stringFromSourceIfNotNull:dictionary[@"abbreviation"]]];
					[_game addPlatformsObject:platform];
				}
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
			dispatch_async(dispatch_get_main_queue(), ^{
				[self setCoverImageAnimated:NO];
				
				[_metascoreLabel setText:_game.metascore];
				[_titleLabel setText:_game.title];
				
				[_releaseDateLabel setText:_game.releaseDateText];
				[_wishlistButton setEnabled:([_game.wanted isEqualToNumber:@(NO)]) ? YES : NO];
				[_libraryButton setEnabled:([_game.owned isEqualToNumber:@(NO)] && [_game.released isEqualToNumber:@(YES)]) ? YES : NO];
				
				// This mess is just for demo purposes
				[_descriptionTextView setText:_game.overview];
				if (_game.genres.count > 0) [_genreFirstLabel setText:[_game.genres.allObjects[0] name]];
				if (_game.genres.count > 1) [_genreSecondLabel setText:[_game.genres.allObjects[1] name]];
				if (_game.developers.count > 0) [_developerLabel setText:[_game.developers.allObjects[0] name]];
				if (_game.publishers.count > 0) [_publisherLabel setText:[_game.publishers.allObjects[0] name]];
			});
			
			_platforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self IN %@", _game.platforms]];
			[_platformsCollectionView reloadData];
			
			[self.tableView reloadData];
			
			// If game is released and has at least one platform, request metascore
			if ([_game.releasePeriod.identifier isEqualToNumber:@(1)] && _platforms.count > 0)
				[self requestMetascoreForGameWithTitle:_game.title platform:_platforms[0]];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Game", self, response.statusCode);
	}];
	[operation start];
}

- (void)downloadImageForCoverImage:(CoverImage *)coverImage{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:coverImage.url]];
	[request setHTTPMethod:@"GET"];
	
	[_progressIndicator setValue:0];
	[_progressIndicator setHidden:NO];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:^UIImage *(UIImage *image) {
		if (image.size.width > image.size.height){
			[coverImage setData:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:280])];
			[_game setWishlistThumbnail:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:56])];
			[_game setLibraryThumbnail:UIImagePNGRepresentation([Tools imageWithImage:image scaledToWidth:92])];
		}
		else{
			[coverImage setData:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:200])];
			[_game setWishlistThumbnail:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:70])];
			[_game setLibraryThumbnail:UIImagePNGRepresentation([Tools imageWithImage:image scaledToHeight:116])];
		}
		return nil;
	} success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[_progressIndicator setHidden:YES];
				[self setCoverImageAnimated:YES];
			});
			[self requestMediaForGame:_game];
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
	formattedTitle = [formattedTitle stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	
	NSString *formattedPlatform = platform.name.lowercaseString;
	formattedPlatform = [formattedPlatform stringByReplacingOccurrencesOfString:@"'" withString:@""];
	formattedPlatform = [formattedPlatform stringByReplacingOccurrencesOfString:@":" withString:@""];
	formattedPlatform = [formattedPlatform stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	
	NSString *url = [NSString stringWithFormat:@"http://www.metacritic.com/game/%@/%@", formattedPlatform, formattedTitle];
	
//	NSLog(@"%@", url);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//		NSLog(@"Success in %@ - Metascore", self);
		
		NSString *html = [NSString stringWithUTF8String:[responseObject bytes]];
		
//		NSLog(@"%@", html);
		
		if (html){
			NSRegularExpression *firstExpression = [NSRegularExpression regularExpressionWithPattern:@"v:average\">" options:NSRegularExpressionCaseInsensitive error:nil];
			NSTextCheckingResult *firstResult = [firstExpression firstMatchInString:html options:NSMatchingReportProgress range:NSMakeRange(0, html.length)];
			NSUInteger startIndex = firstResult.range.location + firstResult.range.length;
			
			NSRegularExpression *secondExpression = [NSRegularExpression regularExpressionWithPattern:@"<" options:NSRegularExpressionCaseInsensitive error:nil];
			NSTextCheckingResult *secondResult = [secondExpression firstMatchInString:html options:NSMatchingReportProgress range:NSMakeRange(startIndex, html.length - startIndex)];
			NSUInteger endIndex = secondResult.range.location;
			
			NSString *metascore = [html substringWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
			
//			NSLog(@"Metascore: %@", metascore);
			
			[_game setMetascore:metascore];
			[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				if (metascore.length > 0){
					[_metascoreView setHidden:NO];
					[_metascoreLabel setText:metascore];
				}
			}];
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Failure in %@ - Metascore", self);
	}];
	[operation start];
}

- (void)requestMediaForGame:(Game *)game{
	NSURLRequest *request = [SessionManager URLRequestForGameWithFields:@"images,videos" identifier:game.identifier];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Media - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
//		NSLog(@"%@", JSON);
		
		NSDictionary *results = JSON[@"results"];
		
		// Images
		if (results[@"images"] != [NSNull null]){
			NSInteger index = 0;
			for (NSDictionary *dictionary in results[@"images"]){
				NSString *stringURL = [Tools stringFromSourceIfNotNull:dictionary[@"super_url"]];
				if (stringURL) stringURL = [stringURL stringByReplacingOccurrencesOfString:@"scale_large" withString:@"original"];
				Image *image = [Image findFirstByAttribute:@"url" withValue:stringURL inContext:_context];
				if (!image){
					image = [Image createInContext:_context];
					[image setUrl:stringURL];
				}
				[image setIndex:@(index)];
				[game addImagesObject:image];
				
				if (index <= 1) [self downloadImageWithImageObject:image];
				
				index++;
			}
		}
		
		// Videos
		if (results[@"videos"] != [NSNull null]){
//			NSLog(@"%@", results[@"videos"]);
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
		}
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			_images = [Image findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game.identifier = %@", game.identifier]];
			[[self.tableView headerViewForSection:2].textLabel setText:[NSString stringWithFormat:@"Images - %d", _images.count]];
			_videos = [Video findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game.identifier = %@ AND type = %@", game.identifier, @"Trailers"]];
			[[self.tableView headerViewForSection:3].textLabel setText:[NSString stringWithFormat:@"Videos - %d", _videos.count]];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d", self, response.statusCode);
	}];
	[operation start];
}

- (void)downloadImageWithImageObject:(Image *)imageObject{
	[imageObject setIsDownloading:@(YES)];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imageObject.url]];
	[request setHTTPMethod:@"GET"];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:^UIImage *(UIImage *image) {
//		NSLog(@"image downloaded: %.fx%.f", image.size.width, image.size.height);
//		NSLog(@"image downloaded index: %@", imageObject.index);
		[imageObject setData:UIImagePNGRepresentation(image)];
		[imageObject setThumbnail:UIImagePNGRepresentation((image.size.width > image.size.height) ? [Tools imageWithImage:image scaledToWidth:320] : [Tools imageWithImage:image scaledToHeight:180])];
		return nil;
	} success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		[imageObject setIsDownloading:@(NO)];
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
//			dispatch_async(dispatch_get_main_queue(), ^{
				[_imagesCollectionView performBatchUpdates:^{
					[_imagesCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
				} completion:nil];
//			});
		}];
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
		[imageObject setIsDownloading:@(NO)];
	}];
	[_operationQueue addOperation:operation];
}

- (void)requestInformationForVideo:(Video *)video{
	NSURLRequest *request = [SessionManager URLRequestForVideoWithFields:@"id,name,deck,video_type,length_seconds,publish_date,high_url,low_url,image" identifier:video.identifier];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Video - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		NSLog(@"%@", JSON);
		
		[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		if ([JSON[@"status_code"] isEqualToNumber:@(101)]){
			[video deleteEntity];
			[_context saveToPersistentStoreAndWait];
			return;
		}
		
		NSDictionary *results = JSON[@"results"];
		
		[video setTitle:[Tools stringFromSourceIfNotNull:results[@"name"]]];
		[video setOverview:[Tools stringFromSourceIfNotNull:results[@"deck"]]];
		[video setType:[Tools stringFromSourceIfNotNull:results[@"video_type"]]];
		[video setLength:[Tools integerNumberFromSourceIfNotNull:results[@"length_seconds"]]];
		[video setPublishDate:[[Tools dateFormatter] dateFromString:results[@"publish_date"]]];
		[video setHighQualityURL:[Tools stringFromSourceIfNotNull:results[@"high_url"]]];
		[video setLowQualityURL:[Tools stringFromSourceIfNotNull:results[@"low_url"]]];
		
		NSString *stringURL = [Tools stringFromSourceIfNotNull:results[@"image"][@"super_url"]];
		if (stringURL) stringURL = [stringURL stringByReplacingOccurrencesOfString:@"scale_large" withString:@"original"];
		
		[video setThumbnailURL:stringURL];
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			if (video.index.integerValue <= 1 && !video.thumbnail)
				[self downloadThumbnailForVideo:video];
			
			_videos = [Video findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game.identifier = %@ AND type = %@", _game.identifier, @"Trailers"]];
			[[self.tableView headerViewForSection:3].textLabel setText:[NSString stringWithFormat:@"Videos - %d", _videos.count]];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		NSLog(@"Failure in %@ - Status code: %d - Video", self, response.statusCode);
	}];
	[_operationQueue addOperation:operation];
}

- (void)downloadThumbnailForVideo:(Video *)video{
	[video setIsDownloading:@(YES)];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:video.thumbnailURL]];
	[request setHTTPMethod:@"GET"];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:^UIImage *(UIImage *image) {
		[video setThumbnail:UIImagePNGRepresentation((image.size.width > image.size.height) ? [Tools imageWithImage:image scaledToWidth:320] : [Tools imageWithImage:image scaledToHeight:180])];
		return nil;
	} success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		[video setIsDownloading:@(NO)];
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
//			dispatch_async(dispatch_get_main_queue(), ^{
				[_videosCollectionView performBatchUpdates:^{
					[_videosCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
				} completion:nil];
//			});
		}];
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
		[video setIsDownloading:@(NO)];
	}];
	[_operationQueue addOperation:operation];
}

#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex){
		if (actionSheet.tag == 1){
			[_game setWishlistPlatform:_selectablePlatforms[buttonIndex]];
			
			// CHANGE THIS (RELEASEPERIOD.HIDDEN?)
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (hidden = %@ AND wanted = %@ AND wishlistPlatform.favorite = %@)", _game.releasePeriod.identifier, @(NO), @(YES), @(YES)];
			NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
			[_game setHidden:(gamesCount == 0) ? @(YES) : @(NO)];
			
			[_game setWanted:@(YES)];
			[_game setOwned:@(NO)];
		}
		else{
			[_game setLibraryPlatform:_selectablePlatforms[buttonIndex]];
			[_game setWanted:@(NO)];
			[_game setOwned:@(YES)];
		}
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self.navigationController popToRootViewControllerAnimated:YES];
//			[self.tabBarController setSelectedIndex:(actionSheet.tag == 1) ? 0 : 1];
		}];
	}
}

#pragma mark - Custom

- (void)setCoverImageAnimated:(BOOL)animated{
	if (animated){
		CATransition *transition = [CATransition animation];
		transition.type = kCATransitionFade;
		transition.duration = 0.2;
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		[_coverImageView setImage:[UIImage imageWithData:_game.coverImage.data]];
		[_coverImageView.layer addAnimation:transition forKey:nil];
	}
	else
		[_coverImageView setImage:[UIImage imageWithData:_game.coverImage.data]];
	
	[Tools addDropShadowToView:_coverImageView color:[UIColor blackColor] opacity:1 radius:10 offset:CGSizeMake(0, 5) bounds:[Tools frameForImageInImageView:_coverImageView]];
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

- (IBAction)addButtonPressAction:(UIButton *)sender{
	NSInteger buttonPressed = (sender == _wishlistButton) ? 1 : 2;
	
	_selectablePlatforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"favorite = %@ AND self IN %@", @(YES), _game.platforms]];
	
	if (_selectablePlatforms.count > 1){
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		[actionSheet setTag:buttonPressed];
		
		for (Platform *platform in _selectablePlatforms)
			[actionSheet addButtonWithTitle:platform.name];
		[actionSheet addButtonWithTitle:@"Cancel"];
		[actionSheet setCancelButtonIndex:_selectablePlatforms.count];
		
		[actionSheet showInView:self.tabBarController.view];
	}
	else{
		if (buttonPressed == 1){
			if (_selectablePlatforms.count > 0){
				[_game setWishlistPlatform:_selectablePlatforms[0]];
				[_game setLibraryPlatform:nil];
			}
			
			// CHANGE THIS (RELEASEPERIOD.HIDDEN?)
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND (hidden = %@ AND wanted = %@ AND wishlistPlatform.favorite = %@)", _game.releasePeriod.identifier, @(NO), @(YES), @(YES)];
			NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
			[_game setHidden:(gamesCount == 0) ? @(YES) : @(NO)];
			
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
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self.navigationController popToRootViewControllerAnimated:YES];
//			[self.tabBarController setSelectedIndex:(sender == _wantButton) ? 0 : 1];
		}];
	}
}

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[self requestGameWithIdentifier:_game.identifier];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	Image *image = sender;
	
	ZoomViewController *destination = segue.destinationViewController;
	[destination setImage:[UIImage imageWithData:image.data]];
}

@end
