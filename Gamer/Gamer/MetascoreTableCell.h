//
//  MetascoreTableCell.h
//  Gamer
//
//  Created by Caio Mello on 02/08/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MetascoreTableCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *criticScoreLabel;
@property (nonatomic, strong) IBOutlet UILabel *userScoreLabel;
@property (nonatomic, strong) IBOutlet UILabel *platformLabel;

@end
