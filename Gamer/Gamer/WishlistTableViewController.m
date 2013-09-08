//
//  WishlistTableViewController.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "WishlistTableViewController.h"
#import "WishlistCell.h"
#import "Game.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "ReleasePeriod.h"
#import "ReleaseDate.h"
#import "GameTableViewController.h"
#import "WishlistSectionHeaderView.h"

@interface WishlistTableViewController () <FetchedTableViewDelegate, WishlistSectionHeaderViewDelegate>

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation WishlistTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	[self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	_operationQueue = [[NSOperationQueue alloc] init];
	[_operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
	
	self.fetchedResultsController = [self fetch];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] sendView:@"Wishlist"];
	
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
	
	[self updateGamesReleasePeriods];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	if (self.fetchedResultsController.sections.count == 0){
		UIView *view = [[NSBundle mainBundle] loadNibNamed:@"iPhone" owner:self options:nil][0];
		[tableView setBackgroundView:view];
	}
	else
		[tableView setBackgroundView:nil];
	
    return self.fetchedResultsController.sections.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
	NSString *sectionName = [self.fetchedResultsController.sections[section] name];
	ReleasePeriod *releasePeriod = [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(sectionName.integerValue)];
	
	WishlistSectionHeaderView *headerView = [[WishlistSectionHeaderView alloc] initWithReleasePeriod:releasePeriod];
	[headerView setDelegate:self];
	
	return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	return (game.identifier) ? tableView.rowHeight : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    WishlistCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	BOOL lastRow = (indexPath.row >= ([tableView numberOfRowsInSection:indexPath.section] - 2)) ? YES : NO;
	[cell setSeparatorInset:UIEdgeInsetsMake(0, (lastRow ? (tableView.frame.size.width * 2) : 68), 0, 0)];
	
	[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[game setWanted:@(NO)];
	[game setWishlistPlatform:nil];
	
	[[SessionManager eventStore] removeEvent:[[SessionManager eventStore] eventWithIdentifier:game.releaseDate.eventIdentifier] span:EKSpanThisEvent commit:YES error:nil];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND wanted = %@", game.releasePeriod.identifier, @(YES)];
	NSArray *games = [Game findAllWithPredicate:predicate inContext:_context];
	
	if (games.count == 0)
		[game.releasePeriod.placeholderGame setHidden:@(YES)];
	
	[_context saveToPersistentStoreAndWait];
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WishlistCell *customCell = (WishlistCell *)cell;
	[customCell.titleLabel setText:(game.identifier) ? game.title : nil];
	[customCell.dateLabel setText:game.releaseDateText];
	[customCell.coverImageView setImage:[UIImage imageWithData:game.thumbnail]];
	[customCell.platformLabel setText:game.wishlistPlatform.abbreviation];
	[customCell.platformLabel setBackgroundColor:game.wishlistPlatform.color];
}

#pragma mark - HidingSectionView

- (void)wishlistSectionHeaderView:(WishlistSectionHeaderView *)headerView didTapReleasePeriod:(ReleasePeriod *)releasePeriod{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND wanted = %@", releasePeriod.identifier, @(YES)];
	NSArray *games = [Game findAllWithPredicate:predicate];
	
	for (Game *game in games)
		[game setHidden:@(!game.hidden.boolValue)];
	
	[_context saveToPersistentStoreAndWait];
}

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)fetch{
	if (!self.fetchedResultsController){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hidden = %@ AND (wanted = %@ OR identifier = nil)", @(NO), @(YES)];
		
		self.fetchedResultsController = [Game fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:predicate sortedBy:@"releasePeriod.identifier,releaseDate.date,title" ascending:YES delegate:self];
	}
	
	return self.fetchedResultsController;
}

#pragma mark - Networking

