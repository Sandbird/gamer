//
//  SessionManager.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SessionManager.h"
#import "ReleaseDate.h"
#import "Platform.h"
#import "ReleasePeriod.h"

@implementation SessionManager

static NSMutableURLRequest *SEARCHREQUEST;
static Gamer *GAMER;

+ (void)setGamer:(Gamer *)gamer{
	GAMER = gamer;
}

+ (Gamer *)gamer{
	return GAMER;
}

+ (id<GAITracker>)tracker{
	return [GAI sharedInstance].defaultTracker;
}

+ (CGSize)optimalCoverImageSizeForImage:(UIImage *)image{
	if ([Tools deviceIsiPhone]){
		if (image.size.width > image.size.height)
			return [Tools sizeOfImage:image aspectFitToWidth:OptimalImageWidthiPhoneCover];
		else
			return [Tools sizeOfImage:image aspectFitToHeight:OptimalImageHeightiPhoneCover];
	}
	else{
		if (image.size.width > image.size.height)
			return [Tools sizeOfImage:image aspectFitToWidth:OptimalImageWidthiPadCover];
		else
			return [Tools sizeOfImage:image aspectFitToHeight:OptimalImageHeightiPadCover];
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

+ (void)setup{
	// Initial data
	NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
	
	// (AKA the user)
	Gamer *gamer = [Gamer findFirst];
	
	if (gamer){
		GAMER = gamer;
		
		if (!gamer.librarySize) [gamer setLibrarySize:@(1)];
		[context saveToPersistentStoreAndWait];
	}
	else {
		// New user
		gamer = [Gamer createInContext:context];
		GAMER = gamer;
		
		// Release periods
		NSCalendar *calendar = [NSCalendar currentCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		NSDateComponents *components = [calendar components:NSYearCalendarUnit fromDate:[NSDate date]];
		[components setYear:2060];
		
		ReleaseDate *releaseDate = [ReleaseDate createInContext:context];
		[releaseDate setDate:[calendar dateFromComponents:components]];
		
		NSArray *periods = @[@"Released", @"This Month", @"Next Month", @"This Quarter", @"Next Quarter", @"This Year", @"Next Year", @"Later", @"To Be Announced"];
		for (NSInteger period = 1; period <= periods.count; period++){
			ReleasePeriod *releasePeriod = [ReleasePeriod createInContext:context];
			[releasePeriod setIdentifier:@(period)];
			[releasePeriod setName:periods[period - 1]];
			
			Game *placeholderGame = [Game createInContext:context];
			[placeholderGame setTitle:@"ZZZ"];
			[placeholderGame setReleasePeriod:releasePeriod];
			[placeholderGame setReleaseDate:releaseDate];
			[placeholderGame setHidden:@(YES)];
			
			[releasePeriod setPlaceholderGame:placeholderGame];
		}
		
		[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			// Platforms
			NSArray *identifiers = @[@(117), @(94), @(35), @(146), @(129), @(139), @(20), @(145)];
			NSArray *names = @[@"Nintendo 3DS",
							   @"PC",
							   @"PlayStation 3",
							   @"PlayStation 4",
							   @"PlayStation Vita",
							   @"Wii U",
							   @"Xbox 360",
							   @"Xbox One"];
			NSArray *abbreviations = @[@"3DS",
									   @"PC",
									   @"PS3",
									   @"PS4",
									   @"VITA",
									   @"WIIU",
									   @"X360",
									   @"XONE"];
			NSArray *colors = @[[UIColor colorWithRed:.764705882 green:0 blue:.058823529 alpha:1],
								[UIColor colorWithRed:0 green:0 blue:0 alpha:1],
								[UIColor colorWithRed:0 green:.039215686 blue:.525490196 alpha:1],
								[UIColor colorWithRed:.039215686 green:.254901961 blue:.588235294 alpha:1],
								[UIColor colorWithRed:0 green:.235294118 blue:.592156863 alpha:1],
								[UIColor colorWithRed:0 green:.521568627 blue:.749019608 alpha:1],
								[UIColor colorWithRed:.501960784 green:.760784314 blue:.145098039 alpha:1],
								[UIColor colorWithRed:.058823529 green:.42745098 blue:0 alpha:1]];
			
			for (NSInteger index = 0; index < identifiers.count; index++){
				Platform *platform = [Platform createInContext:context];
				[platform setIdentifier:identifiers[index]];
				[platform setName:names[index]];
				[platform setAbbreviation:abbreviations[index]];
				[platform setColor:colors[index]];
				[platform setIndex:@(index)];
			}
			
			[context saveToPersistentStoreAndWait];
		}];
	}
}

@end
