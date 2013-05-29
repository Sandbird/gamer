//
//  GameTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 4/23/13.
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
#import "GameMainCell.h"
#import "GameDescriptionCell.h"
#import "GameMediaCell.h"
#import "SessionManager.h"
#import <MACircleProgressIndicator/MACircleProgressIndicator.h>
#import "MediaViewController.h"

#define kWantButtonTag 1
#define kOwnButtonTag 2

@interface GameTableViewController ()

@property (nonatomic, assign) NSInteger pressedButtonTag;

@end

@implementation GameTableViewController

- (void)viewDidLoad{
	[super viewDidLoad];
}

- (void)viewDidLayoutSubviews{
	GameMainCell *cell = (GameMainCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	[Utilities addDropShadowToView:cell.coverImageView color:[UIColor blackColor] opacity:0.6 radius:5 offset:CGSizeZero];
	[cell.progressIndicator setColor:[UIColor whiteColor]];
}

- (void)viewWillAppear:(BOOL)animated{
	if (!_game){
		Game *game = [Game findFirstByAttribute:@"identifier" withValue:_searchResult.identifier];
		if (game) _game = game;
		else [self requestGameWithIdentifier:_searchResult.identifier];
	}
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section) {
		case 1: return @"Description"; break;
		case 2: return @"Images"; break;
		case 3: return @"Videos"; break;
		default: return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case 0: return 328;
		case 1: return 200;
		case 2: case 3: return 160;
		default: return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	switch (indexPath.section) {
		case 0:{
			GameMainCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MainCell" forIndexPath:indexPath];
			[cell.coverImageView setImage:[UIImage imageWithData:_game.coverImage]];
			[cell.metascoreLabel setText:_game.metascore];
			[cell.gameTitleLabel setText:_game.title];
			[cell.releaseDateLabel setText:_game.releaseDateText];
			
			[cell.wantButton setHidden:([_game.wanted isEqualToNumber:@(YES)] || [_game.owned isEqualToNumber:@(YES)]) ? YES : NO];
			[cell.ownButton setHidden:([_game.owned isEqualToNumber:@(YES)] || [_game.released isEqualToNumber:@(NO)]) ? YES : NO];
			
			UITapGestureRecognizer *gestureRecognizer;
			if (!gestureRecognizer) gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerAction:)];
			if (![cell.coverImageView.gestureRecognizers containsObject:gestureRecognizer]) [cell.coverImageView addGestureRecognizer:gestureRecognizer];
			
			return cell;
		}
		case 1:{
			GameDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DescriptionCell" forIndexPath:indexPath];
			[cell.descriptionTextView setText:_game.overview];
			if (_game.platforms.count > 0) [cell.platformsLabel setText:[_game.platforms.allObjects[0] nameShort]];
			if (_game.genres.count > 0) [cell.genrePrimaryLabel setText:[_game.genres.allObjects[0] name]];
			if (_game.genres.count > 1) [cell.genrePrimaryLabel setText:[_game.genres.allObjects[1] name]];
			if (_game.developers.count > 0) [cell.developerLabel setText:[_game.developers.allObjects[0] name]];
			if (_game.publishers.count > 0) [cell.publisherLabel setText:[_game.publishers.allObjects[0] name]];
			return cell;
		}
		case 2:{
			GameMediaCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MediaCell" forIndexPath:indexPath];
			
			return cell;
		}
		case 3:{
			GameMediaCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MediaCell" forIndexPath:indexPath];
			
			return cell;
		}
		default:
			return nil;
	}
}

#pragma mark - Networking

