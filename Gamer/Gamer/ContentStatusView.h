//
//  ContentStatusView.h
//  Gamer
//
//  Created by Caio Mello on 17/08/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ContentStatusUnavailable,
    ContentStatusLoading
} ContentStatus;

@interface ContentStatusView : UIView

@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (id)initWithUnavailableTitle:(NSString *)title;
- (void)setStatus:(ContentStatus)contentStatus;

@end
