//
//  ZoomViewController.m
//  Gamer
//
//  Created by Caio Mello on 7/8/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "ZoomViewController.h"

@interface ZoomViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *doubleTapGestureRecognizer;

@end

@implementation ZoomViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated{
	[self initializeImageViewWithImage:_image];
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

#pragma mark - Custom

- (void)initializeImageViewWithImage:(UIImage *)image{
	_imageView = [[UIImageView alloc] initWithImage:image];
	[_scrollView setContentSize:CGSizeMake(_imageView.frame.size.width, _imageView.frame.size.height)];
	[_scrollView addSubview:_imageView];
	[_scrollView setMinimumZoomScale:320/_imageView.frame.size.width];
	[_scrollView setZoomScale:_scrollView.minimumZoomScale];
	[_imageView setCenter:CGPointMake(_imageView.frame.size.width/2, self.view.center.y)];
}

#pragma mark - Actions

- (IBAction)doubleTapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	CGPoint touchLocation = [sender locationInView:_imageView];
	CGFloat zoomScale = (_scrollView.zoomScale < 1) ? 1 : _scrollView.minimumZoomScale;
	
	CGFloat width = _scrollView.bounds.size.width/zoomScale;
	CGFloat height = _scrollView.bounds.size.height/zoomScale;
	CGFloat x = touchLocation.x - (width/2);
	CGFloat y = touchLocation.y - (height/2);
	
	CGRect zoomRect = CGRectMake(x, y, width, height);
	
    [_scrollView zoomToRect:zoomRect animated:YES];
}

- (IBAction)tapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
