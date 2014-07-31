//
//  MetacriticController.m
//  Gamer
//
//  Created by Caio Mello on 24/08/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "MetacriticController.h"

@interface MetacriticController () <UIWebViewDelegate>

@property (nonatomic, strong) IBOutlet UIWebView *webView;

@end

@implementation MetacriticController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self.webView.scrollView setIndicatorStyle:UIScrollViewIndicatorStyleBlack];
	
	if ([Tools deviceIsiPhone]){
		[self.webView.scrollView setContentInset:UIEdgeInsetsMake(64, 0, 0, 0)];
		[self.webView.scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 0, 0)];
	}
	
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
}

- (void)viewDidDisappear:(BOOL)animated{
	[super viewDidDisappear:animated];
	
	[self.webView stopLoading];
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

@end
