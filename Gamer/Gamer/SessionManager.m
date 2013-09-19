//
//  SessionManager.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SessionManager.h"

@implementation SessionManager

static NSString *APIKEY = @"bb5b34c59426946bea05a8b0b2877789fb374d3c";
static NSMutableURLRequest *SEARCHREQUEST;
//static EKEventStore *EVENTSTORE;
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

//+ (void)setEventStore:(EKEventStore *)eventStore{
//	EVENTSTORE = eventStore;
//}

//+ (EKEventStore *)eventStore{
//	return EVENTSTORE;
//}

//+ (BOOL)calendarEnabled{
//	__block BOOL accessGranted = NO;
//	
//	// If calendar access has not been requested, do it
//	if([EVENTSTORE respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
//		dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//		[EVENTSTORE requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
//			accessGranted = granted;
//			dispatch_semaphore_signal(semaphore);
//		}];
//		dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//	}
//	else
//		accessGranted = YES;
//	
//	if (accessGranted){
//		// Check sources for iCloud
//		EKSource *source = nil;
//		for (EKSource *storeSource in EVENTSTORE.sources){
//			if (storeSource.sourceType == EKSourceTypeCalDAV && [storeSource.title isEqualToString:@"iCloud"]){
//				source = storeSource;
//				break;
//			}
//		}
//		// If iCloud disabled, use local store
//		if (!source){
//			for (EKSource *storeSource in EVENTSTORE.sources){
//				if (storeSource.sourceType == EKSourceTypeLocal){
//					source = storeSource;
//					break;
//				}
//			}
//		}
//		
//		EKCalendar *calendar = [EVENTSTORE calendarWithIdentifier:GAMER.calendarIdentifier];
//		if (!calendar) calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:EVENTSTORE];
//		[calendar setTitle:@"Game Releases"];
//		[calendar setCGColor:[UIColor orangeColor].CGColor];
//		[calendar setSource:source];
//		
//		NSError *error;
//		[EVENTSTORE saveCalendar:calendar commit:YES error:&error];
//		
//		[GAMER setCalendarIdentifier:calendar.calendarIdentifier];
//		[[NSManagedObjectContext contextForCurrentThread] saveToPersistentStoreAndWait];
//	}
//	
//	return accessGranted;
//}

+ (NSMutableURLRequest *)requestForGamesWithTitle:(NSString *)title fields:(NSString *)fields platforms:(NSArray *)platforms{
	NSString *platformIdentifiers = [[platforms valueForKey:@"identifier"] componentsJoinedByString:@"|"];
	NSString *stringURL = [NSString stringWithFormat:@"http://api.giantbomb.com/games/3030/?api_key=%@&format=json&sort=date_added:desc&field_list=%@&filter=platforms:%@,name:%@", APIKEY, fields, platformIdentifiers, title];
	
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

@end
