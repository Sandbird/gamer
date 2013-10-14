//
//  Networking.m
//  Gamer
//
//  Created by Caio Mello on 13/10/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "Networking.h"
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

@implementation Networking

static NSString *APIKEY = @"bb5b34c59426946bea05a8b0b2877789fb374d3c";
static NSMutableURLRequest *SEARCHREQUEST;

+ (NSMutableURLRequest *)requestForGamesWithTitle:(NSString *)title fields:(NSString *)fields platforms:(NSArray *)platforms{
	NSArray *identifiers = [platforms valueForKey:@"identifier"];
	NSMutableArray *platformIdentifiers = [[NSMutableArray alloc] initWithArray:identifiers];
	for (NSNumber *identifier in identifiers){
		switch (identifier.integerValue) {
			case 35: [platformIdentifiers addObject:@(88)]; break;
			case 129: [platformIdentifiers addObject:@(143)]; break;
			case 20: [platformIdentifiers addObject:@(86)]; break;
			default: break;
		}
	}
	NSString *platformsString = [platformIdentifiers componentsJoinedByString:@"|"];
	
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/games/3030/?api_key=%@&format=json&sort=date_added:desc&field_list=%@&filter=platforms:%@,name:%@", APIKEY, fields, platformsString, title];
	
	if (!SEARCHREQUEST) SEARCHREQUEST = [[NSMutableURLRequest alloc] init];
	[SEARCHREQUEST setHTTPMethod:@"GET"];
	[SEARCHREQUEST setURL:[NSURL URLWithString:[stringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	return  SEARCHREQUEST;
}

+ (NSMutableURLRequest *)requestForGameWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields{
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/game/3030-%@/?api_key=%@&format=json&field_list=%@", identifier, APIKEY, fields];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
	[request setHTTPMethod:@"GET"];
	
	return  request;
}

+ (NSMutableURLRequest *)requestForVideoWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields{
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/video/2300-%@/?api_key=%@&format=json&field_list=%@", identifier, APIKEY, fields];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
	[request setHTTPMethod:@"GET"];
	
	return request;
}

+ (void)updateGame:(Game *)game withDataFromJSON:(NSDictionary *)JSON context:(NSManagedObjectContext *)context{
	[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
	
	NSDictionary *results = JSON[@"results"];
	
	NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:results[@"id"]];
	
	// Main info
	[game setIdentifier:identifier];
	[game setTitle:[Tools stringFromSourceIfNotNull:results[@"name"]]];
	[game setOverview:[Tools stringFromSourceIfNotNull:results[@"deck"]]];
	
	// Cover image
	if (results[@"image"] != [NSNull null]){
		NSString *imageURL = [Tools stringFromSourceIfNotNull:results[@"image"][@"super_url"]];
		
		CoverImage *coverImage = [CoverImage findFirstByAttribute:@"url" withValue:imageURL];
		if (!coverImage){
			coverImage = [CoverImage createInContext:context];
			[coverImage setUrl:imageURL];
		}
		[game setCoverImage:coverImage];
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
		if (!releaseDate) releaseDate = [ReleaseDate createInContext:context];
		[releaseDate setDate:releaseDateFromComponents];
		[releaseDate setDay:@(originalReleaseDateComponents.day)];
		[releaseDate setMonth:@(originalReleaseDateComponents.month)];
		[releaseDate setQuarter:@(originalReleaseDateComponents.quarter)];
		[releaseDate setYear:@(originalReleaseDateComponents.year)];
		
		[[Tools dateFormatter] setDateFormat:@"d MMMM yyyy"];
		[game setReleaseDateText:[[Tools dateFormatter] stringFromDate:releaseDateFromComponents]];
		[game setReleased:@(YES)];
		
		[game setReleaseDate:releaseDate];
		[game.releaseDate setDefined:@(YES)];
		[game setReleasePeriod:[self releasePeriodForReleaseDate:releaseDate]];
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
		if (!releaseDate) releaseDate = [ReleaseDate createInContext:context];
		[releaseDate setDate:expectedReleaseDateFromComponents];
		[releaseDate setDay:@(expectedReleaseDateComponents.day)];
		[releaseDate setMonth:@(expectedReleaseDateComponents.month)];
		[releaseDate setQuarter:@(expectedReleaseDateComponents.quarter)];
		[releaseDate setYear:@(expectedReleaseDateComponents.year)];
		
		[releaseDate setDefined:@(defined)];
		
		[game setReleaseDateText:(expectedReleaseYear) ? [[Tools dateFormatter] stringFromDate:expectedReleaseDateFromComponents] : @"TBA"];
		[game setReleased:@(NO)];
		
		[game setReleaseDate:releaseDate];
		[game setReleasePeriod:[self releasePeriodForReleaseDate:releaseDate]];
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
			Platform *platform = [Platform findFirstByAttribute:@"identifier" withValue:identifier inContext:context];
			if (platform) [game addPlatformsObject:platform];
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
			[game addGenresObject:genre];
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
			[game addDevelopersObject:developer];
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
			[game addPublishersObject:publisher];
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
			[game addFranchisesObject:franchise];
		}
	}
	
	// Similar games
	if (results[@"similar_games"] != [NSNull null]){
		for (NSDictionary *dictionary in results[@"similar_games"]){
			SimilarGame *similarGame = [SimilarGame findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
			if (similarGame)
				[similarGame setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			else{
				similarGame = [SimilarGame createInContext:context];
				[similarGame setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
				[similarGame setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			}
			[game addSimilarGamesObject:similarGame];
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
			[game addThemesObject:theme];
		}
	}
}

+ (NSInteger)quarterForMonth:(NSInteger)month{
	switch (month) {
		case 1: case 2: case 3: return 1;
		case 4: case 5: case 6: return 2;
		case 7: case 8: case 9: return 3;
		case 10: case 11: case 12: return 4;
		default: return 0;
	}
}

+ (ReleasePeriod *)releasePeriodForReleaseDate:(ReleaseDate *)releaseDate{
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

@end