- (void)requestInformationForGame:(Game *)game{
	NSURLRequest *request = [SessionManager URLRequestForGameWithFields:@"expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,id,name,original_release_date" identifier:game.identifier];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Game - Size: %lld bytes", self, response.statusCode, response.expectedContentLength);
		
		//		NSLog(@"%@", JSON);
		
		[[Tools dateFormatter] setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
		
		NSDictionary *results = JSON[@"results"];
		
		// Info
		[game setTitle:[Tools stringFromSourceIfNotNull:results[@"name"]]];
		
		// Release date
		NSString *originalReleaseDate = [Tools stringFromSourceIfNotNull:results[@"original_release_date"]];
		NSInteger expectedReleaseDay = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_day"]].integerValue;
		NSInteger expectedReleaseMonth = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_month"]].integerValue;
		NSInteger expectedReleaseQuarter = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_quarter"]].integerValue;
		NSInteger expectedReleaseYear = [Tools integerNumberFromSourceIfNotNull:results[@"expected_release_year"]].integerValue;
		
		NSCalendar *calendar = [NSCalendar currentCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		
		if (originalReleaseDate){
			NSDateComponents *originalReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[[Tools dateFormatter] dateFromString:originalReleaseDate]];
			[originalReleaseDateComponents setHour:10];
			[originalReleaseDateComponents setQuarter:[self quarterForMonth:originalReleaseDateComponents.month]];
			
			NSDate *releaseDateFromComponents = [calendar dateFromComponents:originalReleaseDateComponents];
			
			ReleaseDate *releaseDate = [ReleaseDate findFirstByAttribute:@"date" withValue:releaseDateFromComponents];
			if (!releaseDate) releaseDate = [ReleaseDate createInContext:_context];
			[releaseDate setDate:releaseDateFromComponents];
			[releaseDate setDay:@(originalReleaseDateComponents.day)];
			[releaseDate setMonth:@(originalReleaseDateComponents.month)];
			[releaseDate setQuarter:@(originalReleaseDateComponents.quarter)];
			[releaseDate setYear:@(originalReleaseDateComponents.year)];
			
			[[Tools dateFormatter] setDateFormat:@"d MMMM yyyy"];
			[game setReleaseDateText:[[Tools dateFormatter] stringFromDate:releaseDateFromComponents]];
			[game setReleased:@(YES)];
			
			[game setReleaseDate:releaseDate];
			[game setReleasePeriod:[self releasePeriodForReleaseDate:releaseDate]];
		}
		else{
			NSDateComponents *expectedReleaseDateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSQuarterCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
			[expectedReleaseDateComponents setHour:10];
			
			BOOL defined = NO;
			
			if (expectedReleaseDay){
				[expectedReleaseDateComponents setDay:expectedReleaseDay];
				[expectedReleaseDateComponents setMonth:expectedReleaseMonth];
				[expectedReleaseDateComponents setQuarter:[self quarterForMonth:expectedReleaseMonth]];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Tools dateFormatter] setDateFormat:@"d MMMM yyyy"];
				defined = YES;
			}
			else if (expectedReleaseMonth){
				[expectedReleaseDateComponents setMonth:expectedReleaseMonth + 1];
				[expectedReleaseDateComponents setDay:0];
				[expectedReleaseDateComponents setQuarter:[self quarterForMonth:expectedReleaseMonth]];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Tools dateFormatter] setDateFormat:@"MMMM yyyy"];
			}
			else if (expectedReleaseQuarter){
				[expectedReleaseDateComponents setQuarter:expectedReleaseQuarter];
				[expectedReleaseDateComponents setMonth:((expectedReleaseQuarter * 3) + 1)];
				[expectedReleaseDateComponents setDay:0];
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[[Tools dateFormatter] setDateFormat:@"QQQ yyyy"];
			}
			else if (expectedReleaseYear){
				[expectedReleaseDateComponents setYear:expectedReleaseYear];
				[expectedReleaseDateComponents setQuarter:4];
				[expectedReleaseDateComponents setMonth:13];
				[expectedReleaseDateComponents setDay:0];
				[[Tools dateFormatter] setDateFormat:@"yyyy"];
			}
			else{
				[expectedReleaseDateComponents setYear:2050];
				[expectedReleaseDateComponents setQuarter:4];
				[expectedReleaseDateComponents setMonth:13];
				[expectedReleaseDateComponents setDay:0];
			}
			
			NSDate *expectedReleaseDateFromComponents = [calendar dateFromComponents:expectedReleaseDateComponents];
			
			ReleaseDate *releaseDate = [ReleaseDate findFirstByAttribute:@"date" withValue:expectedReleaseDateFromComponents];
			if (!releaseDate) releaseDate = [ReleaseDate createInContext:_context];
			[releaseDate setDate:expectedReleaseDateFromComponents];
			[releaseDate setDay:@(expectedReleaseDateComponents.day)];
			[releaseDate setMonth:@(expectedReleaseDateComponents.month)];
			[releaseDate setQuarter:@(expectedReleaseDateComponents.quarter)];
			[releaseDate setYear:@(expectedReleaseDateComponents.year)];
			
			if (defined)
				[releaseDate setDefined:@(YES)];
			
			[game setReleaseDateText:(expectedReleaseYear) ? [[Tools dateFormatter] stringFromDate:expectedReleaseDateFromComponents] : @"TBA"];
			[game setReleased:@(NO)];
			
			[game setReleaseDate:releaseDate];
			[game setReleasePeriod:[self releasePeriodForReleaseDate:releaseDate]];
		}
		
		[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			if (_operationQueue.operationCount == 0) [self updateGamesReleasePeriods];
		}];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		if (response.statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Game", self, response.statusCode);
	}];
	[_operationQueue addOperation:operation];
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

- (ReleasePeriod *)releasePeriodForReleaseDate:(ReleaseDate *)releaseDate{
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

- (void)updateGamesReleasePeriods{
	NSArray *games = [Game findAllWithPredicate:[NSPredicate predicateWithFormat:@"wanted = %@", @(YES)]];
	for (Game *game in games)
		[game setReleasePeriod:[self releasePeriodForReleaseDate:game.releaseDate]];
	[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		// Show section if it has tracked games
		NSArray *releasePeriods = [ReleasePeriod findAll];
		
		for (ReleasePeriod *releasePeriod in releasePeriods){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"releasePeriod.identifier = %@ AND wanted = %@", releasePeriod.identifier, @(YES)];
			NSInteger gamesCount = [Game countOfEntitiesWithPredicate:predicate];
			[releasePeriod.placeholderGame setHidden:(gamesCount > 0) ? @(NO) : @(YES)];
		}
		
		[_context saveToPersistentStoreAndWait];
	}];
}

#pragma mark - Actions

- (IBAction)reloadBarButtonAction:(UIBarButtonItem *)sender{
	for (NSInteger section = 0; section < self.fetchedResultsController.sections.count; section++)
		for (NSInteger row = 0; row < ([self.fetchedResultsController.sections[section] numberOfObjects] - 1); row++)
			[self requestInformationForGame:[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		for (UIViewController *viewController in self.tabBarController.viewControllers){
			[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
		}
		
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
	}
}

@end
