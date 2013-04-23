//
//  LibraryTableViewController.h
//  Gamer
//
//  Created by Caio Mello on 4/23/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LibraryTableViewController : UITableViewController

@property (nonatomic, strong) NSFetchedResultsController *gamesFetch;

@end
