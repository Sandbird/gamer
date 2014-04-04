//
//  SessionManager.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "Session.h"
#import "ReleaseDate.h"
#import "Platform.h"
#import "ReleasePeriod.h"
#import "Region.h"

@implementation Session

static NSMutableURLRequest *SEARCHREQUEST;
static Gamer *GAMER;
static NSString *SEARCHQUERY;
static NSArray *SEARCHRESULTS;

+ (void)setGamer:(Gamer *)gamer{
	GAMER = gamer;
}

+ (Gamer *)gamer{
	return GAMER;
}

+ (NSString *)searchQuery{
	return SEARCHQUERY;
}

+ (void)setSearchQuery:(NSString *)query{
	SEARCHQUERY = query;
}

+ (NSArray *)searchResults{
	return SEARCHRESULTS;
}

+ (void)setSearchResults:(NSArray *)results{
	SEARCHRESULTS = results;
}

+ (CGSize)optimalCoverImageSizeForImage:(UIImage *)image type:(GameImageType)type{
	if ([Tools deviceIsiPhone]){
		if (image.size.width > image.size.height){
			switch (type) {
				case GameImageTypeCover: return [Tools sizeOfImage:image aspectFitToWidth:OptimalImageWidthiPhoneCover];
				case GameImageTypeWishlist: return [Tools sizeOfImage:image aspectFitToWidth:OptimalImageWidthiPhoneWishlist];
				case GameImageTypeLibrary: return [Tools sizeOfImage:image aspectFitToWidth:OptimalImageWidthiPhoneLibrary];
				default: break;
			}
		}
		else{
			switch (type) {
				case GameImageTypeCover: return [Tools sizeOfImage:image aspectFitToHeight:OptimalImageHeightiPhoneCover];
				case GameImageTypeWishlist: return [Tools sizeOfImage:image aspectFitToHeight:OptimalImageHeightiPhoneWishlist];
				case GameImageTypeLibrary: return [Tools sizeOfImage:image aspectFitToHeight:OptimalImageHeightiPhoneLibrary];
				default: break;
			}
		}
	}
	else{
		if (image.size.width > image.size.height){
			switch (type) {
				case GameImageTypeCover: return [Tools sizeOfImage:image aspectFitToWidth:OptimalImageWidthiPadCover];
				case GameImageTypeWishlist: return [Tools sizeOfImage:image aspectFitToWidth:OptimalImageWidthiPadWishlist];
				case GameImageTypeLibrary: return [Tools sizeOfImage:image aspectFitToWidth:OptimalImageWidthiPadLibrary];
				default: break;
			}
		}
		else{
			switch (type) {
				case GameImageTypeCover: return [Tools sizeOfImage:image aspectFitToHeight:OptimalImageHeightiPadCover];
				case GameImageTypeWishlist: return [Tools sizeOfImage:image aspectFitToHeight:OptimalImageHeightiPadWishlist];
				case GameImageTypeLibrary: return [Tools sizeOfImage:image aspectFitToHeight:OptimalImageHeightiPadLibrary];
				default: break;
			}
		}
	}
}

+ (UIImage *)aspectFitImageWithImage:(UIImage *)image type:(GameImageType)type{
	if ([Tools deviceIsiPhone]){
		if (image.size.width > image.size.height){
			switch (type) {
				case GameImageTypeCover: return [Tools imageWithImage:image scaledToWidth:OptimalImageWidthiPhoneCover];
				case GameImageTypeWishlist: return [Tools imageWithImage:image scaledToWidth:OptimalImageWidthiPhoneWishlist];
				case GameImageTypeLibrary: return [Tools imageWithImage:image scaledToWidth:OptimalImageWidthiPhoneLibrary];
				default: break;
			}
		}
		else{
			switch (type) {
				case GameImageTypeCover: return [Tools imageWithImage:image scaledToHeight:OptimalImageHeightiPhoneCover];
				case GameImageTypeWishlist: return [Tools imageWithImage:image scaledToHeight:OptimalImageHeightiPhoneWishlist];
				case GameImageTypeLibrary: return [Tools imageWithImage:image scaledToHeight:OptimalImageHeightiPhoneLibrary];
				default: break;
			}
		}
	}
	else{
		if (image.size.width > image.size.height){
			switch (type) {
				case GameImageTypeCover: return [Tools imageWithImage:image scaledToWidth:OptimalImageWidthiPadCover];
				case GameImageTypeWishlist: return [Tools imageWithImage:image scaledToWidth:OptimalImageWidthiPadWishlist];
				case GameImageTypeLibrary: return [Tools imageWithImage:image scaledToWidth:OptimalImageWidthiPadLibrary];
				default: break;
			}
		}
		else{
			switch (type) {
				case GameImageTypeCover: return [Tools imageWithImage:image scaledToHeight:OptimalImageHeightiPadCover];
				case GameImageTypeWishlist: return [Tools imageWithImage:image scaledToHeight:OptimalImageHeightiPadWishlist];
				case GameImageTypeLibrary: return [Tools imageWithImage:image scaledToHeight:OptimalImageHeightiPadLibrary];
				default: break;
			}
		}
	}
}

