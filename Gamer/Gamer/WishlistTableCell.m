//
//  WishlistTableCell.m
//  Gamer
//
//  Created by Caio Mello on 02/08/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "WishlistTableCell.h"
#import "WishlistCollectionCell.h"
#import "Game.h"
#import "Release.h"
#import "Platform.h"
#import "Metascore.h"

@interface WishlistTableCell () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSCache *imageCache;

@end

@implementation WishlistTableCell

#pragma mark - Appearance

- (void)awakeFromNib{
	[super awakeFromNib];
	
	UIView *cellBackgroundView = [UIView new];
	[cellBackgroundView setBackgroundColor:[UIColor darkGrayColor]];
	[cellBackgroundView.layer setMasksToBounds:YES];
	[self setSelectedBackgroundView:cellBackgroundView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
	UIColor *platformColor = self.platformLabel.backgroundColor;
	
    [super setSelected:selected animated:animated];
	
	[self.platformLabel setBackgroundColor:platformColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
	UIColor *platformColor = self.platformLabel.backgroundColor;
	
	[super setHighlighted:highlighted animated:animated];
	
	if (highlighted){
		[self.platformLabel setBackgroundColor:platformColor];
	}
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return self.games.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = self.games[indexPath.row];
	
	WishlistCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	
	UIImage *image = [self.imageCache objectForKey:game.imagePath.lastPathComponent];
	
	if (image){
		[cell.coverImageView setImage:image];
		[cell.coverImageView setBackgroundColor:[UIColor clearColor]];
	}
	else{
		[cell.coverImageView setImage:nil];
		
		__block UIImage *image = [UIImage imageWithContentsOfFile:game.imagePath];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			CGSize imageSize = [Tools sizeOfImage:image aspectFitToWidth:cell.coverImageView.frame.size.width];
			
			UIGraphicsBeginImageContext(imageSize);
			[image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
			image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[cell.coverImageView setImage:image];
				[cell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
				
				if (image){
					[self.imageCache setObject:image forKey:game.imagePath.lastPathComponent];
				}
			});
		});
	}
	
	[cell.preorderedIcon setHidden:([game.preordered isEqualToNumber:@(YES)] && [game.released isEqualToNumber:@(NO)]) ? NO : YES];
	
	if (game.selectedRelease){
		[cell.platformLabel setText:game.selectedRelease.platform.abbreviation];
		[cell.platformLabel setBackgroundColor:game.selectedRelease.platform.color];
		[cell.titleLabel setText:game.selectedRelease.title];
		[cell.dateLabel setText:game.selectedRelease.releaseDateText];
	}
	else{
		Platform *platform = game.wishlistPlatform;
		[cell.platformLabel setText:platform.abbreviation];
		[cell.platformLabel setBackgroundColor:platform.color];
		[cell.titleLabel setText:game.title];
		[cell.dateLabel setText:game.releaseDateText];
	}
	
	if (game.selectedMetascore){
		[cell.metascoreLabel setText:[game.selectedMetascore.criticScore isEqualToNumber:@(0)] ? nil : [NSString stringWithFormat:@"%@", game.selectedMetascore.criticScore]];
		[cell.metascoreLabel setTextColor:[Networking colorForMetascore:[NSString stringWithFormat:@"%@", game.selectedMetascore.criticScore]]];
	}
	else{
		[cell.metascoreLabel setText:nil];
		[cell.metascoreLabel setTextColor:[UIColor clearColor]];
	}
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self.delegate wishlistTableCellCollectionView:collectionView didSelectGame:self.games[indexPath.row]];
}

@end
