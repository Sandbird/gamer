//
//  SessionManager.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SessionManager.h"

@implementation SessionManager

static NSString *APIKEY = @"d92c258adb509ded409d28f4e51de2c83e297011";
static NSMutableURLRequest *REQUEST;
static EKEventStore *EVENTSTORE;
static Gamer *GAMER;

+ (void)setGamer:(Gamer *)gamer{
	GAMER = gamer;
}

+ (Gamer *)gamer{
	return GAMER;
}

+ (void)setEventStore:(EKEventStore *)eventStore{
	EVENTSTORE = eventStore;
}

+ (EKEventStore *)eventStore{
	return EVENTSTORE;
}

+ (BOOL)calendarEnabled{
	__block BOOL accessGranted = NO;
	
	if([EVENTSTORE respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
		[EVENTSTORE requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
			accessGranted = granted;
			dispatch_semaphore_signal(semaphore);
		}];
		dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	}
	else
		accessGranted = YES;
	
	if (accessGranted && !GAMER.calendarIdentifier){
		EKCalendar *calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:EVENTSTORE];
		[calendar setTitle:@"Game Releases"];
		[calendar setCGColor:[UIColor orangeColor].CGColor];
		EKSource *source = nil;
		for (EKSource *storeSource in EVENTSTORE.sources){
			if (storeSource.sourceType == EKSourceTypeCalDAV && [storeSource.title isEqualToString:@"iCloud"]){
				source = storeSource;
				break;
			}
		}
		if (!source){
			for (EKSource *storeSource in EVENTSTORE.sources){
				if (storeSource.sourceType == EKSourceTypeLocal){
					source = storeSource;
					break;
				}
			}
		}
		[calendar setSource:source];
		
		NSError *error;
		[EVENTSTORE saveCalendar:calendar commit:YES error:&error];
		
		[GAMER setCalendarIdentifier:calendar.calendarIdentifier];
		[[NSManagedObjectContext contextForCurrentThread] saveToPersistentStoreAndWait];
	}
	
	return accessGranted;
}

+ (id<GAITracker>)tracker{
	return [GAI sharedInstance].defaultTracker;
}

+ (NSMutableURLRequest *)URLRequestForGamesWithFields:(NSString *)fields platforms:(NSArray *)platforms title:(NSString *)title{
	NSString *platformIdentifiers = [[platforms valueForKey:@"identifier"] componentsJoinedByString:@"|"];
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/games/3030/?api_key=%@&format=json&sort=date_added:desc&field_list=%@&filter=platforms:%@,name:%@", APIKEY, fields, platformIdentifiers, title];
	
	if (!REQUEST) REQUEST = [[NSMutableURLRequest alloc] init];
	[REQUEST setHTTPMethod:@"GET"];
	[REQUEST setURL:[NSURL URLWithString:[stringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	return  REQUEST;
}

+ (NSMutableURLRequest *)URLRequestForGameWithFields:(NSString *)fields identifier:(NSNumber *)identifier{
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/game/3030-%@/?api_key=%@&format=json&field_list=%@", identifier, APIKEY, fields];
	
	if (!REQUEST) REQUEST = [[NSMutableURLRequest alloc] init];
	[REQUEST setHTTPMethod:@"GET"];
	[REQUEST setURL:[NSURL URLWithString:stringURL]];
	
	return  REQUEST;
}

+ (NSMutableURLRequest *)URLRequestForVideoWithFields:(NSString *)fields identifier:(NSNumber *)identifier{
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/video/2300-%@/?api_key=%@&format=json&field_list=%@", identifier, APIKEY, fields];
	
//	if (!REQUEST) REQUEST = [[NSMutableURLRequest alloc] init];
//	[REQUEST setHTTPMethod:@"GET"];
//	[REQUEST setURL:[NSURL URLWithString:stringURL]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
	[request setHTTPMethod:@"GET"];
	
	return request;
}

@end
