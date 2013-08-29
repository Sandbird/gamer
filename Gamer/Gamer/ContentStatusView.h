//
//  ContentStatusView.h
//  Gamer
//
//  Created by Caio Mello on 17/08/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ContentStatusUnavailable,
    ContentStatusLoading
} ContentStatus;

@interface ContentStatusView : UIView

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (void)setStatus:(ContentStatus)contentStatus;

@end
