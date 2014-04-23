//
//  PlatformCell.h
//  Gamer
//
//  Created by Caio Mello on 7/9/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlatformCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *abbreviationLabel;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UISwitch *switchControl;

@end
