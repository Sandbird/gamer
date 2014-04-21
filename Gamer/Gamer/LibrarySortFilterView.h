//
//  LibraryFilterView.h
//  Gamer
//
//  Created by Caio Mello on 26/01/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LibrarySortFilterView;

@protocol LibrarySortFilterViewDelegate <NSObject>

- (void)librarySortFilterView:(LibrarySortFilterView *)view didPressSortButton:(UIButton *)button;
- (void)librarySortFilterView:(LibrarySortFilterView *)view didPressFilterButton:(UIButton *)button;
- (void)librarySortFilterView:(LibrarySortFilterView *)view didPressCancelButton:(UIButton *)button;

@end

@interface LibrarySortFilterView : UIView

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;

@property (nonatomic, strong) IBOutlet UIButton *sortButton;
@property (nonatomic, strong) IBOutlet UIButton *filterButton;

@property (nonatomic, weak) id <LibrarySortFilterViewDelegate> delegate;

- (void)showStatusWithTitle:(NSString *)title animated:(BOOL)animated;
- (void)resetAnimated:(BOOL)animated;

@end
