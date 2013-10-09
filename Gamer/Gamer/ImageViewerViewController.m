//
//  ImageViewerViewController.m
//  Gamer
//
//  Created by Caio Mello on 7/8/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "ImageViewerViewController.h"
#import <MACircleProgressIndicator/MACircleProgressIndicator.h>
#import <AFNetworking/AFNetworking.h>

@interface ImageViewerViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet MACircleProgressIndicator *progressIndicator;

@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *doubleTapGestureRecognizer;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) CGSize imageSize;

@property (nonatomic, strong) NSOperation *currentOperation;

@end

@implementation ImageViewerViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[_progressIndicator setColor:[UIColor whiteColor]];
	
	[_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated{
	[self downloadImageWithImageObject:_image];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] set:kGAIScreenName value:@"ImageViewer"];
	[[SessionManager tracker] send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated{
	[_currentOperation cancel];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
	
	_image = nil;
	_imageView = nil;
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)viewDidLayoutSubviews{
	[self centerImageView];
	
	CGFloat imageAspectRatio = _imageSize.width/_imageSize.height;
	CGFloat screenAspectRatio = self.view.bounds.size.width/self.view.bounds.size.height;
	
	if (imageAspectRatio > screenAspectRatio)
		[_scrollView setMinimumZoomScale:self.view.bounds.size.width/_imageSize.width];
	else
		[_scrollView setMinimumZoomScale:self.view.bounds.size.height/_imageSize.height];
	
	[_scrollView setZoomScale:_scrollView.minimumZoomScale];
}

#pragma mark - ScrollView

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
	return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
	[self centerImageView];
}

#pragma mark - Networking

- (void)downloadImageWithImageObject:(Image *)imageObject{
	[_progressIndicator setValue:0];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageObject.originalURL]];
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
		_imageSize = image.size;
		[self initializeImageViewWithImage:image animated:YES];
	}];
	[operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
//		NSLog(@"Received %lld of %lld bytes", totalBytesRead, totalBytesExpectedToRead);
		[_progressIndicator setValue:(float)totalBytesRead/(float)totalBytesExpectedToRead];
	}];
	[operation start];
	_currentOperation = operation;
}

#pragma mark - Custom

- (void)initializeImageViewWithImage:(UIImage *)image animated:(BOOL)animated{
	_imageView = [[UIImageView alloc] initWithImage:image];
	[_scrollView setContentSize:CGSizeMake(_imageView.frame.size.width, _imageView.frame.size.height)];
	
	[_scrollView addSubview:_imageView];
	if (animated) [_scrollView.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	
	CGFloat imageAspectRatio = _imageSize.width/_imageSize.height;
	CGFloat screenAspectRatio = self.view.bounds.size.width/self.view.bounds.size.height;
	
	if (imageAspectRatio > screenAspectRatio)
		[_scrollView setMinimumZoomScale:self.view.bounds.size.width/_imageSize.width];
	else
		[_scrollView setMinimumZoomScale:self.view.bounds.size.height/_imageSize.height];
	
	[_scrollView setZoomScale:_scrollView.minimumZoomScale];
}

- (void)centerImageView{
	CGRect contentFrame = _imageView.frame;
	
	if (_imageView.frame.size.width < _scrollView.bounds.size.width)
		contentFrame.origin.x = (_scrollView.bounds.size.width - _imageView.frame.size.width)/2;
	else
		contentFrame.origin.x = 0;
	
	if (contentFrame.size.height < _scrollView.bounds.size.height)
		contentFrame.origin.y = (_scrollView.bounds.size.height - contentFrame.size.height)/2;
	else
		contentFrame.origin.y = 0;
	
	_imageView.frame = contentFrame;
}

#pragma mark - Actions

- (IBAction)doubleTapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	CGFloat imageAspectRatio = _imageSize.width/_imageSize.height;
	CGFloat screenAspectRatio = self.view.bounds.size.width/self.view.bounds.size.height;
	
	if ((imageAspectRatio > screenAspectRatio && _imageSize.width > self.view.bounds.size.width) || (imageAspectRatio < screenAspectRatio && _imageSize.height > self.view.bounds.size.height)){
		CGPoint touchLocation = [sender locationInView:_imageView];
		CGFloat zoomScale = (_scrollView.zoomScale < 1) ? 1 : _scrollView.minimumZoomScale;
		CGFloat width = self.view.bounds.size.width/zoomScale;
		CGFloat height = self.view.bounds.size.height/zoomScale;
		CGFloat x = touchLocation.x - width;
		CGFloat y = touchLocation.y - height;
		CGRect zoomRect = CGRectMake(x, y, (width), (height));
		
		if (zoomScale >= _scrollView.minimumZoomScale && zoomScale != _scrollView.zoomScale) [_scrollView zoomToRect:zoomRect animated:YES];
	}
}

- (IBAction)tapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
