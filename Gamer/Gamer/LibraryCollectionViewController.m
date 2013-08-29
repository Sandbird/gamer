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

@interface LibraryCollectionViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation LibraryCollectionViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameUpdatedNotification:) name:@"GameUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(platformChangeNotification:) name:@"PlatformChange" object:nil];
	
	_context = [NSManagedObjectContext contextForCurrentThread];
	[_context setUndoManager:nil];
	
	_sectionChanges = [NSMutableArray array];
	_objectChanges = [NSMutableArray array];
	_fetchedResultsController = [self fetchWithPredicate:_predicate];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] sendView:@"Library"];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	LibraryCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	UIImage *image = [UIImage imageWithData:game.thumbnailLarge];
	[cell.imageView setImage:image];
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:indexPath];
}

#pragma mark - Fetch

- (NSFetchedResultsController *)fetchWithPredicate:(NSPredicate *)predicate{
	if (!_fetchedResultsController)
		_fetchedResultsController = [Game fetchAllGroupedBy:nil withPredicate:(predicate) ? predicate : [NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"title" ascending:YES delegate:self];
	return _fetchedResultsController;
}

#pragma mark - Actions

- (void)gameUpdatedNotification:(NSNotification *)notification{
	[self.collectionView reloadData];
}

- (void)platformChangeNotification:(NSNotification *)notification{
	[self.collectionView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[_fetchedResultsController objectAtIndexPath:sender]];
	}
}

@end
