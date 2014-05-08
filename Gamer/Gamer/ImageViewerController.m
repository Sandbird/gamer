//
//  ImageViewerController.m
//  Gamer
//
//  Created by Caio Mello on 7/8/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "ImageViewerController.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIProgressView+AFNetworking.h>
#import "DACircularProgressView+AFNetworking.h"

@interface ImageViewerController () <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet DACircularProgressView *progressView;

@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *doubleTapGestureRecognizer;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) CGSize imageSize;

@property (nonatomic, strong) NSURLSessionDownloadTask *runningTask;

@end

@implementation ImageViewerController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
	
	[_progressView setTrackTintColor:[UIColor clearColor]];
	[_progressView setProgressTintColor:[UIColor lightGrayColor]];
	[_progressView setThicknessRatio:0.2];
}

- (void)viewWillAppear:(BOOL)animated{
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	
	[self downloadImageWithImageObject:_image];
}

- (void)viewWillDisappear:(BOOL)animated{
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	
	[_runningTask cancel];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
	
	[self dismissViewControllerAnimated:YES completion:nil];
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
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageObject.originalURL]];
	
	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/original_%@", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject, request.URL.lastPathComponent]];
		return fileURL;
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
		
		_imageSize = downloadedImage.size;
		[self initializeImageViewWithImage:downloadedImage animated:YES];
		[_progressView setHidden:YES];
		[_progressView.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	}];
	[_progressView setProgressWithDownloadProgressOfTask:downloadTask animated:YES];
	[downloadTask resume];
	_runningTask = downloadTask;
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
