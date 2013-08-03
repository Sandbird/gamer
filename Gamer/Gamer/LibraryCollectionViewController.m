//
//  LibraryCollectionViewController.m
//  Gamer
//
//  Created by Caio Mello on 24/07/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "LibraryCollectionViewController.h"
#import "LibraryCollectionCell.h"
#import "Game.h"
#import "Platform.h"
#import "GameTableViewController.h"
#import "LibraryHeaderReusableView.h"

@interface LibraryCollectionViewController () <NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSArray *platforms;
@property (nonatomic, assign) NSInteger platformSelection;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation LibraryCollectionViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(platformChangeNotification:) name:@"PlatformChange" object:nil];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	_sectionChanges = [NSMutableArray array];
	_objectChanges = [NSMutableArray array];
	_fetchedResultsController = [self fetchWithPredicate:_predicate];
}

- (void)viewWillAppear:(BOOL)animated{
//	_platforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"favorite = %@ AND libraryGames.@count > 0", @(YES)]];
//	[_segmentedControl removeAllSegments];
//	[_segmentedControl insertSegmentWithTitle:@"All" atIndex:0 animated:NO];
//	for (Platform *platform in _platforms)
//		[_segmentedControl insertSegmentWithTitle:platform.abbreviation atIndex:([_platforms indexOfObject:platform] + 1) animated:NO];
//	[_segmentedControl setSelectedSegmentIndex:0];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] sendView:@"Library"];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - CollectionView

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
	_platforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"self in %@ AND libraryGames.@count > 0", [SessionManager gamer].platforms]];
	return (_platforms.count > 1) ? CGSizeMake(0, 50) : CGSizeMake(0, 11);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
	return CGSizeMake(0, 11);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
	LibraryHeaderReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
	if (_platforms.count > 1){
		[header.segmentedControl removeAllSegments];
		[header.segmentedControl insertSegmentWithTitle:@"All" atIndex:0 animated:NO];
		for (Platform *platform in _platforms) [header.segmentedControl insertSegmentWithTitle:platform.abbreviation atIndex:([_platforms indexOfObject:platform] + 1) animated:NO];
		[header.segmentedControl setSelectedSegmentIndex:0];
		[header.segmentedControl setSelectedSegmentIndex:_platformSelection];
	}
	return header;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	LibraryCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	UIImage *image = [UIImage imageWithData:game.libraryThumbnail];
	[cell.imageView setImage:image];
	
//	CGRect shadowRect;
//	if (cell.imageView.image.size.width > cell.imageView.image.size.height)
//		shadowRect = CGRectMake(cell.imageView.bounds.origin.x, (cell.imageView.bounds.size.height - cell.imageView.image.size.height/2)/2, cell.imageView.bounds.size.width, cell.imageView.image.size.height/2);
//	else
//		shadowRect = CGRectMake((cell.imageView.bounds.size.width - cell.imageView.image.size.width/2)/2, cell.imageView.bounds.origin.y, cell.imageView.image.size.width/2, cell.imageView.bounds.size.height);
//	NSLog(@"imag:     %.f %.f", cell.imageView.image.size.width, cell.imageView.image.size.height);
//	NSLog(@"boun: %.f %.f %.f %.f", cell.imageView.bounds.origin.x, cell.imageView.bounds.origin.y, cell.imageView.bounds.size.width, cell.imageView.bounds.size.height);
//	NSLog(@"rect: %.f %.f %.f %.f", shadowRect.origin.x, shadowRect.origin.y, shadowRect.size.width, shadowRect.size.height);
//	[Tools addDropShadowToView:cell.imageView color:[UIColor redColor] opacity:1 radius:5 offset:CGSizeMake(0, 0) bounds:shadowRect];
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:indexPath];
//	[collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - Fetch

- (NSFetchedResultsController *)fetchWithPredicate:(NSPredicate *)predicate{
	if (!_fetchedResultsController)
		_fetchedResultsController = [Game fetchAllGroupedBy:nil withPredicate:(predicate) ? predicate : [NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"title" ascending:YES delegate:self];
	return _fetchedResultsController;
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

#pragma mark - Actions

- (void)platformChangeNotification:(NSNotification *)notification{
	[self.collectionView reloadData];
}

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender{
	_platformSelection = sender.selectedSegmentIndex;
	
	NSPredicate *predicate;
	
	if (sender.selectedSegmentIndex > 0){
		Platform *selectedPlatform = _platforms[sender.selectedSegmentIndex - 1];
		predicate = [NSPredicate predicateWithFormat:@"owned = %@ AND libraryPlatform = %@", @(YES), selectedPlatform];
	}
	else
		predicate = nil;
	
	_fetchedResultsController = nil;
	_fetchedResultsController = [self fetchWithPredicate:predicate];
	[self.collectionView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[_fetchedResultsController objectAtIndexPath:sender]];
	}
	//	if ([segue.identifier isEqualToString:@"SearchSegue"]){
	//		SearchTableViewController *destination = [segue destinationViewController];
	//		[destination setOrigin:2];
	//	}
}

@end
