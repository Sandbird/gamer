//
//  MetacriticController.m
//  Gamer
//
//  Created by Caio Mello on 24/08/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "MetacriticController.h"

@interface MetacriticController ()

@property (nonatomic, strong) IBOutlet UIWebView *webView;

@property (nonatomic, strong) UITapGestureRecognizer *dismissTapGesture;

@end

@implementation MetacriticController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	[_webView loadRequest:[NSURLRequest requestWithURL:_URL]];
}

- (void)viewDidAppear:(BOOL)animated{
	if ([Tools deviceIsiPad]){
		_dismissTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTapGestureAction:)];
		[_dismissTapGesture setNumberOfTapsRequired:1];
		[_dismissTapGesture setCancelsTouchesInView:NO];
		[self.view.window addGestureRecognizer:_dismissTapGesture];
	}
}

- (void)viewWillDisappear:(BOOL)animated{
	[self.view.window removeGestureRecognizer:_dismissTapGesture];
}

- (void)viewDidDisappear:(BOOL)animated{
	[_webView stopLoading];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - WebView

- (void)webViewDidStartLoad:(UIWebView *)webView{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - Actions

- (void)dismissTapGestureAction:(UITapGestureRecognizer *)sender{
	if (sender.state == UIGestureRecognizerStateEnded){
		CGPoint location = [sender locationInView:nil];
		if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil]){
			[self.view.window removeGestureRecognizer:sender];
			[self dismissViewControllerAnimated:YES completion:nil];
		}
	}
}

@end
