//
//  ImageCollectionCell.h
//  Gamer
//
//  Created by Caio Mello on 7/3/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageCollectionCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
