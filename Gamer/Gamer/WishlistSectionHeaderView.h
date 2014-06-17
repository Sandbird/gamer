//
//  WishlistSectionHeaderView.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReleasePeriod.h"

@interface WishlistSectionHeaderView : UIView

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

@property (nonatomic, strong) ReleasePeriod *releasePeriod;

- (id)initWithReleasePeriod:(ReleasePeriod *)releasePeriod;

@end
