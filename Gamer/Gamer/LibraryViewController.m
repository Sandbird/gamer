//
//  LibraryCollectionViewController.m
//  Gamer
//
//  Created by Caio Mello on 24/07/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "LibraryViewController.h"
#import "LibraryCollectionCell.h"
#import "Game.h"
#import "Platform.h"
#import "GameTableViewController.h"
#import "HeaderCollectionReusableView.h"

@interface LibraryViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) UIView *guideView;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation LibraryViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameDownloadedNotification:) name:@"GameDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLibraryNotification:) name:@"RefreshLibrary" object:nil];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	_sectionChanges = [NSMutableArray array];
	_objectChanges = [NSMutableArray array];
	_fetchedResultsController = [self fetch];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] set:kGAIScreenName value:@"Library"];
	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
	if (_fetchedResultsController.sections.count == 0){
		_guideView = [[NSBundle mainBundle] loadNibNamed:[Tools deviceIsiPad] ? @"iPad" : @"iPhone" owner:self options:nil][1];
		[self.view addSubview:_guideView];
		[_guideView setFrame:self.view.frame];
	}
	else{
		[_guideView removeFromSuperview];
	}
	
	return _fetchedResultsController.sections.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
	NSString *sectionName = [_fetchedResultsController.sections[indexPath.section] name];
	Platform *platform = [Platform findFirstByAttribute:@"index" withValue:sectionName];
	
	HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
	[headerView.titleLabel setText:platform.name];
	[headerView.separator setHidden:indexPath.section == 0 ? YES : NO];
	return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [_fetchedResultsController.sections[section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	LibraryCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	
	Game *game = [_fetchedResultsController objectAtIndexPath:indexPath];
	UIImage *image = [UIImage imageWithData:game.thumbnailLarge];
	[cell.imageView setImage:image];
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:indexPath];
}

#pragma mark - Fetch

- (NSFetchedResultsController *)fetch{
	if (!_fetchedResultsController)
		_fetchedResultsController = [Game fetchAllGroupedBy:@"libraryPlatform.index" withPredicate:[NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"libraryPlatform.index,title" ascending:YES delegate:nil];
	return _fetchedResultsController;
}

#pragma mark - FetchedResultsController

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type{
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert: change[@(type)] = @(sectionIndex); break;
        case NSFetchedResultsChangeDelete: change[@(type)] = @(sectionIndex); break;
    }
    
    [_sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type){
        case NSFetchedResultsChangeInsert: change[@(type)] = newIndexPath; break;
        case NSFetchedResultsChangeDelete: change[@(type)] = indexPath; break;
        case NSFetchedResultsChangeUpdate: change[@(type)] = indexPath; break;
        case NSFetchedResultsChangeMove: change[@(type)] = @[indexPath, newIndexPath]; break;
    }
    [_objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    if (_sectionChanges.count > 0){
        [_collectionView performBatchUpdates:^{
            for (NSDictionary *change in _sectionChanges){
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type) {
                        case NSFetchedResultsChangeInsert: [_collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]]; break;
                        case NSFetchedResultsChangeDelete: [_collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]]; break;
                        case NSFetchedResultsChangeUpdate: [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]]; break;
                    }
                }];
            }
        } completion:nil];
    }
    
    if ([_objectChanges count] > 0 && [_sectionChanges count] == 0){
        if ([self shouldReloadCollectionViewToPreventKnownIssue] || _collectionView.window == nil) {
            // This is to prevent a bug in UICollectionView from occurring.
            // The bug presents itself when inserting the first object or deleting the last object in a collection view.
            // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
            // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
            // http://openradar.appspot.com/12954582
            [_collectionView reloadData];
        }
		else{
            [_collectionView performBatchUpdates:^{
                for (NSDictionary *change in _objectChanges){
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        switch (type) {
                            case NSFetchedResultsChangeInsert: [_collectionView insertItemsAtIndexPaths:@[obj]]; break;
                            case NSFetchedResultsChangeDelete: [_collectionView deleteItemsAtIndexPaths:@[obj]]; break;
                            case NSFetchedResultsChangeUpdate: [_collectionView reloadItemsAtIndexPaths:@[obj]]; break;
                            case NSFetchedResultsChangeMove: [_collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]]; break;
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
                    if ([_collectionView numberOfItemsInSection:indexPath.section] == 0)
                        shouldReload = YES;
                    else
                        shouldReload = NO;
                    break;
                case NSFetchedResultsChangeDelete:
                    if ([_collectionView numberOfItemsInSection:indexPath.section] == 1)
                        shouldReload = YES;
                    else
                        shouldReload = NO;
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

- (void)gameDownloadedNotification:(NSNotification *)notification{
	[_collectionView reloadData];
}

- (void)refreshLibraryNotification:(NSNotification *)notification{
	_fetchedResultsController = nil;
	_fetchedResultsController = [self fetch];
	[_collectionView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		for (UIViewController *viewController in self.tabBarController.viewControllers){
			[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
		}
		
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[_fetchedResultsController objectAtIndexPath:sender]];
	}
}

@end
