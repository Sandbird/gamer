//
//  MetascoreController.h
//  Gamer
//
//  Created by Caio Mello on 03/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FetchedTableViewController.h"

@class MetascoreController;

@protocol MetascoreControllerDelegate <NSObject>

- (void)metascoreController:(MetascoreController *)controller didSelectMetascore:(Metascore *)metascore;

@end

@interface MetascoreController : FetchedTableViewController

@property (nonatomic, strong) Game *game;

@property (nonatomic, weak) id<MetascoreControllerDelegate> delegate;

@end
