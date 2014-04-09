//
//  ReleasesController.h
//  Gamer
//
//  Created by Caio Mello on 03/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ReleasesController;

@protocol ReleasesControllerDelegate <NSObject>

- (void)releasesController:(ReleasesController *)controller didSelectRelease:(Release *)release;

@end

@interface ReleasesController : UITableViewController

@property (nonatomic, strong) Game *game;

@property (nonatomic, weak) id<ReleasesControllerDelegate> delegate;

@end
