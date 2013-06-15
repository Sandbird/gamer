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
#import "SessionManager.h"
//#import "MediaViewController.h"

#define kWantButtonTag 1
#define kOwnButtonTag 2

@interface GameTableViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet MACircleProgressIndicator *progressIndicator;
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

@end

@implementation GameTableViewController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	if (!_game){
		Game *game = [Game findFirstByAttribute:@"identifier" withValue:_searchResult.identifier];
		if (game) _game = game;
		else [self requestGameWithIdentifier:_searchResult.identifier];
	}
}

- (void)viewDidLayoutSubviews{
	[Tools addDropShadowToView:_coverImageView color:[UIColor blackColor] opacity:0.6 radius:5 offset:CGSizeZero];
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
		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		//		NSLog(@"%@", JSON);
		
		[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		NSDictionary *results = JSON[@"results"];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		// Set game
		_game = [Game findFirstByAttribute:@"identifier" withValue:identifier];
		if (!_game) _game = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		
		// Main info
		[_game setIdentifier:identifier];
		[_game setTitle:[Tools stringFromSourceIfNotNull:results[@"name"]]];
		[_game setOverview:[Tools stringFromSourceIfNotNull:results[@"deck"]]];
		
		// Cover image
		if (results[@"image"] != [NSNull null]){
			NSString *URL = [Tools stringFromSourceIfNotNull:results[@"image"][@"super_url"]];
			if (!_game.coverImage || ![_game.coverImageURL isEqualToString:URL]){
				[self requestImageWithURL:[NSURL URLWithString:URL]];
				[_game setCoverImageURL:URL];
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
			
			NSDate *dateFromComponents = [calendar dateFromComponents:originalReleaseDateComponents];
			[_game setReleaseDate:dateFromComponents];
			[_game setReleaseDay:@(originalReleaseDateComponents.day)];
			[_game setReleaseMonth:@(originalReleaseDateComponents.month)];
			[_game setReleaseQuarter:@(originalReleaseDateComponents.quarter)];
			[_game setReleaseYear:@(originalReleaseDateComponents.year)];
			
			[[Tools dateFormatter] setDateFormat:@"d MMM yyyy"];
			[_game setReleaseDateText:[[Tools dateFormatter] stringFromDate:dateFromComponents]];
			[_game setReleased:@(YES)];
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
			
			NSDate *expectedReleaseDate = [calendar dateFromComponents:expectedReleaseDateComponents];
			[_game setReleaseDate:expectedReleaseDate];
			[_game setReleaseDay:@(expectedReleaseDateComponents.day)];
			[_game setReleaseMonth:@(expectedReleaseDateComponents.month)];
			[_game setReleaseQuarter:@(expectedReleaseDateComponents.quarter)];
			[_game setReleaseYear:@(expectedReleaseDateComponents.year)];
			[_game setReleaseDateText:(expectedReleaseYear) ? [[Tools dateFormatter] stringFromDate:expectedReleaseDate] : @"TBA"];
			
			[_game setReleased:@(NO)];
		}
		[_game setReleasePeriod:[self releasePeriodForGame:_game]];
		
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
					genre = [[Genre alloc] initWithEntity:[NSEntityDescription entityForName:@"Genre" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
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
					developer = [[Developer alloc] initWithEntity:[NSEntityDescription entityForName:@"Developer" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
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
					publisher = [[Publisher alloc] initWithEntity:[NSEntityDescription entityForName:@"Publisher" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
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
					franchise = [[Franchise alloc] initWithEntity:[NSEntityDescription entityForName:@"Franchise" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
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
					theme = [[Theme alloc] initWithEntity:[NSEntityDescription entityForName:@"Theme" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[theme setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
					[theme setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
				}
				[_game addThemesObject:theme];
			}
		}
		
		// Images
		if (results[@"images"] != [NSNull null]){
			for (NSDictionary *dictionary in results[@"images"]){
				Image *image = [Image findFirstByAttribute:@"url" withValue:[Tools stringFromSourceIfNotNull:dictionary[@"super_url"]] inContext:context];
				if (!image){
					image = [[Image alloc] initWithEntity:[NSEntityDescription entityForName:@"Image" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
					[image setUrl:[Tools stringFromSourceIfNotNull:dictionary[@"super_url"]]];
				}
				[_game addImagesObject:image];
			}
		}
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self refresh];
			
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
	
	[_progressIndicator setValue:0];
	[_progressIndicator setHidden:NO];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
		NSLog(@"Success in %@ - Cover image", self);
		
		UIImage *imageLarge = [self imageWithImage:image scaledToWidth:300];
		UIImage *imageSmall = [self imageWithImage:image scaledToWidth:200];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		[_game setCoverImage:UIImagePNGRepresentation(imageLarge)];
		[_game setCoverImageSmall:UIImagePNGRepresentation(imageSmall)];
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				CATransition *transition = [CATransition animation];
				transition.type = kCATransitionFade;
				transition.duration = 0.2;
				transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
				[_coverImageView setImage:image];
				[_progressIndicator setHidden:YES];
				[_coverImageView.layer addAnimation:transition forKey:nil];
				
				//				NSLog(@"image:      %.2fx%.2f", image.size.width, image.size.height);
				//				NSLog(@"imageLarge: %.2fx%.2f", imageLarge.size.width, imageLarge.size.height);
				//				NSLog(@"imageSmall: %.2fx%.2f", imageSmall.size.width, imageSmall.size.height);
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
				[_metascoreLabel setText:metascore];
				
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

- (void)refresh{
	[_coverImageView setImage:[UIImage imageWithData:_game.coverImage]];
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
	
	return [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(period)];
}

#pragma mark - Actions

- (void)tapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	[self performSegueWithIdentifier:@"MediaSegue" sender:nil];
}

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

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[self requestGameWithIdentifier:_game.identifier];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
//	MediaViewController *destination = segue.destinationViewController;
//	[destination setImage:[UIImage imageWithData:_game.coverImage]];
}

@end
