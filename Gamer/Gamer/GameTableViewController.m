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
#import "SessionManager.h"
#import <MediaPlayer/MediaPlayer.h>

#define kWantButtonTag 1
#define kOwnButtonTag 2

@interface GameTableViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet MACircleProgressIndicator *progressIndicator;
@property (nonatomic, strong) IBOutlet UIView *metascoreView;
@property (nonatomic, strong) IBOutlet UILabel *metascoreLabel;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *releaseDateLabel;
@property (nonatomic, strong) IBOutlet UIButton *wantButton;
@property (nonatomic, strong) IBOutlet UIButton *ownButton;
@property (nonatomic, strong) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, strong) IBOutlet UILabel *platformLabel;
@property (nonatomic, strong) IBOutlet UILabel *developerLabel;
@property (nonatomic, strong) IBOutlet UILabel *publisherLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreFirstLabel;
@property (nonatomic, strong) IBOutlet UILabel *genreSecondLabel;
@property (nonatomic, strong) IBOutlet UIScrollView *imagesScrollView;
@property (nonatomic, strong) IBOutlet UIScrollView *videosScrollView;

@property (nonatomic, assign) NSInteger pressedButtonTag;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation GameTableViewController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIExtendedEdgeAll];
	
	[self.tableView setBackgroundColor:[UIColor colorWithRed:.098039216 green:.098039216 blue:.098039216 alpha:1]];
	[self.tableView setSeparatorColor:[UIColor darkGrayColor]];
	
	[_titleLabel setTextColor:[UIColor lightGrayColor]];
	[_releaseDateLabel setTextColor:[UIColor lightGrayColor]];
	[_descriptionTextView setTextColor:[UIColor lightGrayColor]];
	[_platformLabel setTextColor:[UIColor lightGrayColor]];
	[_developerLabel setTextColor:[UIColor lightGrayColor]];
	[_publisherLabel setTextColor:[UIColor lightGrayColor]];
	[_genreFirstLabel setTextColor:[UIColor lightGrayColor]];
	[_genreSecondLabel setTextColor:[UIColor lightGrayColor]];
	
	if (!_game){
		Game *game = [Game findFirstByAttribute:@"identifier" withValue:_searchResult.identifier];
		if (game) _game = game;
		else [self requestGameWithIdentifier:_searchResult.identifier];
	}
	
	[_metascoreView setHidden:YES];
}

- (void)viewDidLayoutSubviews{
//	[Tools addDropShadowToView:_coverImageView color:[UIColor blackColor] opacity:0.6 radius:5 offset:CGSizeZero];
	[_progressIndicator setColor:[UIColor whiteColor]];
}

