//
//  LibraryCollectionCell.h
//  Gamer
//
//  Created by Caio Mello on 24/07/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LibraryCollectionCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet UIView *overlayView;
@property (nonatomic, strong) IBOutlet UIImageView *firstIcon;
@property (nonatomic, strong) IBOutlet UIImageView *secondIcon;
@property (nonatomic, strong) IBOutlet UIImageView *thirdIcon;

@end
