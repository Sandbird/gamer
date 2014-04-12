//
//  SessionManager.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "Session.h"
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

+ (void)setupInitialData{
	NSString *imagesDirectoryPath = [Tools imagesDirectory];
	if (![[NSFileManager defaultManager] fileExistsAtPath:imagesDirectoryPath]){
		[[NSFileManager defaultManager] createDirectoryAtPath:imagesDirectoryPath withIntermediateDirectories:NO attributes:nil error:nil];
		[Tools addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:imagesDirectoryPath isDirectory:YES]];
	}
	
	NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	Gamer *gamer = [Gamer MR_findFirstInContext:context];
	if (!gamer) gamer = [Gamer MR_createInContext:context];
	[self setGamer:gamer];
	
	if (!gamer.librarySize) [gamer setLibrarySize:@(LibrarySizeMedium)];
	
	NSDictionary *initialDataDictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"InitialData" ofType:@"plist"]];
//	NSLog(@"%@", initialDataDictionary);
	
	for (NSDictionary *platformDictionary in initialDataDictionary[@"initial_data"][@"platforms"]){
		Platform *platform = [Platform MR_findFirstByAttribute:@"identifier" withValue:platformDictionary[@"platform"][@"identifier"] inContext:context];
		if (!platform) platform = [Platform MR_createInContext:context];
		[platform setIdentifier:platformDictionary[@"platform"][@"identifier"]];
		[platform setName:platformDictionary[@"platform"][@"name"]];
		[platform setAbbreviation:platformDictionary[@"platform"][@"abbreviation"]];
		[platform setIndex:platformDictionary[@"platform"][@"index"]];
		[platform setMetacriticIdentifier:platformDictionary[@"platform"][@"metacritic_identifier"]];
		[platform setColor:[UIColor colorWithRed:[Tools decimalNumberFromSourceIfNotNull:platformDictionary[@"platform"][@"color"][@"red"]].floatValue
										   green:[Tools decimalNumberFromSourceIfNotNull:platformDictionary[@"platform"][@"color"][@"green"]].floatValue
											blue:[Tools decimalNumberFromSourceIfNotNull:platformDictionary[@"platform"][@"color"][@"blue"]].floatValue
										   alpha:1]];
	}
	
	for (NSDictionary *releasePeriodDictionary in initialDataDictionary[@"initial_data"][@"release_periods"]){
		ReleasePeriod *releasePeriod = [ReleasePeriod MR_findFirstByAttribute:@"identifier" withValue:releasePeriodDictionary[@"release_period"][@"identifier"] inContext:context];
		if (!releasePeriod) releasePeriod = [ReleasePeriod MR_createInContext:context];
		[releasePeriod setIdentifier:releasePeriodDictionary[@"release_period"][@"identifier"]];
		[releasePeriod setName:releasePeriodDictionary[@"release_period"][@"name"]];
		
		Game *placeholderGame = releasePeriod.placeholderGame;
		if (!placeholderGame) placeholderGame = [Game MR_createInContext:context];
		[placeholderGame setTitle:releasePeriodDictionary[@"release_period"][@"placeholder"][@"title"]];
		[placeholderGame setHidden:releasePeriodDictionary[@"release_period"][@"placeholder"][@"hidden"]];
		[placeholderGame setReleaseDate:releasePeriodDictionary[@"release_period"][@"placeholder"][@"release_date"]];
		[placeholderGame setLocation:@(GameLocationWishlist)];
		[placeholderGame setReleasePeriod:releasePeriod];
		
		[releasePeriod setPlaceholderGame:placeholderGame];
	}
	
	for (NSDictionary *regionDictionary in initialDataDictionary[@"initial_data"][@"regions"]){
		Region *region = [Region MR_findFirstByAttribute:@"identifier" withValue:regionDictionary[@"region"][@"identifier"] inContext:context];
		if (!region) region = [Region MR_createInContext:context];
		[region setIdentifier:regionDictionary[@"region"][@"identifier"]];
		[region setName:regionDictionary[@"region"][@"name"]];
		[region setAbbreviation:regionDictionary[@"region"][@"abbreviation"]];
		[region setImageName:regionDictionary[@"region"][@"image_name"]];
	}
	
	[context MR_saveToPersistentStoreAndWait];
}

@end
