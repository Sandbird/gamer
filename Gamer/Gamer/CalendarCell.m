//
//  CalendarCell.m
//  Gamer
//
//  Created by Caio Mello on 1/21/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "CalendarCell.h"

@implementation CalendarCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
