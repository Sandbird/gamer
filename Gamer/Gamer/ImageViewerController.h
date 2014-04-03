//
//  ImageViewerController.h
//  Gamer
//
//  Created by Caio Mello on 7/8/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Image.h"

@interface ImageViewerController : UIViewController

@property (nonatomic, strong) Image *image;

- (IBAction)doubleTapGestureRecognizerAction:(UITapGestureRecognizer *)sender;
- (IBAction)tapGestureRecognizerAction:(UITapGestureRecognizer *)sender;

@end
