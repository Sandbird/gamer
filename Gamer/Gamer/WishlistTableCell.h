//
//  WishlistTableCell.h
//  Gamer
//
//  Created by Caio Mello on 02/08/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WishlistTableCellCollectionViewDelegate <NSObject>

- (void)wishlistTableCellCollectionView:(UICollectionView *)collectionView didSelectGame:(Game *)game;

@end

@interface WishlistTableCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *metascoreLabel;
@property (nonatomic, strong) IBOutlet UIImageView *preorderedIcon;
@property (nonatomic, strong) IBOutlet UILabel *platformLabel;
@property (nonatomic, strong) IBOutlet UIView *separatorView;

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *games;

@property (nonatomic, weak) id<WishlistTableCellCollectionViewDelegate> delegate;

@end