- (void)viewWillAppear:(BOOL)animated{
	[self refresh];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//	switch (indexPath.section) {
//		case 0: return 328;
//		case 1: return 200;
//		case 2: case 3: return 160;
//		default: return 0;
//	}
//}

#pragma mark - Networking

- (void)requestGameWithIdentifier:(NSNumber *)identifier{
	NSURLRequest *request = [SessionManager URLRequestForGameWithFields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers" identifier:identifier];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Game - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
//		NSLog(@"%@", JSON);
		
		[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		NSDictionary *results = JSON[@"results"];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		// Set game
		_game = [Game findFirstByAttribute:@"identifier" withValue:identifier];
		if (!_game) _game = [Game createInContext:context];
		
		// Main info
		[_game setIdentifier:identifier];
		[_game setTitle:[Tools stringFromSourceIfNotNull:results[@"name"]]];
		[_game setOverview:[Tools stringFromSourceIfNotNull:results[@"deck"]]];
		
		// Cover image
		if (results[@"image"] != [NSNull null]){
			NSString *stringURL = [Tools stringFromSourceIfNotNull:results[@"image"][@"super_url"]];
			if (stringURL) stringURL = [stringURL stringByReplacingOccurrencesOfString:@"scale_large" withString:@"original"];
			if (!_game.coverImage || ![_game.coverImage.url isEqualToString:stringURL]){
				[self downloadCoverImageWithURL:[NSURL URLWithString:stringURL]];
			}
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
			if (!releaseDate) releaseDate = [ReleaseDate createInContext:context];
			[releaseDate setDate:releaseDateFromComponents];
			[releaseDate setDay:@(originalReleaseDateComponents.day)];
			[releaseDate setMonth:@(originalReleaseDateComponents.month)];
			[releaseDate setQuarter:@(originalReleaseDateComponents.quarter)];
			[releaseDate setYear:@(originalReleaseDateComponents.year)];
			
			[[Tools dateFormatter] setDateFormat:@"d MMM yyyy"];
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
			if (!releaseDate) releaseDate = [ReleaseDate createInContext:context];
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
				Platform *platform = [Platform findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (platform){
					[platform setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
					[platform setAbbreviation:[Tools stringFromSourceIfNotNull:dictionary[@"abbreviation"]]];
					[_game addPlatformsObject:platform];
				}
			}
		}
        
		// Genres
		if (results[@"genres"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"genres"]){
				Genre *genre = [Genre findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (genre)
					[genre setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					genre = [Genre createInContext:context];
					[genre setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[genre setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addGenresObject:genre];
			}
		}
		
		// Developers
		if (results[@"developers"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"developers"]){
				Developer *developer = [Developer findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (developer)
					[developer setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					developer = [Developer createInContext:context];
					[developer setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[developer setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addDevelopersObject:developer];
			}
		}
		
		// Publishers
		if (results[@"publishers"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"publishers"]){
				Publisher *publisher = [Publisher findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (publisher)
					[publisher setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					publisher = [Publisher createInContext:context];
					[publisher setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[publisher setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addPublishersObject:publisher];
			}
		}
		
		// Franchises
		if (results[@"franchises"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"franchises"]){
				Franchise *franchise = [Franchise findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (franchise)
					[franchise setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					franchise = [Franchise createInContext:context];
					[franchise setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[franchise setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addFranchisesObject:franchise];
			}
		}
		
		// Themes
		if (results[@"themes"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"themes"]){
				Theme *theme = [Theme findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (theme)
					[theme setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					theme = [Theme createInContext:context];
					[theme setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[theme setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addThemesObject:theme];
			}
		}
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self refresh];
			
			// If game is released and has at least one platform, request metascore
			if ([_game.releasePeriod.identifier isEqualToNumber:@(1)] && _game.platforms.count > 0)
				[self requestMetascoreForGameWithTitle:_game.title platform:_game.platforms.allObjects[0]];
			
			[self requestMediaForGame:_game];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Error: %@", self, response.statusCode, error.description);
	}];
	[operation start];
}

- (void)downloadCoverImageWithURL:(NSURL *)URL{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setHTTPMethod:@"GET"];
	
	[_progressIndicator setValue:0];
	[_progressIndicator setHidden:NO];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
		NSLog(@"Success in %@ - Cover image", self);
		
		UIImage *fullImage = [Tools imageWithImage:image scaledToHeight:200];
		UIImage *thumbnail = [Tools imageWithImage:image scaledToHeight:70];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		CoverImage *coverImage = [CoverImage findFirstByAttribute:@"url" withValue:URL.absoluteString];
		if (!coverImage) coverImage = [CoverImage createInContext:context];
		[coverImage setData:UIImagePNGRepresentation(fullImage)];
		[coverImage setUrl:URL.absoluteString];
		
		[_game setCoverImage:coverImage];
		[_game setThumbnail:UIImagePNGRepresentation(thumbnail)];
		
		[_coverImageView setFrame:CGRectMake(_coverImageView.frame.origin.x, _coverImageView.frame.origin.y, fullImage.size.width * 0.5, _coverImageView.frame.size.height)];
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				CATransition *transition = [CATransition animation];
				transition.type = kCATransitionFade;
				transition.duration = 0.2;
				transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
				[_coverImageView setImage:fullImage];
				[_progressIndicator setHidden:YES];
				[_coverImageView.layer addAnimation:transition forKey:nil];
			});
		}];
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
		NSLog(@"Success in %@ - Metascore", self);
		
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
			
			NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
			[_game setMetascore:metascore];
			[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
				
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
	
	_operationQueue = [[NSOperationQueue alloc] init];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Media - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
//		NSLog(@"%@", JSON);
		
		NSDictionary *results = JSON[@"results"];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		// Images
		if (results[@"images"] != [NSNull null]){
			NSInteger index = 0;
			for (NSDictionary *dictionary in results[@"images"]){
				NSString *stringURL = [Tools stringFromSourceIfNotNull:dictionary[@"super_url"]];
				if (stringURL) stringURL = [stringURL stringByReplacingOccurrencesOfString:@"scale_large" withString:@"original"];
				Image *image = [Image findFirstByAttribute:@"url" withValue:stringURL inContext:context];
				if (!image){
					image = [Image createInContext:context];
					[image setUrl:stringURL];
				}
				[image setIndex:@(index)];
				[game addImagesObject:image];
				
				if (index == 2) [self downloadImageWithURL:[NSURL URLWithString:stringURL]];
				
				index++;
			}
		}
		
		// Videos
		if (results[@"videos"] != [NSNull null]){
			NSInteger index = 0;
			for (NSDictionary *dictionary in results[@"videos"]){
				NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
				Video *video = [Video findFirstByAttribute:@"identifier" withValue:identifier];
				if (!video){
					video = [Video createInContext:context];
					[video setIdentifier:identifier];
				}
				[video setIndex:@(index)];
				[video setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"title"]]];
				[game addVideosObject:video];
				
				if (index == 0) [self requestVideoWithIdentifier:identifier];
				
				index++;
			}
		}
		
		[context saveToPersistentStoreAndWait];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d", self, response.statusCode);
	}];
	[operation start];
}

- (void)downloadImageWithURL:(NSURL *)URL{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setHTTPMethod:@"GET"];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
//		NSLog(@"Success in %@ - Image", self);
		
//		NSLog(@"image   size: %.fx%.f", image.size.width, image.size.height);
		
		UIImage *scaledImage = [Tools imageWithImage:image scaledToWidth:image.size.width * 2];
		UIImage *scaledThumbnail = [Tools imageWithImage:image scaledToHeight:180];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		Image *img = [Image findFirstByAttribute:@"url" withValue:URL.absoluteString];
		[img setData:UIImagePNGRepresentation(scaledImage)];
		[img setThumbnailData:UIImagePNGRepresentation(scaledThumbnail)];
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
//			[self refresh];
		}];
	}];
	[operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
//		NSLog(@"Received %lld of %lld bytes", totalBytesRead, totalBytesExpectedToRead);
		
//		[_progressIndicator setValue:(float)totalBytesRead/(float)totalBytesExpectedToRead];
	}];
	[_operationQueue addOperation:operation];
}

