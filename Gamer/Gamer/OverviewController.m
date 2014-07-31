//
//  OverviewController.m
//  Gamer
//
//  Created by Caio Mello on 30/07/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "OverviewController.h"

@interface OverviewController () <UIWebViewDelegate>

@property (nonatomic, strong) IBOutlet UIWebView *webView;

@end

@implementation OverviewController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIRectEdgeAll];
	
	[self requestDescriptionWithGame:self.game];
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

#pragma mark - Networking

- (void)requestDescriptionWithGame:(Game *)game{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"description"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if ([responseObject[@"status_code"] isEqualToNumber:@(1)]) {
			if (responseObject[@"results"][@"description"] != [NSNull null]){
				NSString *HTML = responseObject[@"results"][@"description"];
				[self.webView loadHTMLString:[self formattedHTMLWithBody:HTML font:[UIFont systemFontOfSize:14] textColor:[UIColor whiteColor]] baseURL:nil];
			}
		}
		else{
			NSLog(@"%@", responseObject);
		}
	}];
	[dataTask resume];
}

#pragma mark - Custom

- (NSString *)formattedHTMLWithBody:(NSString *)body font:(UIFont *)font textColor:(UIColor *)textColor{
	NSInteger numberOfComponents = CGColorGetNumberOfComponents(textColor.CGColor);
	
	NSAssert(numberOfComponents == 4 || numberOfComponents == 2, @"Unsupported color format");
	
	NSString *colorHexString;
	
	const CGFloat *components = CGColorGetComponents(textColor.CGColor);
	
	if (numberOfComponents == 4)
	{
		NSUInteger red = components[0] * 255;
		NSUInteger green = components[1] * 255;
		NSUInteger blue = components[2] * 255;
		colorHexString = [NSString stringWithFormat:@"%02lX%02lX%02lX", (unsigned long)red, (unsigned long)green, (unsigned long)blue];
	}
	else
	{
		NSUInteger white = components[0] * 255;
		colorHexString = [NSString stringWithFormat:@"%02lX%02lX%02lX", (unsigned long)white, (unsigned long)white, (unsigned long)white];
	}
	
	CGFloat contentWidth = self.webView.bounds.size.width - 30;
	
	NSString *HTML = [NSString stringWithFormat:@"<html>\n"
                      "<head>\n"
                      "<style type=\"text/css\">\n"
                      "body {margin-left: 15px; margin-right: 15px; font-family: \"%@\"; font-size: %@; color:#%@;}\n"
					  "img {max-width: %@px; margin-left: -40px; margin-right: 15px;}\n"
					  "figcaption {font-size: 12; width: %@px; margin-left: -40px; margin-right: 15px; margin-top: 8px}\n"
					  "table {font-size: 12; border-collapse: collapse; text-align: left;}\n"
					  "th {background-color: #161616; border-left: 4px solid #161616; border-bottom: 8px solid #1B1B1B;}\n"
					  "td {background-color: #1B1B1B; border-bottom: 8px solid #1B1B1B; border-left: 4px solid #1B1B1B;}\n"
                      "</style>\n"
                      "</head>\n"
                      "<body>%@</body>\n"
                      "</html>",
                      font.familyName, @(font.pointSize), colorHexString, @(contentWidth), @(contentWidth), body];
    
	NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"<a href=.*?>(.*?)</a>" options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *linkStrippedHTML = [expression stringByReplacingMatchesInString:HTML options:0 range:NSMakeRange(0, [HTML length]) withTemplate:@"$1"];
	
	return linkStrippedHTML;
}

@end
