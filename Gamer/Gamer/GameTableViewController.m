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
#import "Utilities.h"

@interface GameTableViewController ()

@end

@implementation GameTableViewController

- (void)viewDidLoad{
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
	
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
			GameMainCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameMainCell" forIndexPath:indexPath];
			[cell.coverImageView setImage:[UIImage imageWithData:_game.image]];
			[cell.metascoreLabel setText:_game.metascore];
			[cell.gameTitleLabel setText:_game.title];
			[cell.releaseDateLabel setText:_game.releaseDateText];
			return cell;
		}
		case 1:{
			GameDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameDescriptionCell" forIndexPath:indexPath];
			[cell.descriptionTextView setText:_game.overview];
//			[cell.platformsLabel setText:[_game.platforms.allObjects[0] nameShort]];
//			[cell.developerLabel]
//			[cell.publisherLabel]
//			[cell.genrePrimaryLabel]
//			[cell.genreSecondaryLabel]
			return cell;
		}
		case 2:{
			GameMediaCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameMediaCell" forIndexPath:indexPath];
			return cell;
		}
		case 3:{
			GameMediaCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameMediaCell" forIndexPath:indexPath];
			
			return cell;
		}
		default:
			return nil;
	}
}

#pragma mark - Networking

- (void)requestGameWithIdentifier:(NSInteger)identifier{
	NSURLRequest *request = [SessionManager APIGameRequestWithFields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers" identifier:identifier];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		NSLog(@"%@", JSON);
		
		[[SessionManager dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		NSDictionary *results = JSON[@"results"];
		
		NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
		
		if (!_game) _game = [[Game alloc] initWithEntity:[NSEntityDescription entityForName:@"Game" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		
		[_game setIdentifier:@(identifier)];
		[_game setTitle:[Utilities stringFromSourceIfNotNull:results[@"name"]]];
		[_game setOverview:[Utilities stringFromSourceIfNotNull:results[@"deck"]]];
		[self requestImageWithURL:[NSURL URLWithString:[Utilities stringFromSourceIfNotNull:results[@"image"][@"super_url"]]]];
		
		// Release date
		NSString *originalReleaseDate = [Utilities stringFromSourceIfNotNull:results[@"original_release_date"]];
		NSInteger expectedReleaseDay = [Utilities integerNumberFromSourceIfNotNull:results[@"expected_release_day"]];
		NSInteger expectedReleaseMonth = [Utilities integerNumberFromSourceIfNotNull:results[@"expected_release_day"]];
		NSInteger expectedReleaseQuarter = [Utilities integerNumberFromSourceIfNotNull:results[@"expected_release_quarter"]];
		NSInteger expectedReleaseYear = [Utilities integerNumberFromSourceIfNotNull:results[@"expected_release_year"]];
		
		NSCalendar *calendar = [NSCalendar currentCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		
		if (originalReleaseDate){
			NSDateComponents *originalReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[[SessionManager dateFormatter] dateFromString:originalReleaseDate]];
			[originalReleaseDateComponents setQuarter:[self quarterForMonth:originalReleaseDateComponents.month]];
			
			NSDate *dateFromComponents = [calendar dateFromComponents:originalReleaseDateComponents];
			[_game setReleaseDate:dateFromComponents];
			[_game setReleaseDay:@(originalReleaseDateComponents.day)];
			[_game setReleaseMonth:@(originalReleaseDateComponents.month)];
			[_game setReleaseQuarter:@(originalReleaseDateComponents.quarter)];
			[_game setReleaseYear:@(originalReleaseDateComponents.year)];
			
			[[SessionManager dateFormatter] setDateFormat:@"dd MMM yyyy"];
			[_game setReleaseDateText:[[SessionManager dateFormatter] stringFromDate:dateFromComponents]];
		}
		else{
			NSDateComponents *expectedReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
			
			if (expectedReleaseDay){
				[expectedReleaseDateComponents setDay:expectedReleaseDay];
				[expectedReleaseDateComponents setMonth:expectedReleaseMonth];
				[expectedReleaseDateComponents setQuarter:[self quarterForMonth:expectedReleaseMonth]];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[SessionManager dateFormatter] setDateFormat:@"dd MMM yyyy"];
			}
			else if (expectedReleaseMonth){
				[expectedReleaseDateComponents setMonth:expectedReleaseMonth + 1];
				[expectedReleaseDateComponents setDay:0];
				[expectedReleaseDateComponents setQuarter:[self quarterForMonth:expectedReleaseMonth]];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[SessionManager dateFormatter] setDateFormat:@"MMMM yyyy"];
			}
			else if (expectedReleaseQuarter){
				[expectedReleaseDateComponents setQuarter:expectedReleaseQuarter];
				[expectedReleaseDateComponents setMonth:((expectedReleaseQuarter * 3) + 1)];
				[expectedReleaseDateComponents setDay:0];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[SessionManager dateFormatter] setDateFormat:@"QQQ yyyy"];
			}
			else if (expectedReleaseYear){
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[expectedReleaseDateComponents setQuarter:4];
				[expectedReleaseDateComponents setMonth:13];
				[expectedReleaseDateComponents setDay:0];
				[[SessionManager dateFormatter] setDateFormat:@"yyyy"];
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
			[_game setReleaseDateText:(expectedReleaseYear) ? [[SessionManager dateFormatter] stringFromDate:expectedReleaseDate] : @"TBA"];
		}
		
		[_game setReleasePeriod:[self releasePeriodForGame:_game]];
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self.tableView reloadData];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Error: %@", self, response.statusCode, error.description);
	}];
	[operation start];
}

- (void)requestImageWithURL:(NSURL *)URL{
	
}

- (void)requestMetascoreForGameWithTitle:(NSString *)title platform:(Platform *)platform{
	
}

#pragma mark - Custom

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
























































@end