- (void)requestVideoWithIdentifier:(NSNumber *)identifier{
	NSURLRequest *request = [SessionManager URLRequestForVideoWithFields:@"id,name,deck,video_type,length_seconds,publish_date,high_url,low_url,image" identifier:identifier];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Video - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
//		NSLog(@"%@", JSON);
		
		[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		NSDictionary *results = JSON[@"results"];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		Video *video = [Video findFirstByAttribute:@"identifier" withValue:identifier];
		[video setTitle:[Tools stringFromSourceIfNotNull:results[@"name"]]];
		[video setOverview:[Tools stringFromSourceIfNotNull:results[@"deck"]]];
		[video setType:[Tools stringFromSourceIfNotNull:results[@"video_type"]]];
		[video setLength:[Tools integerNumberFromSourceIfNotNull:results[@"length_seconds"]]];
		[video setPublishDate:[[Tools dateFormatter] dateFromString:results[@"publish_date"]]];
		[video setHighQualityURL:[Tools stringFromSourceIfNotNull:results[@"high_url"]]];
		[video setLowQualityURL:[Tools stringFromSourceIfNotNull:results[@"low_url"]]];
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			NSString *stringURL = [Tools stringFromSourceIfNotNull:results[@"image"][@"super_url"]];
			if (stringURL) stringURL = [stringURL stringByReplacingOccurrencesOfString:@"scale_large" withString:@"original"];
			[self downloadVideoImageWithURL:[NSURL URLWithString:stringURL] video:video];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		NSLog(@"Failure in %@ - Status code: %d - Video", self, response.statusCode);
	}];
	[_operationQueue addOperation:operation];
}

