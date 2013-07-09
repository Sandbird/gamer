//
//  VideoCollectionCell.h
//  Gamer
//
//  Created by Caio Mello on 7/3/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MACircleProgressIndicator/MACircleProgressIndicator.h>

@interface VideoCollectionCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet MACircleProgressIndicator *progressIndicator;

@end
