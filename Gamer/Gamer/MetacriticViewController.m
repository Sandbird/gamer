//
//  MetacriticViewController.m
//  Gamer
//
//  Created by Caio Mello on 24/08/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "MetacriticViewController.h"

@interface MetacriticViewController ()

@property (nonatomic, strong) IBOutlet UIWebView *webView;

@end

@implementation MetacriticViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	[_webView loadRequest:[NSURLRequest requestWithURL:_URL]];
}

- (void)viewDidAppear:(BOOL)animated{
//	[[SessionManager tracker] set:kGAIScreenName value:@"Metacritic"];
//	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
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
