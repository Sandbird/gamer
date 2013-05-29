//
//  MediaViewController.h
//  Gamer
//
//  Created by Caio Mello on 5/22/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MediaViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) UIImage *image;

@end