+ (void)stp{
	NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	Gamer *gamer = [Gamer MR_findFirstInContext:context];
	if (!gamer) gamer = [Gamer MR_createInContext:context];
	[self setGamer:gamer];
	
	if (!gamer.librarySize) [gamer setLibrarySize:@(LibrarySizeMedium)];
	
	NSDictionary *initialDataDictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"InitialData" ofType:@"plist"]];
	NSLog(@"%@", initialDataDictionary);
	
//	NSArray *platforms = [Platform MR_findAllSortedBy:@"index" ascending:YES inContext:context];
//	NSArray *releasePeriods = [ReleasePeriod MR_findAllSortedBy:@"identifier" ascending:YES inContext:context];
//	NSArray *placeholderGames = [Game MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"identifier == nil"] inContext:context];
//	NSArray *regions = [Region MR_findAllSortedBy:@"identifier" ascending:YES inContext:context];
	
	for (NSDictionary *platformDictionary in initialDataDictionary[@"initial_data"][@"platforms"]){
		Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:platformDictionary[@"platform"][@"identifier"] inContext:context];
		if (!platform) platform = [Platform MR_createInContext:context];
		[platform setIdentifier:platformDictionary[@"platform"][@"identifier"]];
		[platform setName:platformDictionary[@"platform"][@"name"]];
		[platform setAbbreviation:platformDictionary[@"platform"][@"abbreviation"]];
		[platform setIndex:platformDictionary[@"platform"][@"index"]];
		[platform setGroup:platformDictionary[@"platform"][@"group"]];
		[platform setMetacriticIdentifier:platformDictionary[@"platform"][@"metacritic_identifier"]];
		[platform setColor:[UIColor colorWithRed:[Tools decimalNumberFromSourceIfNotNull:platformDictionary[@"platform"][@"color"][@"red"]].floatValue
										   green:[Tools decimalNumberFromSourceIfNotNull:platformDictionary[@"platform"][@"color"][@"green"]].floatValue
											blue:[Tools decimalNumberFromSourceIfNotNull:platformDictionary[@"platform"][@"color"][@"blue"]].floatValue
										   alpha:1]];
	}
	
	
	
	[context MR_saveToPersistentStoreAndWait];
}