- (void)downloadVideoImageWithURL:(NSURL *)URL video:(Video *)video{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setHTTPMethod:@"GET"];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		UIImage *scaledImage = [Tools imageWithImage:image scaledToWidth:image.size.width * 2];
		UIImage *scaledThumbnail = [Tools imageWithImage:image scaledToHeight:180];
		
		Image *newImage = [Image findFirstByAttribute:@"url" withValue:URL];
		if (!newImage) newImage = [Image createInContext:context];
		[newImage setUrl:URL.absoluteString];
		[newImage setData:UIImagePNGRepresentation(scaledImage)];
		[newImage setThumbnailData:UIImagePNGRepresentation(scaledThumbnail)];
		
		[video setImage:newImage];
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self refresh];
		}];
	}];
	[operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
//		NSLog(@"Received %lld of %lld bytes", totalBytesRead, totalBytesExpectedToRead);
		
//		[_progressIndicator setValue:(float)totalBytesRead/(float)totalBytesExpectedToRead];
	}];
	[_operationQueue addOperation:operation];
}

#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex){
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		[_game setSelectedPlatform:_game.platforms.allObjects[buttonIndex]];
		[_game setWanted:(_pressedButtonTag == kWantButtonTag) ? @(YES) : @(NO)];
		[_game setOwned:(_pressedButtonTag == kOwnButtonTag) ? @(YES) : @(NO)];
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self.navigationController popToRootViewControllerAnimated:YES];
		}];
	}
}

#pragma mark - Custom

