//
//  GameTableCell.h
//  Gamer
//
//  Created by Caio Mello on 02/08/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GameTableCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *platformLabel;

@property (nonatomic, strong) IBOutlet UIImageView *regionImageView;

@end
