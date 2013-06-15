//
//  LibraryCell.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LibraryCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *platformLabel;
@property (nonatomic, strong) IBOutlet UILabel *metascoreLabel;

@end
