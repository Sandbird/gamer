//
//  MetacriticController.m
//  Gamer
//
//  Created by Caio Mello on 24/08/2013.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "MetacriticController.h"

@interface MetacriticController ()

@property (nonatomic, strong) IBOutlet UIWebView *webView;

@end

@implementation MetacriticController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	[_webView loadRequest:[NSURLRequest requestWithURL:_URL]];
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

@end
