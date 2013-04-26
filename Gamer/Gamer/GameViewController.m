//
//  GameViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "GameViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AFNetworking/AFNetworking.h>
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "Image.h"
#import "Video.h"
#import "SessionManager.h"
#import "ReleasePeriod.h"

#define setTargetIfValueNotNull(target, value) if (value != [NSNull null]) target = value;

@interface GameViewController ()

@end

@implementation GameViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	_dateFormatter = [[NSDateFormatter alloc] init];
	[_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
	[_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
//	[self setInterfaceElementsWithGame:_game];
}

- (void)viewDidLayoutSubviews{
	[_coverImageShadowView setClipsToBounds:NO];
	[_coverImageShadowView.layer setShadowPath:[UIBezierPath bezierPathWithRect:_coverImageShadowView.bounds].CGPath];
	[_coverImageShadowView.layer setShadowColor:[UIColor blackColor].CGColor];
	[_coverImageShadowView.layer setShadowOpacity:0.6];
	[_coverImageShadowView.layer setShadowRadius:5];
	[_coverImageShadowView.layer setShadowOffset:CGSizeMake(0, 0)];
	
	[_metascoreView setClipsToBounds:NO];
	[_metascoreView.layer setShadowPath:[UIBezierPath bezierPathWithRect:_metascoreView.bounds].CGPath];
	[_metascoreView.layer setShadowColor:[UIColor blackColor].CGColor];
	[_metascoreView.layer setShadowOpacity:0.6];
	[_metascoreView.layer setShadowRadius:5];
	[_metascoreView.layer setShadowOffset:CGSizeMake(0, 0)];
}

- (void)viewWillAppear:(BOOL)animated{
//	// If coming from search load game from database
//	if (_searchResult){
//		[self.navigationItem setTitle:[_searchResult.title componentsSeparatedByString:@":"][0]];
//		Game *game = [Game findFirstByAttribute:@"identifier" withValue:_searchResult.identifier];
//		if (game){
//			_game = game;
//			[self setInterfaceElementsWithGame:_game];
//		}
//		else
//			[self requestGameWithIdentifier:_searchResult.identifier];
//	}
//	else{
//		[self.navigationItem setTitle:[_game.title componentsSeparatedByString:@":"][0]];
//		[self requestGameWithIdentifier:_game.identifier];
//	}
}

- (void)viewDidAppear:(BOOL)animated{
	[_imagesScrollView setContentSize:CGSizeMake(_imagesScrollView.frame.size.width + 1, _imagesScrollView.frame.size.height)];
	[_videosScrollView setContentSize:CGSizeMake(_videosScrollView.frame.size.width + 1, _videosScrollView.frame.size.height)];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated{
	[_previousOperation cancel];
//	if ([_game.temporary isEqualToNumber:@(YES)]){
//		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
//		[Game deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", _game.identifier] inContext:context];
//		[context saveToPersistentStoreAndWait];
//	}
}

#pragma mark -
#pragma mark Networking

- (void)requestGameWithIdentifier:(NSString *)identifier{
	NSString *url = [NSString stringWithFormat:@"http://www.giantbomb.com/api/game/3030-%@/?api_key=d92c258adb509ded409d28f4e51de2c83e297011&format=json&field_list=deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,images,name,original_release_date,platforms,publishers,similar_games,themes,videos", identifier];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		NSLog(@"%@", JSON);
		
		[_dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		NSDictionary *results = JSON[@"results"];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		Game *game = [Game findFirstByAttribute:@"identifier" withValue:[results[@"id"] stringValue]];
		_game = (game) ? game : [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		
		// Information
//		[_game setIdentifier:results[@"id"]];
		setTargetIfValueNotNull(_game.title, results[@"name"]);
		setTargetIfValueNotNull(_game.overview, results[@"deck"]);
		
		// Image
		NSString *imageURL;
		setTargetIfValueNotNull(imageURL, results[@"image"][@"super_url"]);
		[self requestImageWithURL:[NSURL URLWithString:imageURL]];
		
		// similar games
		// releases
		// screenshots
		// videos
		
		// Release date
		NSString *releaseDate;
		NSString *day;
		NSString *month;
		NSString *quarter;
		NSString *year;
		
		setTargetIfValueNotNull(releaseDate, results[@"original_release_date"]);
		setTargetIfValueNotNull(day, results[@"expected_release_day"]);
		setTargetIfValueNotNull(month, results[@"expected_release_month"]);
		setTargetIfValueNotNull(quarter, results[@"expected_release_quarter"]);
		setTargetIfValueNotNull(year, results[@"expected_release_year"]);
		
		NSCalendar *calendar = [NSCalendar currentCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		
		if (releaseDate){
			NSDateComponents *components = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[_dateFormatter dateFromString:releaseDate]];
			
			[components setQuarter:[self quarterForMonth:components.month]];
			
			NSDate *date = [calendar dateFromComponents:components];
			[_game setReleaseDate:date];
			[_game setReleaseDay:@(components.day)];
			[_game setReleaseMonth:@(components.month)];
			[_game setReleaseQuarter:@(components.quarter)];
			[_game setReleaseYear:@(components.year)];
			
			[_dateFormatter setDateFormat:@"dd MMM yyyy"];
			[_game setReleaseDateText:[_dateFormatter stringFromDate:date]];
		}
		else{
			NSDateComponents *components = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
			
			if (day){
				[components setDay:day.integerValue];
				[components setMonth:month.integerValue];
				[components setQuarter:[self quarterForMonth:month.integerValue]];
				[components setYear:year.integerValue];
				
				[_dateFormatter setDateFormat:@"dd MMM yyyy"];
			}
			else if (month){
				// Set day to last day of month (setting day to 0 sets month to previous month, so (month + 1))
				[components setMonth:(month.integerValue + 1)];
				[components setDay:0];
				[components setQuarter:[self quarterForMonth:month.integerValue]];
				[components setYear:year.integerValue];
				
				[_dateFormatter setDateFormat:@"MMMM yyyy"];
			}
			else if (quarter){
				// Set month to last month of quarter and day to last day of that month (thus month + 1)
				[components setQuarter:quarter.integerValue];
				[components setMonth:((quarter.integerValue * 3) + 1)];
				[components setDay:0];
				[components setYear:year.integerValue];
				
				[_dateFormatter setDateFormat:@"QQQ yyyy"];
			}
			else if (year){
				[components setYear:year.integerValue];
				[components setQuarter:4];
				[components setMonth:13];
				[components setDay:0];
				
				[_dateFormatter setDateFormat:@"yyyy"];
			}
			else{
				// TBA
				[components setYear:2050];
				[components setQuarter:4];
				[components setMonth:13];
				[components setDay:0];
				
				[_dateFormatter setDateFormat:@"TBA"];
			}
			
			NSDate *date = [calendar dateFromComponents:components];
			
			[_game setReleaseDate:date];
			[_game setReleaseDay:@(components.day)];
			[_game setReleaseMonth:@(components.month)];
			[_game setReleaseQuarter:@(components.quarter)];
			[_game setReleaseYear:@(components.year)];
			
			[_game setReleaseDateText:([_dateFormatter.dateFormat isEqualToString:@"TBA"]) ? @"TBA" : [_dateFormatter stringFromDate:date]];
		}
		
		[_game setReleasePeriod:[self releasePeriodForGame:_game]];
		
//		NSLog(@"%@", _game.releaseDate);
//		NSLog(@"%@", _game.releaseDateText);
//		NSLog(@"%@", _game.releaseMonth);
//		NSLog(@"%@", _game.releaseQuarter);
//		NSLog(@"%@", _game.releaseYear);
		
		// Genre
		if (results[@"genres"] != [NSNull null]){
			for (NSDictionary *genreDictionary in results[@"genres"]){
				Genre *genre = [Genre findFirstByAttribute:@"identifier" withValue:genreDictionary[@"id"] inContext:context];
				if (genre) [genre setName:genreDictionary[@"name"]];
				else{
					genre = [[Genre alloc] initWithEntity:[NSEntityDescription entityForName:@"Genre" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[genre setIdentifier:[genreDictionary[@"id"] stringValue]];
					[genre setName:genreDictionary[@"name"]];
				}
				[_game addGenresObject:genre];
			}
		}
		
		// Platforms
		if (results[@"platforms"] != [NSNull null]){
			for (NSDictionary *platformDictionary in results[@"platforms"]){
				if ([platformDictionary[@"name"] isEqualToString:@"Xbox 360"] || [platformDictionary[@"name"] isEqualToString:@"PlayStation 3"] || [platformDictionary[@"name"] isEqualToString:@"PC"] || [platformDictionary[@"name"] isEqualToString:@"Wii U"]){
					Platform *platform = [Platform findFirstByAttribute:@"identifier" withValue:platformDictionary[@"id"] inContext:context];
					if (platform) [platform setName:platformDictionary[@"name"]];
					else{
						platform = [[Platform alloc] initWithEntity:[NSEntityDescription entityForName:@"Platform" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
						[platform setIdentifier:[platformDictionary[@"id"] stringValue]];
						[platform setName:platformDictionary[@"name"]];
						[platform setNameShort:platformDictionary[@"abbreviation"]];
					}
					[_game addPlatformsObject:platform];
				}
			}
		}
		
		// Developers
		if (results[@"developers"] != [NSNull null]){
			for (NSDictionary *developerDictionary in results[@"developers"]){
				Developer *developer = [Developer findFirstByAttribute:@"identifier" withValue:developerDictionary[@"id"] inContext:context];
				if (developer) [developer setName:developerDictionary[@"name"]];
				else{
					developer = [[Developer alloc] initWithEntity:[NSEntityDescription entityForName:@"Developer" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[developer setIdentifier:[developerDictionary[@"id"] stringValue]];
					[developer setName:developerDictionary[@"name"]];
				}
				[_game addDevelopersObject:developer];
			}
		}
		
		// Publishers
		if (results[@"publishers"] != [NSNull null]){
			for (NSDictionary *publisherDictionary in results[@"publishers"]){
				Publisher *publisher = [Publisher findFirstByAttribute:@"identifier" withValue:publisherDictionary[@"id"] inContext:context];
				if (publisher) [publisher setName:publisherDictionary[@"name"]];
				else{
					publisher = [[Publisher alloc] initWithEntity:[NSEntityDescription entityForName:@"Publisher" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[publisher setIdentifier:[publisherDictionary[@"id"] stringValue]];
					[publisher setName:publisherDictionary[@"name"]];
				}
				[_game addPublishersObject:publisher];
			}
		}
		
		// Franchises
		if (results[@"franchises"] != [NSNull null]){
			for (NSDictionary *franchiseDictionary in results[@"franchises"]){
				Franchise *franchise = [Franchise findFirstByAttribute:@"identifier" withValue:franchiseDictionary[@"id"] inContext:context];
				if (franchise) [franchise setName:franchiseDictionary[@"name"]];
				else{
					franchise = [[Franchise alloc] initWithEntity:[NSEntityDescription entityForName:@"Franchise" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[franchise setIdentifier:[franchiseDictionary[@"id"] stringValue]];
					[franchise setName:franchiseDictionary[@"name"]];
				}
				[_game addFranchisesObject:franchise];
			}
		}
		
		// Themes
		if (results[@"themes"] != [NSNull null]){
			for (NSDictionary *themeDictionary in results[@"themes"]){
				Theme *theme = [Theme findFirstByAttribute:@"identifier" withValue:themeDictionary[@"id"] inContext:context];
				if (theme) [theme setName:themeDictionary[@"name"]];
				else{
					theme = [[Theme alloc] initWithEntity:[NSEntityDescription entityForName:@"Theme" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[theme setIdentifier:[themeDictionary[@"id"] stringValue]];
					[theme setName:themeDictionary[@"name"]];
				}
				[_game addThemesObject:theme];
			}
		}
		
		// Images
		if (results[@"images"] != [NSNull null]){
			for (NSDictionary *imageDictionary in results[@"images"]){
				Image *image = [Image findFirstByAttribute:@"url" withValue:imageDictionary[@"super_url"] inContext:context];
				if (image) [image setUrl:imageDictionary[@"super_url"]];
				else{
					image = [[Image alloc] initWithEntity:[NSEntityDescription entityForName:@"Image" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[image setUrl:imageDictionary[@"super_url"]];
				}
				[_game addImagesObject:image];
			}
		}
		
		[context saveToPersistentStoreAndWait];
		
		[self setInterfaceElementsWithGame:_game];
		
		NSDateComponents *todayComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
		
		if ([_game.releaseDate compare:[calendar dateFromComponents:todayComponents]] < NSOrderedSame && _game.platforms.count > 0)
			[self requestMetascoreForGameWithTitle:_game.title andPlatformWithName:[_game.platforms.allObjects[0] name]];
		
		if (_searchResult){
			if ([_game.releaseDate compare:[calendar dateFromComponents:todayComponents]] >= NSOrderedSame){
				UIBarButtonItem *trackButton = [[UIBarButtonItem alloc] initWithTitle:@"Track" style:UIBarButtonItemStylePlain target:self action:@selector(trackButtonPressAction)];
				[self.navigationItem setRightBarButtonItem:trackButton animated:YES];
			}
			else if ([_game.releaseDate compare:[calendar dateFromComponents:todayComponents]] <= NSOrderedSame){
				UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveButtonPressAction)];
				[self.navigationItem setRightBarButtonItem:saveButton animated:YES];
			}
		}
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Error: %@", self, response.statusCode, error.description);
	}];
	[operation start];
	_previousOperation = operation;
}

- (void)requestImageWithURL:(NSURL *)url{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"GET"];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
		UIImage *imageLarge = [self imageWithImage:image scaledToWidth:300];
		UIImage *imageSmall = [self imageWithImage:image scaledToWidth:200];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		[_game setImage:UIImagePNGRepresentation(imageLarge)];
		[_game setImageSmall:UIImagePNGRepresentation(imageSmall)];
		[context saveToPersistentStoreAndWait];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			CATransition *transition = [CATransition animation];
			transition.type = kCATransitionFade;
			transition.duration = 0.2;
			transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			[_coverImageView setImage:image];
			[_coverImageView.layer addAnimation:transition forKey:nil];
		});
		
//		NSLog(@"image:      %.2fx%.2f", image.size.width, image.size.height);
//		NSLog(@"imageLarge: %.2fx%.2f", imageLarge.size.width, imageLarge.size.height);
//		NSLog(@"imageSmall: %.2fx%.2f", imageSmall.size.width, imageSmall.size.height);
	}];
	
	[operation start];
}

- (void)requestMetascoreForGameWithTitle:(NSString *)title andPlatformWithName:(NSString *)platform{
	NSString *formattedTitle = title.lowercaseString;
	formattedTitle = [formattedTitle stringByReplacingOccurrencesOfString:@"'" withString:@""];
	formattedTitle = [formattedTitle stringByReplacingOccurrencesOfString:@":" withString:@""];
	formattedTitle = [formattedTitle stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	
	NSString *formattedPlatform = platform.lowercaseString;
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
			
			NSLog(@"Metascore: %@", metascore);
			
			NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
			[_game setMetascore:metascore];
			[context saveToPersistentStoreAndWait];
			
			[_metascoreLabel setText:metascore];
			
			if (metascore.length > 0 && _metascoreView.isHidden){
				CATransition *transition = [CATransition animation];
				transition.type = kCATransitionFade;
				transition.duration = 0.2;
				transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
				[_metascoreView setHidden:NO];
				[_metascoreView.layer addAnimation:transition forKey:nil];
			}
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Failure in %@ - Error: %@ - Metascore", self, error.description);
	}];
	[operation start];
}

#pragma mark -
#pragma mark ActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex){
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"Track"]){
			[_game setSelectedPlatform:_game.platforms.allObjects[buttonIndex]];
			[context saveToPersistentStoreAndWait];
			[self.navigationController popToRootViewControllerAnimated:YES];
		}
		else if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"Save"]){
			[_game setSelectedPlatform:_game.platforms.allObjects[buttonIndex]];
			[context saveToPersistentStoreAndWait];
		}
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex && [self.navigationItem.rightBarButtonItem.title isEqualToString:@"Save"])
		[self.tabBarController setSelectedIndex:2];
}

#pragma mark -
#pragma mark Custom

- (void)setInterfaceElementsWithGame:(Game *)game{
	[self.navigationItem setTitle:[_game.title componentsSeparatedByString:@":"][0]];
	[_coverImageView setImage:[UIImage imageWithData:game.image]];
	if (game.metascore) [_metascoreView setHidden:NO];
	[_metascoreLabel setText:game.metascore];
	[_releaseDateLabel setText:game.releaseDateText];
	if (game.genres.count > 0) [_genreFirstLabel setText:[game.genres.allObjects[0] name]];
	if (game.genres.count > 1) [_genreSecondLabel setText:[game.genres.allObjects[1] name]];
	if (game.platforms.count > 0) [_platformFirstLabel setText:[game.platforms.allObjects[0] name]];
	if (game.platforms.count > 1) [_platformSecondLabel setText:[game.platforms.allObjects[1] name]];
	if (game.developers.count > 0) [_developerLabel setText:[game.developers.allObjects[0] name]];
	if (game.publishers.count > 0) [_publisherLabel setText:[game.publishers.allObjects[0] name]];
	if (game.franchises.count > 0) [_franchiseFirstLabel setText:[game.franchises.allObjects[0] name]];
	if (game.franchises.count > 1) [_franchiseSecondLabel setText:[game.franchises.allObjects[1] name]];
	if (game.themes.count > 0) [_themeFirstLabel setText:[game.themes.allObjects[0] name]];
	if (game.themes.count > 1) [_themeSecondLabel setText:[game.themes.allObjects[1] name]];
	[_overviewTextView setText:game.overview];
	
	[self resizeContentViewsAndScrollView];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToWidth:(float)width{
	float scaleFactor = width/image.size.width;
	
	float newWidth = image.size.width * scaleFactor;
	float newHeight = image.size.height * scaleFactor;
	
	UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
	[image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
	
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

- (void)resizeContentViewsAndScrollView{
	[_overviewTextView setFrame:CGRectMake(_overviewTextView.frame.origin.x, _overviewTextView.frame.origin.y, _overviewTextView.contentSize.width, _overviewTextView.contentSize.height)];
	[_overviewContentView setFrame:CGRectMake(0, _overviewContentView.frame.origin.y, 320, _overviewTextView.frame.origin.y + _overviewTextView.frame.size.height + 10)];
	[_imagesContentView setFrame:CGRectMake(0, _overviewContentView.frame.origin.y + _overviewContentView.frame.size.height, 320, _imagesContentView.frame.size.height)];
	[_videosContentView setFrame:CGRectMake(0, _imagesContentView.frame.origin.y + _imagesContentView.frame.size.height, 320, _videosContentView.frame.size.height)];
	[_contentView setFrame:CGRectMake(0, 0, 320, _videosContentView.frame.origin.y + _videosContentView.frame.size.height)];
	[_scrollView setContentSize:CGSizeMake(_contentView.frame.size.width, _contentView.frame.size.height)];
}

- (NSInteger)quarterForMonth:(NSInteger)month{
	switch (month) {
		case 1: return 1;
		case 2: return 1;
		case 3: return 1;
		case 4: return 2;
		case 5: return 2;
		case 6: return 2;
		case 7: return 3;
		case 8: return 3;
		case 9: return 3;
		case 10: return 4;
		case 11: return 4;
		case 12: return 4;
		default: return 0;
	}
}

- (ReleasePeriod *)releasePeriodForGame:(Game *)game{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	// Components for today, this month, this quarter, this year
	NSDateComponents *currentComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	[currentComponents setQuarter:[self quarterForMonth:currentComponents.month]];
	
	// Components for next month, next quarter, next year
	NSDateComponents *nextComponents = [calendar components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	nextComponents.month++;
	[nextComponents setQuarter:[self quarterForMonth:nextComponents.month]];
	nextComponents.quarter++;
	nextComponents.year++;
	
	NSInteger period = 0;
	if ([game.releaseDate compare:[calendar dateFromComponents:currentComponents]] <= NSOrderedSame) period = 1;
	else if ([game.releaseMonth isEqualToNumber:@(currentComponents.month)]) period = 2;
	else if ([game.releaseMonth isEqualToNumber:@(nextComponents.month)]) period = 3;
	else if ([game.releaseQuarter isEqualToNumber:@(currentComponents.quarter)]) period = 4;
	else if ([game.releaseQuarter isEqualToNumber:@(nextComponents.quarter)]) period = 5;
	else if ([game.releaseYear isEqualToNumber:@(currentComponents.year)]) period = 6;
	else if ([game.releaseYear isEqualToNumber:@(nextComponents.year)]) period = 7;
	else if ([game.releaseYear isEqualToNumber:@(2050)]) period = 8;
	
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	
	ReleasePeriod *releasePeriod = [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(period)];
	if (!releasePeriod){
		releasePeriod = [[ReleasePeriod alloc] initWithEntity:[NSEntityDescription entityForName:@"ReleasePeriod" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		[releasePeriod setIdentifier:@(period)];
		switch (period) {
			case 1: [releasePeriod setName:@"Released"]; break;
			case 2: [releasePeriod setName:@"This Month"]; break;
			case 3: [releasePeriod setName:@"Next Month"]; break;
			case 4: [releasePeriod setName:@"This Quarter"]; break;
			case 5: [releasePeriod setName:@"Next Quarter"]; break;
			case 6: [releasePeriod setName:@"This Year"]; break;
			case 7: [releasePeriod setName:@"Next Year"]; break;
			case 8: [releasePeriod setName:@"To Be Announced"]; break;
			default: break;
		}
		[context saveToPersistentStoreAndWait];
	}
	
	return releasePeriod;
}

#pragma mark -
#pragma mark Actions

- (void)trackButtonPressAction{
	if (_game.platforms.count > 1){
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		
		for (Platform *platform in _game.platforms.allObjects)
			[actionSheet addButtonWithTitle:platform.name];
		
		[actionSheet addButtonWithTitle:@"Cancel"];
		[actionSheet setCancelButtonIndex:_game.platforms.count];
		
		[actionSheet showInView:self.tabBarController.view];
	}
	else{
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		if (_game.platforms.allObjects.count > 0)
			[_game setSelectedPlatform:_game.platforms.allObjects[0]];
		[context saveToPersistentStoreAndWait];
		
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
}

- (void)saveButtonPressAction{
	if (_game.platforms.count > 1){
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		
		for (Platform *platform in _game.platforms.allObjects)
			[actionSheet addButtonWithTitle:platform.name];
		
		[actionSheet addButtonWithTitle:@"Cancel"];
		[actionSheet setCancelButtonIndex:_game.platforms.count];
		
		[actionSheet showInView:self.tabBarController.view];
	}
	else{
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		[_game setSelectedPlatform:_game.platforms.allObjects[0]];
		[context saveToPersistentStoreAndWait];
		
		[self.tabBarController setSelectedIndex:2];
		[self.navigationController popToRootViewControllerAnimated:NO];
	}
}

- (IBAction)trailerButtonPressAction:(UIButton *)sender{
//	MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:_game.trailerURL]];
//	player.controlStyle=MPMovieControlStyleDefault;
//	player.shouldAutoplay=YES;
//	[self.view addSubview:player.view];
//	[player setFullscreen:YES animated:YES];
}

@end
