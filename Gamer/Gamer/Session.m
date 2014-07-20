//
//  SessionManager.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
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

+ (CGSize)coverImageSize{
	return [Tools deviceIsiPhone] ? CGSizeMake(280, 200) : CGSizeMake(420, 300);
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
		[platform setMetacriticIdentifier:platformDictionary[@"platform"][@"metacritic_identifier"]];
		
		if (!platform.group)
			[platform setIndex:platformDictionary[@"platform"][@"index"]];
		
		[platform setGroup:platformDictionary[@"platform"][@"group"]];
		
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
