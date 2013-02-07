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
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"

@interface GameViewController ()

@end

@implementation GameViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self.navigationItem setTitle:[_game.title componentsSeparatedByString:@":"][0]];
	
	// UI setup
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
	
	_dateFormatter = [[NSDateFormatter alloc] init];
	[_dateFormatter setDateFormat:@"dd/MM/yyyy"];
	
	// Set data
	[_coverImageView setImage:[UIImage imageWithData:_game.image]];
	[_releaseDateLabel setText:[_dateFormatter stringFromDate:_game.releaseDate]];
	if (_game.genres.count > 0) [_genreFirstLabel setText:[[_game.genres allObjects][0] name]];
	if (_game.genres.count > 1) [_genreSecondLabel setText:[[_game.genres allObjects][1] name]];
	if (_game.platforms.count > 0) [_platformFirstLabel setText:[[_game.platforms allObjects][0] name]];
	if (_game.platforms.count > 1) [_platformSecondLabel setText:[[_game.platforms allObjects][1] name]];
	[_developerLabel setText:[[_game.developers allObjects][0] name]];
	[_publisherLabel setText:[[_game.publishers allObjects][0] name]];
	if (_game.franchises.count > 0) [_franchiseFirstLabel setText:[[_game.franchises allObjects][0] name]];
	if (_game.franchises.count > 1) [_franchiseSecondLabel setText:[[_game.franchises allObjects][1] name]];
	if (_game.themes.count > 0) [_themeFirstLabel setText:[[_game.themes allObjects][0] name]];
	if (_game.themes.count > 1) [_themeSecondLabel setText:[[_game.themes allObjects][1] name]];
	[_overviewTextView setText:_game.overview];
	[_overviewTextView setText:_game.overview];
	
	[self resizeContentViewsAndScrollView];
	
	if (_searchResult){
		[self.navigationItem setTitle:[_searchResult.title componentsSeparatedByString:@":"][0]];
		[self requestGameWithIdentifier:_searchResult.identifier];
	}
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Networking

- (void)requestGameWithIdentifier:(NSString *)identifier{
	NSString *url = [NSString stringWithFormat:@"http://api.giantbomb.com/game/%@/?api_key=d92c258adb509ded409d28f4e51de2c83e297011&format=json&field_list=deck,developers,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,images,name,original_release_date,platforms,publishers,releases,similar_games,themes,videos", identifier];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Game", self, response.statusCode);
		
		NSLog(@"%@", JSON);
		
		[_dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		NSDictionary *results = JSON[@"results"];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		_game = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		
		if (results[@"deck"] != [NSNull null]) [_game setOverview:results[@"deck"]];
		if (results[@"id"] != [NSNull null]) [_game setIdentifier:[results[@"id"] stringValue]];
		if (results[@"image"][@"super_url"] != [NSNull null]) [self requestImageWithURL:[NSURL URLWithString:results[@"image"][@"super_url"]]];
		if (results[@"name"] != [NSNull null]) [_game setTitle:results[@"name"]];
		// similar games
		// releases
		// screenshots
		// videos
		
		// Release date
		NSString *releaseDate = (results[@"original_release_date"] != [NSNull null]) ? results[@"original_release_date"] : nil;
		NSString *month = (results[@"expected_release_month"] != [NSNull null]) ? results[@"expected_release_month"] : nil;
		NSString *quarter = (results[@"expected_release_quarter"] != [NSNull null]) ? results[@"expected_release_quarter"] : nil;
		NSString *year = (results[@"expected_release_year"] != [NSNull null]) ? results[@"expected_release_year"] : nil;
		
		NSDateComponents *components = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
		
		if (releaseDate){
			[_game setReleaseDate:[_dateFormatter dateFromString:releaseDate]];
			[_dateFormatter setDateFormat:@"dd/MM/yyyy"];
			[_game setReleaseDateText:[_dateFormatter stringFromDate:_game.releaseDate]];
		}
		else if (month){
			[components setMonth:[month integerValue]];
			[components setQuarter:[quarter integerValue]];
			[components setYear:[year integerValue]];
			NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:components];
			[_game setReleaseDate:date];
			[_dateFormatter setDateFormat:@"MMM yyyy"];
			[_game setReleaseDateText:[_dateFormatter stringFromDate:date]];
		}
		else if (quarter){
			[components setMonth:1];
			[components setQuarter:[quarter integerValue]];
			[components setYear:[year integerValue]];
			NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:components];
			[_game setReleaseDate:date];
			[_dateFormatter setDateFormat:@"QQQ yyyy"];
			[_game setReleaseDateText:[_dateFormatter stringFromDate:date]];
		}
		else{
			[components setMonth:1];
			[components setQuarter:1];
			[components setYear:[year integerValue]];
			NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:components];
			[_game setReleaseDate:date];
			[_dateFormatter setDateFormat:@"yyyy"];
			[_game setReleaseDateText:[_dateFormatter stringFromDate:date]];
		}
		
		// Genre
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
		
		// Platforms
		for (NSDictionary *platformDictionary in results[@"platforms"]){
			Platform *platform = [Platform findFirstByAttribute:@"identifier" withValue:platformDictionary[@"id"] inContext:context];
			if (platform) [platform setName:platformDictionary[@"name"]];
			else{
				platform = [[Platform alloc] initWithEntity:[NSEntityDescription entityForName:@"Platform" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
				[platform setIdentifier:[platformDictionary[@"id"] stringValue]];
				[platform setName:platformDictionary[@"name"]];
			}
			[_game addPlatformsObject:platform];
		}
		
		// Developers
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
		
		// Publishers
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
		
		// Franchises
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
		
		// Themes
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
		
		[context saveToPersistentStoreAndWait];
		
		[self setInterfaceElementsWithGame:_game];
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		NSLog(@"Failure in %@ - Status code: %d - Game", self, response.statusCode);
	}];
	[operation start];
}

