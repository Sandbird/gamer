//
//  WishlistCell.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WishlistCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *metascoreLabel;
@property (nonatomic, strong) IBOutlet UIImageView *preorderedIcon;
@property (nonatomic, strong) IBOutlet UILabel *platformLabel;

@end