- (void)requestGameWithIdentifier:(NSNumber *)identifier{
	NSURLRequest *request = [SessionManager URLRequestForGameWithFields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers" identifier:identifier];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
//		NSLog(@"%@", JSON);
		
		[[Utilities dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		NSDictionary *results = JSON[@"results"];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		// Set game
		_game = [Game findFirstByAttribute:@"identifier" withValue:identifier];
		if (!_game) _game = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		
		// Main info
		[_game setIdentifier:identifier];
		[_game setTitle:[Utilities stringFromSourceIfNotNull:results[@"name"]]];
		[_game setOverview:[Utilities stringFromSourceIfNotNull:results[@"deck"]]];
		
		// Cover image
		if (results[@"image"] != [NSNull null]){
			NSString *URL = [Utilities stringFromSourceIfNotNull:results[@"image"][@"super_url"]];
			if (!_game.coverImage || ![_game.coverImageURL isEqualToString:URL]){
				[self requestImageWithURL:[NSURL URLWithString:URL]];
				[_game setCoverImageURL:URL];
			}
		}
		
		// Release date
		NSString *originalReleaseDate = [Utilities stringFromSourceIfNotNull:results[@"original_release_date"]];
		NSInteger expectedReleaseDay = [Utilities integerNumberFromSourceIfNotNull:results[@"expected_release_day"]].integerValue;
		NSInteger expectedReleaseMonth = [Utilities integerNumberFromSourceIfNotNull:results[@"expected_release_month"]].integerValue;
		NSInteger expectedReleaseQuarter = [Utilities integerNumberFromSourceIfNotNull:results[@"expected_release_quarter"]].integerValue;
		NSInteger expectedReleaseYear = [Utilities integerNumberFromSourceIfNotNull:results[@"expected_release_year"]].integerValue;
		
		NSCalendar *calendar = [NSCalendar currentCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		
		if (originalReleaseDate){
			NSDateComponents *originalReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[[Utilities dateFormatter] dateFromString:originalReleaseDate]];
			[originalReleaseDateComponents setQuarter:[self quarterForMonth:originalReleaseDateComponents.month]];
			
			NSDate *dateFromComponents = [calendar dateFromComponents:originalReleaseDateComponents];
			[_game setReleaseDate:dateFromComponents];
			[_game setReleaseDay:@(originalReleaseDateComponents.day)];
			[_game setReleaseMonth:@(originalReleaseDateComponents.month)];
			[_game setReleaseQuarter:@(originalReleaseDateComponents.quarter)];
			[_game setReleaseYear:@(originalReleaseDateComponents.year)];
			
			[[Utilities dateFormatter] setDateFormat:@"d MMM yyyy"];
			[_game setReleaseDateText:[[Utilities dateFormatter] stringFromDate:dateFromComponents]];
			[_game setReleased:@(YES)];
		}
		else{
			NSDateComponents *expectedReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
			
			if (expectedReleaseDay){
				[expectedReleaseDateComponents setDay:expectedReleaseDay];
				[expectedReleaseDateComponents setMonth:expectedReleaseMonth];
				[expectedReleaseDateComponents setQuarter:[self quarterForMonth:expectedReleaseMonth]];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Utilities dateFormatter] setDateFormat:@"d MMMM yyyy"];
			}
			else if (expectedReleaseMonth){
				[expectedReleaseDateComponents setMonth:expectedReleaseMonth + 1];
				[expectedReleaseDateComponents setDay:0];
				[expectedReleaseDateComponents setQuarter:[self quarterForMonth:expectedReleaseMonth]];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Utilities dateFormatter] setDateFormat:@"MMMM yyyy"];
			}
			else if (expectedReleaseQuarter){
				[expectedReleaseDateComponents setQuarter:expectedReleaseQuarter];
				[expectedReleaseDateComponents setMonth:((expectedReleaseQuarter * 3) + 1)];
				[expectedReleaseDateComponents setDay:0];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Utilities dateFormatter] setDateFormat:@"QQQ yyyy"];
			}
			else if (expectedReleaseYear){
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[expectedReleaseDateComponents setQuarter:4];
				[expectedReleaseDateComponents setMonth:13];
				[expectedReleaseDateComponents setDay:0];
				[[Utilities dateFormatter] setDateFormat:@"yyyy"];
			}
			else{
				[expectedReleaseDateComponents setYear:2050];
				[expectedReleaseDateComponents setQuarter:4];
				[expectedReleaseDateComponents setMonth:13];
				[expectedReleaseDateComponents setDay:0];
			}
			
			NSDate *expectedReleaseDate = [calendar dateFromComponents:expectedReleaseDateComponents];
			[_game setReleaseDate:expectedReleaseDate];
			[_game setReleaseDay:@(expectedReleaseDateComponents.day)];
			[_game setReleaseMonth:@(expectedReleaseDateComponents.month)];
			[_game setReleaseQuarter:@(expectedReleaseDateComponents.quarter)];
			[_game setReleaseYear:@(expectedReleaseDateComponents.year)];
			[_game setReleaseDateText:(expectedReleaseYear) ? [[Utilities dateFormatter] stringFromDate:expectedReleaseDate] : @"TBA"];
			
			[_game setReleased:@(NO)];
		}
		
		[_game setReleasePeriod:[self releasePeriodForGame:_game]];
		
        // Platforms
		if (results[@"platforms"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"platforms"]){
				Platform *platform = [Platform findFirstByAttribute:@"identifier" withValue:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (platform){
					[platform setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
					[platform setNameShort:[Utilities stringFromSourceIfNotNull:dictionary[@"abbreviation"]]];
					[_game addPlatformsObject:platform];
				}
			}
		}
        
		// Genres
		if (results[@"genres"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"genres"]){
				Genre *genre = [Genre findFirstByAttribute:@"identifier" withValue:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (genre)
					[genre setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					genre = [[Genre alloc] initWithEntity:[NSEntityDescription entityForName:@"Genre" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[genre setIdentifier:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[genre setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addGenresObject:genre];
			}
		}
		
		// Developers
		if (results[@"developers"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"developers"]){
				Developer *developer = [Developer findFirstByAttribute:@"identifier" withValue:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (developer)
					[developer setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					developer = [[Developer alloc] initWithEntity:[NSEntityDescription entityForName:@"Developer" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[developer setIdentifier:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[developer setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addDevelopersObject:developer];
			}
		}
		
		// Publishers
		if (results[@"publishers"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"publishers"]){
				Publisher *publisher = [Publisher findFirstByAttribute:@"identifier" withValue:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (publisher)
					[publisher setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					publisher = [[Publisher alloc] initWithEntity:[NSEntityDescription entityForName:@"Publisher" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[publisher setIdentifier:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[publisher setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addPublishersObject:publisher];
			}
		}
		
		// Franchises
		if (results[@"franchises"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"franchises"]){
				Franchise *franchise = [Franchise findFirstByAttribute:@"identifier" withValue:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (franchise)
					[franchise setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					franchise = [[Franchise alloc] initWithEntity:[NSEntityDescription entityForName:@"Franchise" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[franchise setIdentifier:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[franchise setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addFranchisesObject:franchise];
			}
		}
		
		// Themes
		if (results[@"themes"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"themes"]){
				Theme *theme = [Theme findFirstByAttribute:@"identifier" withValue:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
				if (theme)
					[theme setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
				else{
					theme = [[Theme alloc] initWithEntity:[NSEntityDescription entityForName:@"Theme" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[theme setIdentifier:[Utilities integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[theme setName:[Utilities stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addThemesObject:theme];
			}
		}
		
		// Images
		if (results[@"images"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"images"]){
				Image *image = [Image findFirstByAttribute:@"url" withValue:[Utilities stringFromSourceIfNotNull:dictionary[@"super_url"]] inContext:context];
				if (!image){
					image = [[Image alloc] initWithEntity:[NSEntityDescription entityForName:@"Image" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[image setUrl:[Utilities stringFromSourceIfNotNull:dictionary[@"super_url"]]];
				}
				[_game addImagesObject:image];
			}
		}
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self.tableView reloadData];
			
			// If game is released and has at least one platform, request metascore
			if ([_game.releasePeriod.identifier isEqualToNumber:@(1)] && _game.platforms.count > 0)
				[self requestMetascoreForGameWithTitle:_game.title platform:_game.platforms.allObjects[0]];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Error: %@", self, response.statusCode, error.description);
	}];
	[operation start];
}

- (void)requestImageWithURL:(NSURL *)URL{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setHTTPMethod:@"GET"];
	
	GameMainCell *cell = (GameMainCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	[cell.progressIndicator setValue:0];
	[cell.progressIndicator setHidden:NO];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
		NSLog(@"Success in %@ - Cover image", self);
		
		UIImage *imageLarge = [self imageWithImage:image scaledToWidth:300];
		UIImage *imageSmall = [self imageWithImage:image scaledToWidth:200];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		[_game setCoverImage:UIImagePNGRepresentation(imageLarge)];
		[_game setCoverImageSmall:UIImagePNGRepresentation(imageSmall)];
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			GameMainCell *cell = (GameMainCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				CATransition *transition = [CATransition animation];
				transition.type = kCATransitionFade;
				transition.duration = 0.2;
				transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
				[cell.coverImageView setImage:image];
				[cell.progressIndicator setHidden:YES];
				[Utilities addDropShadowToView:cell.coverImageView color:[UIColor blackColor] opacity:0.6 radius:5 offset:CGSizeZero];
				[cell.coverImageView.layer addAnimation:transition forKey:nil];
				
//				NSLog(@"image:      %.2fx%.2f", image.size.width, image.size.height);
//				NSLog(@"imageLarge: %.2fx%.2f", imageLarge.size.width, imageLarge.size.height);
//				NSLog(@"imageSmall: %.2fx%.2f", imageSmall.size.width, imageSmall.size.height);
			});
		}];
	}];
	[operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
//		NSLog(@"Received %lld of %lld bytes", totalBytesRead, totalBytesExpectedToRead);
		
		[cell.progressIndicator setValue:(float)totalBytesRead/(float)totalBytesExpectedToRead];
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
				GameMainCell *cell = (GameMainCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
				[cell.metascoreLabel setText:metascore];
				
//				if (metascore.length > 0 && _metascoreView.isHidden){
//					CATransition *transition = [CATransition animation];
//					transition.type = kCATransitionFade;
//					transition.duration = 0.2;
//					transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
//					[_metascoreView setHidden:NO];
//					[_metascoreView.layer addAnimation:transition forKey:nil];
//				}
			}];
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Failure in %@ - Error: %@ - Metascore", self, error.description);
	}];
	[operation start];
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

- (NSInteger)quarterForMonth:(NSInteger)month{
	switch (month) {
		case 1: case 2: case 3: return 1;
		case 4: case 5: case 6: return 2;
		case 7: case 8: case 9: return 3;
		case 10: case 11: case 12: return 4;
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

#pragma mark - Actions

- (void)tapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	[self performSegueWithIdentifier:@"MediaSegue" sender:nil];
}

- (IBAction)addButtonPressAction:(UIButton *)sender{
	_pressedButtonTag = sender.tag;
	
	NSArray *favoritePlatforms = [Platform findAllWithPredicate:[NSPredicate predicateWithFormat:@"favorite == %@ AND self IN %@", @(YES), _game.platforms.allObjects]];
	
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

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[self requestGameWithIdentifier:_game.identifier];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	MediaViewController *destination = segue.destinationViewController;
	[destination setImage:[UIImage imageWithData:_game.coverImage]];
}

@end
