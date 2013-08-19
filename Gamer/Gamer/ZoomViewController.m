//
//  ZoomViewController.m
//  Gamer
//
//  Created by Caio Mello on 7/8/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "ZoomViewController.h"
#import <MACircleProgressIndicator/MACircleProgressIndicator.h>

@interface ZoomViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet MACircleProgressIndicator *progressIndicator;

@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *doubleTapGestureRecognizer;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) NSOperation *currentOperation;

@end

@implementation ZoomViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[_progressIndicator setColor:[UIColor whiteColor]];
	
	[_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated{
	if (_image.data)
		[self initializeImageViewWithImage:[UIImage imageWithData:_image.data] animated:NO];
	else
		[self downloadImageWithImageObject:_image];
}

- (void)viewDidAppear:(BOOL)animated{
	[[SessionManager tracker] sendView:@"Zoom"];
}

- (void)viewWillDisappear:(BOOL)animated{
	[_currentOperation cancel];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden{
	return YES;
}

#pragma mark - ScrollView

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
	return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
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

#pragma mark - Networking

- (void)downloadImageWithImageObject:(Image *)imageObject{
	[_progressIndicator setValue:0];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imageObject.originalURL]];
	[request setHTTPMethod:@"GET"];
	
	AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
		[imageObject setData:UIImagePNGRepresentation(image)];
		[[NSManagedObjectContext contextForCurrentThread] saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
			[self initializeImageViewWithImage:image animated:YES];
		}];
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
	
	if (animated){
		[_scrollView addSubview:_imageView];
		[_scrollView.layer addAnimation:[Tools fadeTransitionWithDuration:0.2] forKey:nil];
	}
	else
		[_scrollView addSubview:_imageView];
	
	[_scrollView setMinimumZoomScale:self.view.frame.size.width/_imageView.frame.size.width];
	[_scrollView setZoomScale:_scrollView.minimumZoomScale];
	[_imageView setCenter:CGPointMake(_imageView.frame.size.width/2, self.view.center.y)];
}

#pragma mark - Actions

- (IBAction)doubleTapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	CGPoint touchLocation = [sender locationInView:_imageView];
	CGFloat zoomScale = (_scrollView.zoomScale < 0.5) ? 1 : _scrollView.minimumZoomScale;
	CGFloat width = _scrollView.bounds.size.width/zoomScale;
	CGFloat height = _scrollView.bounds.size.height/zoomScale;
	CGFloat x = touchLocation.x - width;
	CGFloat y = touchLocation.y - height;
	
	CGRect zoomRect = CGRectMake(x, y, (width * 2), (height * 2));
	
    [_scrollView zoomToRect:zoomRect animated:YES];
}

- (IBAction)tapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