+ (void)setup{
	// Initial data
	NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	// (AKA the user)
	Gamer *gamer = [Gamer MR_findFirstInContext:context];
	
	if (gamer){
		GAMER = gamer;
		
		if (!gamer.librarySize) [gamer setLibrarySize:@(1)];
		
		if ([Platform MR_countOfEntities] < 11){
			NSArray *identifiers = @[@(52), @(18), @(36)];
			
			NSArray *names = @[@"Nintendo DS",
							   @"PlayStation Portable",
							   @"Wii"];
			
			NSArray *abbreviations = @[@"DS",
									   @"PSP",
									   @"WII"];
			
			NSArray *colors = @[[UIColor colorWithRed:.666666667 green:.31372549 blue:.31372549 alpha:1],
								[UIColor colorWithRed:.235294118 green:.235294118 blue:.549019608 alpha:1],
								[UIColor colorWithRed:.352941176 green:.784313725 blue:.941176471 alpha:1]];
			
			for (NSInteger index = 0; index < identifiers.count; index++){
				Platform *platform = [Platform MR_createInContext:context];
				[platform setIdentifier:identifiers[index]];
				[platform setName:names[index]];
				[platform setAbbreviation:abbreviations[index]];
				[platform setColor:colors[index]];
				[platform setIndex:@(8 + index)];
			}
		}
		
		if ([ReleasePeriod MR_countOfEntities] < 10){
			NSArray *releasePeriods = [ReleasePeriod MR_findAllSortedBy:@"identifier" ascending:YES inContext:context];
			for (ReleasePeriod *releasePeriod in releasePeriods){
				if (releasePeriod.identifier.integerValue > 1){
					[releasePeriod setIdentifier:@(releasePeriod.identifier.integerValue + 1)];
				}
			}
			
			NSCalendar *calendar = [NSCalendar currentCalendar];
			[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			NSDateComponents *components = [calendar components:NSYearCalendarUnit fromDate:[NSDate date]];
			[components setYear:2060];
			
			ReleaseDate *releaseDate = [ReleaseDate MR_findFirstByAttribute:@"date" withValue:[calendar dateFromComponents:components] inContext:context];
			
			ReleasePeriod *releasePeriod = [ReleasePeriod MR_createInContext:context];
			[releasePeriod setIdentifier:@(2)];
			[releasePeriod setName:@"Recently Released"];
			
			Game *placeholderGame = [Game MR_createInContext:context];
			[placeholderGame setTitle:@"ZZZ"];
			[placeholderGame setReleasePeriod:releasePeriod];
			[placeholderGame setReleaseDate:releaseDate];
			[placeholderGame setHidden:@(YES)];
			
			[releasePeriod setPlaceholderGame:placeholderGame];
		}
		
		[context MR_saveToPersistentStoreAndWait];
	}
	else {
		// New user
		gamer = [Gamer MR_createInContext:context];
		GAMER = gamer;
		
		// Release periods
		NSCalendar *calendar = [NSCalendar currentCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		NSDateComponents *components = [calendar components:NSYearCalendarUnit fromDate:[NSDate date]];
		[components setYear:2060];
		
		ReleaseDate *releaseDate = [ReleaseDate MR_createInContext:context];
		[releaseDate setDate:[calendar dateFromComponents:components]];
		
		NSArray *periods = @[@"Released", @"Recently Released", @"This Month", @"Next Month", @"This Quarter", @"Next Quarter", @"This Year", @"Next Year", @"Later", @"To Be Announced"];
		for (NSInteger period = 1; period <= periods.count; period++){
			ReleasePeriod *releasePeriod = [ReleasePeriod MR_createInContext:context];
			[releasePeriod setIdentifier:@(period)];
			[releasePeriod setName:periods[period - 1]];
			
			Game *placeholderGame = [Game MR_createInContext:context];
			[placeholderGame setTitle:@"ZZZ"];
			[placeholderGame setReleasePeriod:releasePeriod];
			[placeholderGame setReleaseDate:releaseDate];
			[placeholderGame setHidden:@(YES)];
			
			[releasePeriod setPlaceholderGame:placeholderGame];
		}
		
		[context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			// Platforms
			NSArray *identifiers = @[@(117),
									 @(52),
									 @(94),
									 @(35),
									 @(146),
									 @(18),
									 @(129),
									 @(36),
									 @(139),
									 @(20),
									 @(145)];
			
			NSArray *names = @[@"Nintendo 3DS",
							   @"Nintendo DS",
							   @"PC",
							   @"PlayStation 3",
							   @"PlayStation 4",
							   @"PlayStation Portable",
							   @"PlayStation Vita",
							   @"Wii",
							   @"Wii U",
							   @"Xbox 360",
							   @"Xbox One"];
			
			NSArray *abbreviations = @[@"3DS",
									   @"DS",
									   @"PC",
									   @"PS3",
									   @"PS4",
									   @"PSP",
									   @"VITA",
									   @"WII",
									   @"WIIU",
									   @"X360",
									   @"XONE"];
			
			NSArray *colors = @[[UIColor colorWithRed:.764705882 green:0 blue:.058823529 alpha:1],
								[UIColor colorWithRed:.666666667 green:.31372549 blue:.31372549 alpha:1],
								[UIColor colorWithRed:0 green:0 blue:0 alpha:1],
								[UIColor colorWithRed:0 green:.039215686 blue:.525490196 alpha:1],
								[UIColor colorWithRed:.039215686 green:.254901961 blue:.588235294 alpha:1],
								[UIColor colorWithRed:.235294118 green:.235294118 blue:.549019608 alpha:1],
								[UIColor colorWithRed:0 green:.235294118 blue:.592156863 alpha:1],
								[UIColor colorWithRed:.352941176 green:.784313725 blue:.941176471 alpha:1],
								[UIColor colorWithRed:0 green:.521568627 blue:.749019608 alpha:1],
								[UIColor colorWithRed:.501960784 green:.760784314 blue:.145098039 alpha:1],
								[UIColor colorWithRed:.058823529 green:.42745098 blue:0 alpha:1]];
			
			for (NSInteger index = 0; index < identifiers.count; index++){
				Platform *platform = [Platform MR_createInContext:context];
				[platform setIdentifier:identifiers[index]];
				[platform setName:names[index]];
				[platform setAbbreviation:abbreviations[index]];
				[platform setColor:colors[index]];
				[platform setIndex:@(index)];
			}
			
			[context MR_saveToPersistentStoreAndWait];
		}];
	}
}

@end
