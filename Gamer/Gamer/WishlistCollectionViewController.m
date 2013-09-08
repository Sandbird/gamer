//
//  WishlistCollectionViewController.m
//  Gamer
//
//  Created by Caio Mello on 26/08/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "WishlistCollectionViewController.h"
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
#import "WishlistCollectionCell.h"
#import "WishlistCollectionReusableView.h"

@interface WishlistCollectionViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation WishlistCollectionViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameDownloadedNotification:) name:@"GameDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameUpdatedNotification:) name:@"GameUpdated" object:nil];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	self.fetchedResultsController = [self fetch];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] sendView:@"Wishlist"];
	
	[self updateGamesReleasePeriods];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
	if (self.fetchedResultsController.sections.count == 0){
		UIView *view = [[NSBundle mainBundle] loadNibNamed:@"iPad" owner:self options:nil][0];
		[collectionView setBackgroundView:view];
	}
	else
		[collectionView setBackgroundView:nil];
	
    return self.fetchedResultsController.sections.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
	NSString *sectionName = [self.fetchedResultsController.sections[indexPath.section] name];
	ReleasePeriod *releasePeriod = [ReleasePeriod findFirstByAttribute:@"identifier" withValue:@(sectionName.integerValue)];
	
	WishlistCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
	[headerView.titleLabel setText:releasePeriod.name];
	return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	WishlistCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[self performSegueWithIdentifier:@"GameSegue" sender:game];
}

#pragma mark - FetchedCollectionView

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];

	WishlistCollectionCell *customCell = (WishlistCollectionCell *)cell;
	[customCell.titleLabel setText:(game.identifier) ? game.title : nil];
	[customCell.dateLabel setText:game.releaseDateText];
	[customCell.coverImageView setImage:[UIImage imageWithData:game.thumbnailLarge]];
	[customCell.platformLabel setText:game.wishlistPlatform.abbreviation];
	[customCell.platformLabel setBackgroundColor:game.wishlistPlatform.color];
	
	CGFloat coverImageAspectRatio = customCell.coverImageView.image.size.width/customCell.coverImageView.image.size.height;
	CGFloat imageViewAspectRatio = customCell.coverImageView.bounds.size.width/customCell.coverImageView.bounds.size.height;
	
	[customCell.coverImageView setBackgroundColor:(coverImageAspectRatio >= imageViewAspectRatio) ? [UIColor blackColor] : [UIColor clearColor]];
}

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)fetch{
	if (!self.fetchedResultsController){
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"wanted = %@", @(YES)];
		
		self.fetchedResultsController = [Game fetchAllGroupedBy:@"releasePeriod.identifier" withPredicate:predicate sortedBy:@"releasePeriod.identifier,releaseDate.date,title" ascending:YES delegate:self];
	}
	
	return self.fetchedResultsController;
}

#pragma mark - FetchedResultsController

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
    }
    
    [_sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [_objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([_sectionChanges count] > 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in _sectionChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    if ([_objectChanges count] > 0 && [_sectionChanges count] == 0)
    {
        
        if ([self shouldReloadCollectionViewToPreventKnownIssue] || self.collectionView.window == nil) {
            // This is to prevent a bug in UICollectionView from occurring.
            // The bug presents itself when inserting the first object or deleting the last object in a collection view.
            // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
            // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
            // http://openradar.appspot.com/12954582
            [self.collectionView reloadData];
            
        } else {
			
            [self.collectionView performBatchUpdates:^{
                
                for (NSDictionary *change in _objectChanges)
                {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                        
                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        switch (type)
                        {
                            case NSFetchedResultsChangeInsert:
                                [self.collectionView insertItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeDelete:
                                [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeUpdate:
                                [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeMove:
                                [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                                break;
                        }
                    }];
                }
            } completion:nil];
        }
    }
	
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
}

- (BOOL)shouldReloadCollectionViewToPreventKnownIssue {
    __block BOOL shouldReload = NO;
    for (NSDictionary *change in self.objectChanges) {
        [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSFetchedResultsChangeType type = [key unsignedIntegerValue];
            NSIndexPath *indexPath = obj;
            switch (type) {
                case NSFetchedResultsChangeInsert:
                    if ([self.collectionView numberOfItemsInSection:indexPath.section] == 0) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeDelete:
                    if ([self.collectionView numberOfItemsInSection:indexPath.section] == 1) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeUpdate:
                    shouldReload = NO;
                    break;
                case NSFetchedResultsChangeMove:
                    shouldReload = NO;
                    break;
            }
        }];
    }
    
    return shouldReload;
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
	// Update game release periods
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

- (void)gameDownloadedNotification:(NSNotification *)notification{
	[self.collectionView reloadData];
}

- (void)gameUpdatedNotification:(NSNotification *)notification{
	[self.collectionView reloadData];
}

- (IBAction)reloadBarButtonAction:(UIBarButtonItem *)sender{
	for (NSInteger section = 0; section < self.fetchedResultsController.sections.count; section++)
		for (NSInteger row = 0; row < ([self.fetchedResultsController.sections[section] numberOfObjects]); row++)
			[self requestInformationForGame:[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		for (UIViewController *viewController in self.tabBarController.viewControllers){
			[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
		}
		
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:sender];
	}
}

@end
