//
//  LibraryFilterView.m
//  Gamer
//
//  Created by Caio Mello on 26/01/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "LibrarySortFilterView.h"

@implementation LibrarySortFilterView

- (id)initWithFrame:(CGRect)frame
{
    self = [[NSBundle mainBundle] loadNibNamed:@"iPhone" owner:self options:nil][6];
	[self setFrame:CGRectOffset(self.frame, 0, -50)];
    if (self) {
		[_sortButton.layer setBorderWidth:1];
		[_sortButton.layer setBorderColor:_sortButton.tintColor.CGColor];
		[_sortButton.layer setCornerRadius:4];
		[_sortButton setBackgroundImage:[Tools imageWithColor:_sortButton.tintColor] forState:UIControlStateHighlighted];
		
		[_filterButton.layer setBorderWidth:1];
		[_filterButton.layer setBorderColor:_filterButton.tintColor.CGColor];
		[_filterButton.layer setCornerRadius:4];
		[_filterButton setBackgroundImage:[Tools imageWithColor:_filterButton.tintColor] forState:UIControlStateHighlighted];
    }
    return self;
}

#pragma mark - Custom

- (void)showStatusWithTitle:(NSString *)title animated:(BOOL)animated{
	[self.sortButton setHidden:YES];
	[self.filterButton setHidden:YES];
	
	[self.titleLabel setHidden:NO];
	[self.cancelButton setHidden:NO];
	[self.titleLabel setText:title];
	
	if (animated) [self.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
}

- (void)resetAnimated:(BOOL)animated{
	[self.sortButton setHidden:NO];
	[self.filterButton setHidden:NO];
	
	[self.titleLabel setHidden:YES];
	[self.cancelButton setHidden:YES];
	
	if (animated) [self.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
}

#pragma mark - Actions

- (IBAction)sortButtonAction:(UIButton *)sender{
	dispatch_async(dispatch_get_main_queue(), ^{
		[sender setHighlighted:YES];
	});
	
	[self.delegate librarySortFilterView:self didPressSortButton:sender];
}

- (IBAction)filterButtonAction:(UIButton *)sender{
	dispatch_async(dispatch_get_main_queue(), ^{
		[sender setHighlighted:YES];
	});
	
	[self.delegate librarySortFilterView:self didPressFilterButton:sender];
}

- (IBAction)cancelButtonAction:(UIButton *)sender{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.sortButton setHighlighted:NO];
		[self.filterButton setHighlighted:NO];
	});
	
	[self.delegate librarySortFilterView:self didPressCancelButton:sender];
}

@end
