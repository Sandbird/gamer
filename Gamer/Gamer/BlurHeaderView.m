//
//  BlurHeaderView.m
//  Gamer
//
//  Created by Caio Mello on 11/07/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "BlurHeaderView.h"

@interface BlurHeaderView()

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *leftMarginContraint;

@end

@implementation BlurHeaderView

- initWithTitle:(NSString *)title leftMargin:(CGFloat)leftMargin{
	self = [[NSBundle mainBundle] loadNibNamed:[Tools deviceIsiPhone] ? @"iPhone" : @"iPad" owner:self options:nil][3];
	
	if (self){
		UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:self.frame];
		[toolBar setBarStyle:UIBarStyleBlackTranslucent];
		[self insertSubview:toolBar atIndex:0];
		
		[_titleLabel setText:title];
		
		[_leftMarginContraint setConstant:leftMargin];
	}
	
	return self;
}

@end