- (void)requestImageWithURL:(NSURL *)url{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"GET"];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
		[_game setImage:UIImagePNGRepresentation(image)];
		[_coverImageView setImage:image];
		NSLog(@"image: %.2fx%.2f", image.size.width, image.size.height);
	}];
	[operation start];
}

#pragma mark -
#pragma mark Custom

- (void)setInterfaceElementsWithGame:(Game *)game{
	[_releaseDateLabel setText:game.releaseDateText];
	if (_game.genres.count > 0) [_genreFirstLabel setText:[[game.genres allObjects][0] name]];
	if (_game.genres.count > 1) [_genreSecondLabel setText:[[game.genres allObjects][1] name]];
	if (_game.platforms.count > 0) [_platformFirstLabel setText:[[game.platforms allObjects][0] name]];
	if (_game.platforms.count > 1) [_platformSecondLabel setText:[[game.platforms allObjects][1] name]];
	if (_game.developers.count > 0) [_developerLabel setText:[[game.developers allObjects][0] name]];
	if (_game.publishers.count > 0) [_publisherLabel setText:[[game.publishers allObjects][0] name]];
	if (_game.franchises.count > 0) [_franchiseFirstLabel setText:[[game.franchises allObjects][0] name]];
	if (_game.franchises.count > 1) [_franchiseSecondLabel setText:[[game.franchises allObjects][1] name]];
	if (_game.themes.count > 0) [_themeFirstLabel setText:[[game.themes allObjects][0] name]];
	if (_game.themes.count > 1) [_themeSecondLabel setText:[[game.themes allObjects][1] name]];
	[_overviewTextView setText:game.overview];
	
	[self resizeContentViewsAndScrollView];
}

- (void)resizeContentViewsAndScrollView{
	[_overviewTextView setFrame:CGRectMake(_overviewTextView.frame.origin.x, _overviewTextView.frame.origin.y, _overviewTextView.contentSize.width, _overviewTextView.contentSize.height)];
	[_overviewContentView setFrame:CGRectMake(0, _overviewContentView.frame.origin.y, 320, _overviewTextView.frame.origin.y + _overviewTextView.frame.size.height + 10)];
	[_screenshotsContentView setFrame:CGRectMake(0, _overviewContentView.frame.origin.y + _overviewContentView.frame.size.height, 320, _screenshotsContentView.frame.size.height)];
	[_trailerContentView setFrame:CGRectMake(0, _screenshotsContentView.frame.origin.y + _screenshotsContentView.frame.size.height, 320, _trailerContentView.frame.size.height)];
	[_contentView setFrame:CGRectMake(0, 0, 320, _trailerContentView.frame.origin.y + _trailerContentView.frame.size.height)];
	[_scrollView setContentSize:CGSizeMake(_contentView.frame.size.width, _contentView.frame.size.height)];
}

#pragma mark -
#pragma mark Actions

- (IBAction)trackButtonPressAction:(UIBarButtonItem *)sender{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	[_game setTrack:@(YES)];
	[context saveToPersistentStoreAndWait];
	
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)trailerButtonPressAction:(UIButton *)sender{
	MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:_game.trailerURL]];
	player.controlStyle=MPMovieControlStyleDefault;
	player.shouldAutoplay=YES;
	[self.view addSubview:player.view];
	[player setFullscreen:YES animated:YES];
}

@end