- (void)refresh{
	UIImage *coverImage = [UIImage imageWithData:_game.coverImage.data];
	[_coverImageView setFrame:CGRectMake(_coverImageView.frame.origin.x, _coverImageView.frame.origin.y, coverImage.size.width * 0.5, _coverImageView.frame.size.height)];
	[_coverImageView setImage:coverImage];
//	[_progressIndicator setHidden:(_game.coverImage.data) ? YES : NO];
	[_metascoreLabel setText:_game.metascore];
	[_titleLabel setText:_game.title];
	
	[_releaseDateLabel setText:_game.releaseDateText];
	[_wantButton setHidden:([_game.wanted isEqualToNumber:@(YES)] || [_game.owned isEqualToNumber:@(YES)]) ? YES : NO];
	[_ownButton setHidden:([_game.owned isEqualToNumber:@(YES)] || [_game.released isEqualToNumber:@(NO)]) ? YES : NO];
	
	[_descriptionTextView setText:_game.overview];
	if (_game.platforms.count > 0) [_platformLabel setText:[_game.platforms.allObjects[0] abbreviation]];
	if (_game.genres.count > 0) [_genreFirstLabel setText:[_game.genres.allObjects[0] name]];
	if (_game.genres.count > 1) [_genreSecondLabel setText:[_game.genres.allObjects[1] name]];
	if (_game.developers.count > 0) [_developerLabel setText:[_game.developers.allObjects[0] name]];
	if (_game.publishers.count > 0) [_publisherLabel setText:[_game.publishers.allObjects[0] name]];
	
	NSArray *images = [Image findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game = %@", _game]];
	for (Image *image in images){
		UIImage *img = [UIImage imageWithData:image.thumbnailData];
		CGSize imageSize = CGSizeMake(img.size.width * 0.5, img.size.height * 0.5);
		
//		if (img.size.width != 0) NSLog(@"image   size: %.fx%.f", imageSize.width, imageSize.height);
		CGFloat offset = (_imagesScrollView.frame.size.width - imageSize.width) * 0.5;
		CGFloat position = (_imagesScrollView.frame.size.width * image.index.integerValue) + offset;
		
		[_imagesScrollView setContentSize:CGSizeMake(_imagesScrollView.frame.size.width * images.count, _imagesScrollView.frame.size.height)];
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(position, 0, imageSize.width, imageSize.height)];
		[imageView setImage:img];
		[_imagesScrollView addSubview:imageView];
	}
	
	NSArray *videos = [Video findAllSortedBy:@"index" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"game = %@", _game]];
	for (Video *video in videos){
		NSInteger index = [videos indexOfObject:video];
		
		UIImage *image = [UIImage imageWithData:video.image.thumbnailData];
		CGSize imageSize = CGSizeMake(image.size.width * 0.5, image.size.height * 0.5);
		
		CGFloat offset = (_videosScrollView.frame.size.width - imageSize.width) * 0.5;
		CGFloat position = (_videosScrollView.frame.size.width * index) + offset;
		
		[_videosScrollView setContentSize:CGSizeMake(_videosScrollView.frame.size.width * videos.count, _videosScrollView.frame.size.height)];
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(position, 0, imageSize.width, imageSize.height)];
		[imageView setImage:image];
		[_videosScrollView addSubview:imageView];
		
		CGFloat buttonOffset = (_videosScrollView.frame.size.width - 44) * 0.5;
		CGFloat buttonPosition = (_videosScrollView.frame.size.width * index) + buttonOffset;
		
		UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
		[button setFrame:CGRectMake(buttonPosition, 58, 44, 44)];
		[button setTitle:@"Play" forState:UIControlStateNormal];
		[button setBackgroundColor:[UIColor blackColor]];
		[button setTag:video.identifier.integerValue];
		[button addTarget:self action:@selector(playButtonPressAction:) forControlEvents:UIControlEventTouchUpInside];
		
		[_videosScrollView addSubview:button];
	}
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
	NSDateComponents *currentComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	[currentComponents setQuarter:[self quarterForMonth:currentComponents.month]];
	
	// Components for next month, next quarter, next year
	NSDateComponents *nextComponents = [calendar components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	nextComponents.month++;
	[nextComponents setQuarter:[self quarterForMonth:nextComponents.month]];
	nextComponents.year++;
	
	NSInteger period = 0;
	if ([releaseDate.date compare:[calendar dateFromComponents:currentComponents]] <= NSOrderedSame) period = 1;
	else if ([releaseDate.month isEqualToNumber:@(currentComponents.month)]) period = 2;
	else if ([releaseDate.month isEqualToNumber:@(nextComponents.month)]) period = 3;
	else if ([releaseDate.quarter isEqualToNumber:@(currentComponents.quarter)]) period = 4;
	else if ([releaseDate.quarter isEqualToNumber:@(nextComponents.quarter)]) period = 5;
	else if ([releaseDate.year isEqualToNumber:@(currentComponents.year)]) period = 6;
	else if ([releaseDate.year isEqualToNumber:@(nextComponents.year)]) period = 7;
	else if ([releaseDate.year isEqualToNumber:@(2050)]) period = 8;
	
	return [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(period)];
}

#pragma mark - Actions

- (IBAction)addButtonPressAction:(UIButton *)sender{
	_pressedButtonTag = sender.tag;
	
	NSArray *favoritePlatforms = [Platform findAllWithPredicate:[NSPredicate predicateWithFormat:@"favorite = %@ AND self IN %@", @(YES), _game.platforms.allObjects]];
	
	if (favoritePlatforms.count > 1){
		UIActionSheet *actionSheet;
		if (!actionSheet) actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		for (Platform *platform in favoritePlatforms)
			[actionSheet addButtonWithTitle:platform.name];
		[actionSheet addButtonWithTitle:@"Cancel"];
		[actionSheet setCancelButtonIndex:favoritePlatforms.count];
		[actionSheet showInView:self.tabBarController.view];
	}
	else{
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		if (favoritePlatforms.count > 0)
			[_game setSelectedPlatform:favoritePlatforms[0]];
		[_game setWanted:(sender.tag == kWantButtonTag) ? @(YES) : @(NO)];
		[_game setOwned:(sender.tag == kOwnButtonTag) ? @(YES) : @(NO)];
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self.navigationController popToRootViewControllerAnimated:YES];
		}];
	}
}

- (IBAction)playButtonPressAction:(UIButton *)sender{
	Video *video = [Video findFirstByAttribute:@"identifier" withValue:@(sender.tag)];
	
	MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:video.highQualityURL]];
	[self presentMoviePlayerViewControllerAnimated:player];
}

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[self requestGameWithIdentifier:_game.identifier];
}

@end
