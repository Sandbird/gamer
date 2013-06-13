//
//  HidingSectionHeaderView.h
//  Gamer
//
//  Created by Caio Mello on 4/6/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HidingSectionHeaderView;

@protocol HidingSectionViewDelegate <NSObject>

@required

- (void)hidingSectionHeaderView:(HidingSectionHeaderView *)sectionView didTapSection:(NSInteger)section;

@end

@interface HidingSectionHeaderView : UIView

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *hideIndicator;
@property (nonatomic, strong) UITapGestureRecognizer *gestureRecognizer;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, weak) id <HidingSectionViewDelegate> delegate;

- (id)initWithSectionIndex:(NSInteger)index;

@end
