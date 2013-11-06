//
//  iPadTabBarController.m
//  Gamer
//
//  Created by Caio Mello on 05/11/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "iPadTabBarController.h"

@interface iPadTabBarController ()

@end

@implementation iPadTabBarController

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item{
	NSInteger index = [tabBar.items indexOfObject:item];
	if (index == 0 || index == 1){
		UINavigationController *navigationController = self.viewControllers[index];
		[navigationController popViewControllerAnimated:NO];
	}
}

@end
