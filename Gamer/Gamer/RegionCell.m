//
//  RegionCell.m
//  Gamer
//
//  Created by Caio Mello on 05/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "RegionCell.h"

@implementation RegionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
