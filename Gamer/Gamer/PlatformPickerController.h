//
//  PlatformPickerController.h
//  Gamer
//
//  Created by Caio Mello on 04/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PlatformPickerMode){
	PlatformPickerModeWishlist,
	PlatformPickerModeLibrary
};

@class PlatformPickerController;

@protocol PlatformPickerControllerDelegate <NSObject>

- (void)platformPicker:(PlatformPickerController *)picker didSelectPlatforms:(NSArray *)platforms;

@end

@interface PlatformPickerController : UITableViewController

@property (nonatomic, assign) NSInteger mode;
@property (nonatomic, strong) NSArray *selectablePlatforms;
@property (nonatomic, strong) NSMutableArray *selectedPlatforms;

@property (nonatomic, weak) id<PlatformPickerControllerDelegate> delegate;

@end
