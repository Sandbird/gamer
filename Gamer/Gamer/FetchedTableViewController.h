//
//  MagicalTableViewController.h
//  Gamer
//
//  Created by Caio Mello on 5/28/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FetchedTableViewDelegate <NSObject>

@required

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@interface FetchedTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, weak) id <FetchedTableViewDelegate> delegate;

@end
