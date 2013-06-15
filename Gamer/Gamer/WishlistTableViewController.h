//
//  WishlistTableViewController.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FetchedTableViewController.h"
#import "WishlistSectionHeaderView.h"

@interface WishlistTableViewController : FetchedTableViewController <FetchedTableViewDelegate, WishlistSectionHeaderViewDelegate>

@end
