//
//  WishlistSectionHeaderView.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WishlistSectionHeaderView;

@protocol WishlistSectionHeaderViewDelegate <NSObject>

@required

- (void)sectionHeaderView:(WishlistSectionHeaderView *)sectionView didTapSection:(NSInteger)section;

@end

@interface WishlistSectionHeaderView : UIView

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *hideIndicator;
@property (nonatomic, strong) UITapGestureRecognizer *gestureRecognizer;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, weak) id <WishlistSectionHeaderViewDelegate> delegate;

- (id)initWithSectionIndex:(NSInteger)index;

@end
