//
//  LibraryFilterView.h
//  Gamer
//
//  Created by Caio Mello on 26/01/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LibraryFilterView;

@protocol LibraryFilterViewDelegate <NSObject>

- (void)libraryFilterView:(LibraryFilterView *)filterView didPressSortButton:(UIButton *)button;
- (void)libraryFilterView:(LibraryFilterView *)filterView didPressFilterButton:(UIButton *)button;
- (void)libraryFilterView:(LibraryFilterView *)filterView didPressCancelButton:(UIButton *)button;

@end

@interface LibraryFilterView : UIView

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;

@property (nonatomic, strong) IBOutlet UIButton *sortButton;
@property (nonatomic, strong) IBOutlet UIButton *filterButton;

@property (nonatomic, weak) id <LibraryFilterViewDelegate> delegate;

- (void)showStatusWithTitle:(NSString *)title animated:(BOOL)animated;
- (void)resetAnimated:(BOOL)animated;

@end
