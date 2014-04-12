//
//  Networking.m
//  Gamer
//
//  Created by Caio Mello on 13/10/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "Networking.h"
#import "Genre.h"
#import "Game.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "Image.h"
#import "Video.h"
#import "ReleasePeriod.h"
#import "SimilarGame.h"
#import "Release.h"

@implementation Networking

static NSString *APIKEY = @"bb5b34c59426946bea05a8b0b2877789fb374d3c";
static NSString *BASEURL = @"http://api.giantbomb.com";
static AFURLSessionManager *MANAGER;
static NSMutableURLRequest *SEARCHREQUEST;

+ (AFURLSessionManager *)manager{
	if (!MANAGER){
		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		MANAGER = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
		[MANAGER.operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
	}
	return MANAGER;
}

+ (NSURLRequest *)requestForGamesWithTitle:(NSString *)title fields:(NSString *)fields platforms:(NSArray *)platforms{
	NSArray *identifiers = [platforms valueForKey:@"identifier"];
	NSMutableArray *platformIdentifiers = [[NSMutableArray alloc] initWithArray:identifiers];
	for (NSNumber *identifier in identifiers){
		switch (identifier.integerValue) {
			case 35: [platformIdentifiers addObject:@(88)]; break;
			case 129: [platformIdentifiers addObject:@(143)]; break;
			case 20: [platformIdentifiers addObject:@(86)]; break;
			case 117: [platformIdentifiers addObject:@(138)]; break;
			case 52: [platformIdentifiers addObject:@(106)]; break;
			case 18: [platformIdentifiers addObject:@(116)]; break;
			case 36: [platformIdentifiers addObject:@(87)]; break;
			default: break;
		}
	}
	NSString *platformsString = [platformIdentifiers componentsJoinedByString:@"|"];
	
	NSString *path = [NSString stringWithFormat:@"/games/3030/?api_key=%@&format=json&sort=date_added:desc&field_list=%@&filter=platforms:%@,name:%@", APIKEY, fields, platformsString, title];
	NSString *stringURL = [BASEURL stringByAppendingString:path];
	
	if (!SEARCHREQUEST) SEARCHREQUEST = [NSMutableURLRequest new];
	[SEARCHREQUEST setURL:[NSURL URLWithString:[stringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	return  SEARCHREQUEST;
}

+ (NSURLRequest *)requestForGameWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields{
	NSString *path = [NSString stringWithFormat:@"/game/3030-%@/?api_key=%@&format=json&field_list=%@", identifier, APIKEY, fields];
	NSString *stringURL = [BASEURL stringByAppendingString:path];
	return  [NSURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
}

+ (NSURLRequest *)requestForVideoWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields{
	NSString *path = [NSString stringWithFormat:@"/video/2300-%@/?api_key=%@&format=json&field_list=%@", identifier, APIKEY, fields];
	NSString *stringURL = [BASEURL stringByAppendingString:path];
	return [NSURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
}

+ (NSURLRequest *)requestForReleaseWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields{
	NSString *path = [NSString stringWithFormat:@"/release/3050-%@/?api_key=%@&format=json&field_list=%@", identifier, APIKEY, fields];
	NSString *stringURL = [BASEURL stringByAppendingString:path];
	return [NSURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
}

+ (void)updateGame:(Game *)game withDataFromJSON:(NSDictionary *)JSON context:(NSManagedObjectContext *)context{
//	NSLog(@"%@", JSON);
	
	if ([JSON[@"status_code"] isEqualToNumber:@(101)]) return;
	
	NSDictionary *results = JSON[@"results"];
	
	NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:results[@"id"]];
	
	// Main info
	[game setIdentifier:identifier];
	[game setTitle:[Tools stringFromSourceIfNotNull:results[@"name"]]];
	[game setOverview:[Tools stringFromSourceIfNotNull:results[@"deck"]]];
	
	// Platforms
	if (results[@"platforms"] != [NSNull null]){
		for (NSDictionary *dictionary in results[@"platforms"]){
			NSNumber *identifier = [Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]];
			switch (identifier.integerValue) {
				case 88: identifier = @(35); break;
				case 143: identifier = @(129); break;
				case 86: identifier = @(20); break;
				case 138: identifier = @(117); break;
				default: break;
			}
			Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:identifier inContext:context];
			if (platform) [game addPlatformsObject:platform];
		}
	}
	
	// Genres
	if (results[@"genres"] != [NSNull null]){
		for (NSDictionary *dictionary in results[@"genres"]){
			Genre *genre = [Genre MR_findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
			if (!genre) genre = [Genre MR_createInContext:context];
			[genre setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[genre setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			[game addGenresObject:genre];
		}
	}
	
	// Developers
	if (results[@"developers"] != [NSNull null]){
		for (NSDictionary *dictionary in results[@"developers"]){
			Developer *developer = [Developer MR_findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
			if (!developer) developer = [Developer MR_createInContext:context];
			[developer setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[developer setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			[game addDevelopersObject:developer];
		}
	}
	
	// Publishers
	if (results[@"publishers"] != [NSNull null]){
		for (NSDictionary *dictionary in results[@"publishers"]){
			Publisher *publisher = [Publisher MR_findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
			if (!publisher) publisher = [Publisher MR_createInContext:context];
			[publisher setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[publisher setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			[game addPublishersObject:publisher];
		}
	}
	
	// Franchises
	if (results[@"franchises"] != [NSNull null]){
		for (NSDictionary *dictionary in results[@"franchises"]){
			Franchise *franchise = [Franchise MR_findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
			if (!franchise) franchise = [Franchise MR_createInContext:context];
			[franchise setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[franchise setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			[game addFranchisesObject:franchise];
		}
	}
	
	// Similar games
	if (results[@"similar_games"] != [NSNull null]){
		for (NSDictionary *dictionary in results[@"similar_games"]){
			SimilarGame *similarGame = [SimilarGame MR_findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
			if (!similarGame) similarGame = [SimilarGame MR_createInContext:context];
			[similarGame setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[similarGame setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			[game addSimilarGamesObject:similarGame];
		}
	}
	
	// Themes
	if (results[@"themes"] != [NSNull null]){
		for (NSDictionary *dictionary in results[@"themes"]){
			Theme *theme = [Theme MR_findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
			if (!theme) theme = [Theme MR_createInContext:context];
			[theme setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[theme setName:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			[game addThemesObject:theme];
		}
	}
	
	// Releases
	if (results[@"releases"] != [NSNull null]){
		for (NSDictionary *dictionary in results[@"releases"]){
			Release *release = [Release MR_findFirstByAttribute:@"identifier" withValue:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]] inContext:context];
			if (!release) release = [Release MR_createInContext:context];
			[release setIdentifier:[Tools integerNumberFromSourceIfNotNull:dictionary[@"id"]]];
			[release setTitle:[Tools stringFromSourceIfNotNull:dictionary[@"name"]]];
			[game addReleasesObject:release];
		}
	}
	
	// Release date
	NSString *originalReleaseDate = [Tools stringFromSourceIfNotNull:results[@"original_release_date"]];
	NSInteger expectedReleaseDay = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_day"]].integerValue;
	NSInteger expectedReleaseMonth = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_month"]].integerValue;
	NSInteger expectedReleaseQuarter = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_quarter"]].integerValue;
	NSInteger expectedReleaseYear = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_year"]].integerValue;
	
	[self setReleaseDateForGameOrRelease:game dateString:originalReleaseDate expectedReleaseDay:expectedReleaseDay expectedReleaseMonth:expectedReleaseMonth expectedReleaseQuarter:expectedReleaseQuarter expectedReleaseYear:expectedReleaseYear];
	[game setReleasePeriod:[self releasePeriodForGameOrRelease:game context:context]];
}

+ (void)setReleaseDateForGameOrRelease:(id)object dateString:(NSString *)date expectedReleaseDay:(NSInteger)day expectedReleaseMonth:(NSInteger)month expectedReleaseQuarter:(NSInteger)quarter expectedReleaseYear:(NSInteger)year{
	// Workaround for API bug
	if ([date isEqualToString:@"2014-01-01 00:00:00"] && !day && !month && !quarter && !year){
		date = nil;
		year = 2014;
	}
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	if (date){
		[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		NSDateComponents *originalReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[[Tools dateFormatter] dateFromString:date]];
		[originalReleaseDateComponents setHour:10];
		[originalReleaseDateComponents setQuarter:[self quarterForMonth:originalReleaseDateComponents.month]];
		
		NSDate *releaseDateFromComponents = [calendar dateFromComponents:originalReleaseDateComponents];
		
		[object setReleaseDate:releaseDateFromComponents];
		[object setReleaseDay:@(originalReleaseDateComponents.day)];
		[object setReleaseMonth:@(originalReleaseDateComponents.month)];
		[object setReleaseQuarter:@(originalReleaseDateComponents.quarter)];
		[object setReleaseYear:@(originalReleaseDateComponents.year)];
		
		[[Tools dateFormatter] setDateFormat:@"d MMMM yyyy"];
		[object setReleaseDateText:[[Tools dateFormatter] stringFromDate:releaseDateFromComponents]];
		[object setReleased:@(YES)];
		
		[object setReleaseDateDefined:@(YES)];
	}
	else{
		NSDateComponents *expectedReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
		[expectedReleaseDateComponents setHour:10];
		
		BOOL defined = NO;
		
		// Exact release date is known
		if (day){
			[expectedReleaseDateComponents setDay:day];
			[expectedReleaseDateComponents setMonth:month];
			[expectedReleaseDateComponents setQuarter:[self quarterForMonth:month]];
			[expectedReleaseDateComponents setYear:year];
			[[Tools dateFormatter] setDateFormat:@"d MMMM yyyy"];
			defined = YES;
		}
		// Release month is known
		else if (month){
			[expectedReleaseDateComponents setMonth:month + 1];
			[expectedReleaseDateComponents setDay:0];
			[expectedReleaseDateComponents setQuarter:[self quarterForMonth:month]];
			[expectedReleaseDateComponents setYear:year];
			[[Tools dateFormatter] setDateFormat:@"MMMM yyyy"];
		}
		// Release quarter is known
		else if (quarter){
			[expectedReleaseDateComponents setQuarter:quarter];
			[expectedReleaseDateComponents setMonth:((quarter * 3) + 1)];
			[expectedReleaseDateComponents setDay:0];
			[expectedReleaseDateComponents setYear:year];
			[[Tools dateFormatter] setDateFormat:@"QQQ yyyy"];
		}
		// Release year is known
		else if (year){
			[expectedReleaseDateComponents setYear:year];
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
		
		[object setReleaseDate:expectedReleaseDateFromComponents];
		[object setReleaseDay:@(expectedReleaseDateComponents.day)];
		[object setReleaseMonth:@(expectedReleaseDateComponents.month)];
		[object setReleaseQuarter:@(expectedReleaseDateComponents.quarter)];
		[object setReleaseYear:@(expectedReleaseDateComponents.year)];
		
		[object setReleaseDateDefined:@(defined)];
		
		[object setReleaseDateText:(year) ? [[Tools dateFormatter] stringFromDate:expectedReleaseDateFromComponents] : @"TBA"];
		[object setReleased:@(NO)];
	}
}

//+ (NSURLRequest *)requestForMetascoreForGameWithTitle:(NSString *)title platform:(Platform *)platform{
//	NSMutableString *formattedTitle = title.lowercaseString.mutableCopy;
//	[formattedTitle setString:[formattedTitle stringByReplacingOccurrencesOfString:@"'" withString:@""]];
//	[formattedTitle setString:[formattedTitle stringByReplacingOccurrencesOfString:@":" withString:@""]];
//	[formattedTitle setString:[formattedTitle stringByReplacingOccurrencesOfString:@"& " withString:@""]];
//	[formattedTitle setString:[formattedTitle stringByReplacingOccurrencesOfString:@"/" withString:@"-"]];
//	[formattedTitle setString:[formattedTitle stringByReplacingOccurrencesOfString:@" " withString:@"-"]];
//	[formattedTitle setString:[formattedTitle stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale localeWithLocaleIdentifier:@"en_US"]]];
//	
//	NSMutableString *formattedPlatform = platform.name.lowercaseString.mutableCopy;
//	if ([platform.abbreviation isEqualToString:@"PSP"]){
//		[formattedPlatform setString:@"psp"];
//	}
//	else{
//		[formattedPlatform setString:[formattedPlatform stringByReplacingOccurrencesOfString:@"nintendo " withString:@""]];
//		[formattedPlatform setString:[formattedPlatform stringByReplacingOccurrencesOfString:@"'" withString:@""]];
//		[formattedPlatform setString:[formattedPlatform stringByReplacingOccurrencesOfString:@":" withString:@""]];
//		[formattedPlatform setString:[formattedPlatform stringByReplacingOccurrencesOfString:@" " withString:@"-"]];
//	}
//	
//	NSString *url = [NSString stringWithFormat:@"http://www.metacritic.com/game/%@/%@", formattedPlatform, formattedTitle];
//	
//	return [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//}

+ (NSInteger)quarterForMonth:(NSInteger)month{
	switch (month) {
		case 1: case 2: case 3: return 1;
		case 4: case 5: case 6: return 2;
		case 7: case 8: case 9: return 3;
		case 10: case 11: case 12: return 4;
		default: return 0;
	}
}

+ (ReleasePeriod *)releasePeriodForGameOrRelease:(id)object context:(NSManagedObjectContext *)context{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	NSDateComponents *threeMonthsAgo = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	[threeMonthsAgo setMonth:threeMonthsAgo.month - 3];
	
	// Components for today, this month, this quarter, this year
	NSDateComponents *current = [calendar components:NSDayCalendarUnit | NSWeekdayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	[current setQuarter:[self quarterForMonth:current.month]];
	[current setHour:10];
	
	// Components for the start of the week
	NSDateComponents *startOfCurrentWeek = [NSDateComponents new];
	[startOfCurrentWeek setDay:current.day - current.weekday + 1];
	
	// Components for the end of the week
	NSDateComponents *endOfCurrentWeek = [NSDateComponents new];
	[endOfCurrentWeek setDay:startOfCurrentWeek.day + 6];
	
	// Components for next month, next quarter, next year
	NSDateComponents *next = [calendar components:NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
	next.month++;
	[next setQuarter:current.quarter + 1];
	next.year++;
	
	NSInteger period = 0;
	if ([[object releaseDate] compare:[calendar dateFromComponents:threeMonthsAgo]] <= NSOrderedSame)
		period = 1; // Released
	else if ([[object releaseDate] compare:[calendar dateFromComponents:current]] <= NSOrderedSame)
		period = 2; // Recently released
	else{
		if ([object releaseYear].integerValue == 2050)
			period = 11; // TBA
		else if ([object releaseYear].integerValue > next.year)
			period = 10; // Later
		else if ([object releaseYear].integerValue == next.year){
			if (current.month == 12 && [object releaseMonth].integerValue == 1)
				period = 5; // Next month
			else if (current.quarter == 4 && [object releaseQuarter].integerValue == 1)
				period = 7; // Next quarter
			else
				period = 9; // Next year
		}
		else if ([object releaseYear].integerValue == current.year){
			if ([object releaseDay].integerValue >= startOfCurrentWeek.day && [object releaseDay].integerValue <= endOfCurrentWeek.day)
				period = 3;
			else if ([object releaseMonth].integerValue == current.month)
				period = 4; // This month
			else if ([object releaseMonth].integerValue == next.month)
				period = 5; // Next month
			else if ([object releaseQuarter].integerValue == current.quarter)
				period = 6; // This quarter
			else if ([object releaseQuarter].integerValue == next.quarter)
				period = 7; // Next quarter
			else
				period = 8; // This year
		}
	}
	
	return [ReleasePeriod MR_findFirstByAttribute:@"identifier" withValue:@(period) inContext:context];
}

//+ (NSString *)retrieveMetascoreFromHTML:(NSString *)HTML{
//	// Regex magic
//	NSRegularExpression *firstExpression = [NSRegularExpression regularExpressionWithPattern:@"xlarge game" options:NSRegularExpressionCaseInsensitive error:nil];
//	NSTextCheckingResult *firstResult = [firstExpression firstMatchInString:HTML options:NSMatchingReportProgress range:NSMakeRange(0, HTML.length)];
//	NSUInteger startIndex = firstResult.range.location + firstResult.range.length;
//	
//	NSRegularExpression *secondExpression = [NSRegularExpression regularExpressionWithPattern:@"</span" options:NSRegularExpressionCaseInsensitive error:nil];
//	NSTextCheckingResult *secondResult = [secondExpression firstMatchInString:HTML options:NSMatchingReportProgress range:NSMakeRange(startIndex, HTML.length - startIndex)];
//	NSUInteger endIndex = secondResult.range.location;
//	
////	NSString *metascore = [html substringWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
//	NSString *metascore = (startIndex >= 2 && endIndex >= 2) ? [HTML substringWithRange:NSMakeRange(endIndex - 2, 2)] : nil;
//	
////	NSLog(@"HTML: %@", HTML);
////	NSLog(@"Metascore: %@", metascore);
//	
//	return metascore;
//}

+ (UIColor *)colorForMetascore:(NSString *)metascore{
	if (metascore.integerValue >= 75)
		return [UIColor colorWithRed:.384313725 green:.807843137 blue:.129411765 alpha:1];
	else if (metascore.integerValue >= 50)
		return [UIColor colorWithRed:1 green:.803921569 blue:.058823529 alpha:1];
	else
		return [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
}

@end
