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
	
	[self.singleTapGestureRecognizer requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];
	
	[self.progressView setTrackTintColor:[UIColor darkGrayColor]];
	[self.progressView setProgressTintColor:[UIColor whiteColor]];
	[self.progressView setThicknessRatio:0.2];
}

- (void)viewWillAppear:(BOOL)animated{
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	
	[self downloadImageWithImageObject:self.image];
}

- (void)viewWillDisappear:(BOOL)animated{
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	
	[self.runningTask cancel];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLayoutSubviews{
	[self centerImageView];
	
	CGFloat imageAspectRatio = self.imageSize.width/self.imageSize.height;
	CGFloat screenAspectRatio = self.view.bounds.size.width/self.view.bounds.size.height;
	
	if (imageAspectRatio > screenAspectRatio)
		[self.scrollView setMinimumZoomScale:self.view.bounds.size.width/self.imageSize.width];
	else
		[self.scrollView setMinimumZoomScale:self.view.bounds.size.height/self.imageSize.height];
	
	[self.scrollView setZoomScale:self.scrollView.minimumZoomScale];
}

#pragma mark - ScrollView

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
	return self.imageView;
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
		
		self.imageSize = downloadedImage.size;
		[self initializeImageViewWithImage:downloadedImage animated:YES];
		[self.progressView setHidden:YES];
		[self.progressView.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	}];
	[self.progressView setProgressWithDownloadProgressOfTask:downloadTask animated:YES];
	[downloadTask resume];
	self.runningTask = downloadTask;
}

#pragma mark - Custom

- (void)initializeImageViewWithImage:(UIImage *)image animated:(BOOL)animated{
	self.imageView = [[UIImageView alloc] initWithImage:image];
	[self.scrollView setContentSize:CGSizeMake(self.imageView.frame.size.width, self.imageView.frame.size.height)];
	
	[self.scrollView addSubview:self.imageView];
	if (animated) [self.scrollView.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	
	CGFloat imageAspectRatio = self.imageSize.width/self.imageSize.height;
	CGFloat screenAspectRatio = self.view.bounds.size.width/self.view.bounds.size.height;
	
	if (imageAspectRatio > screenAspectRatio)
		[self.scrollView setMinimumZoomScale:self.view.bounds.size.width/self.imageSize.width];
	else
		[self.scrollView setMinimumZoomScale:self.view.bounds.size.height/self.imageSize.height];
	
	[self.scrollView setZoomScale:self.scrollView.minimumZoomScale];
}

- (void)centerImageView{
	CGRect contentFrame = self.imageView.frame;
	
	if (self.imageView.frame.size.width < self.scrollView.bounds.size.width)
		contentFrame.origin.x = (self.scrollView.bounds.size.width - self.imageView.frame.size.width)/2;
	else
		contentFrame.origin.x = 0;
	
	if (contentFrame.size.height < self.scrollView.bounds.size.height)
		contentFrame.origin.y = (self.scrollView.bounds.size.height - contentFrame.size.height)/2;
	else
		contentFrame.origin.y = 0;
	
	self.imageView.frame = contentFrame;
}

#pragma mark - Actions

- (IBAction)doubleTapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	CGFloat imageAspectRatio = self.imageSize.width/self.imageSize.height;
	CGFloat screenAspectRatio = self.view.bounds.size.width/self.view.bounds.size.height;
	
	if ((imageAspectRatio > screenAspectRatio && self.imageSize.width > self.view.bounds.size.width) || (imageAspectRatio < screenAspectRatio && self.imageSize.height > self.view.bounds.size.height)){
		CGPoint touchLocation = [sender locationInView:self.imageView];
		CGFloat zoomScale = (self.scrollView.zoomScale < 1) ? 1 : self.scrollView.minimumZoomScale;
		CGFloat width = self.view.bounds.size.width/zoomScale;
		CGFloat height = self.view.bounds.size.height/zoomScale;
		CGFloat x = touchLocation.x - width;
		CGFloat y = touchLocation.y - height;
		CGRect zoomRect = CGRectMake(x, y, (width), (height));
		
		if (zoomScale >= self.scrollView.minimumZoomScale && zoomScale != self.scrollView.zoomScale) [self.scrollView zoomToRect:zoomRect animated:YES];
	}
}

- (IBAction)tapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
