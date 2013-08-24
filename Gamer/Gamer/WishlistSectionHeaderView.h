//
//  WishlistSectionHeaderView.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReleasePeriod.h"

@class WishlistSectionHeaderView;

@protocol WishlistSectionHeaderViewDelegate <NSObject>

@required

- (void)wishlistSectionHeaderView:(WishlistSectionHeaderView *)headerView didTapReleasePeriod:(ReleasePeriod *)releasePeriod;

@end

@interface WishlistSectionHeaderView : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *hideIndicator;
@property (nonatomic, strong) UITapGestureRecognizer *gestureRecognizer;
@property (nonatomic, assign) BOOL hidden;

@property (nonatomic, strong) ReleasePeriod *releasePeriod;

@property (nonatomic, weak) id <WishlistSectionHeaderViewDelegate> delegate;

- (id)initWithReleasePeriod:(ReleasePeriod *)releasePeriod;

@end
