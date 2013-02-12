//
//  ReleasesSectionCell.h
//  Gamer
//
//  Created by Caio Mello on 2/10/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReleasesSectionCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, strong) IBOutlet UIImageView *iconImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *hideIndicator;

@end
