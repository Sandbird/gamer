//
//  MediaViewController.m
//  Gamer
//
//  Created by Caio Mello on 5/22/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "MediaViewController.h"

@interface MediaViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation MediaViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
	
	[self initializeImageViewWithImage:_image];
}

- (void)viewWillDisappear:(BOOL)animated{
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
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
	if (!_imageView) _imageView = [[UIImageView alloc] initWithImage:image];
	else [_imageView setImage:image];
	[_imageView setBackgroundColor:[UIColor whiteColor]];
	[_scrollView setContentSize:CGSizeMake(_imageView.frame.size.width, _imageView.frame.size.height)];
	[_scrollView addSubview:_imageView];
	[_imageView setCenter:CGPointMake(_imageView.frame.size.width/2, self.view.center.y)];
	[_scrollView setMinimumZoomScale:_scrollView.frame.size.width/_imageView.frame.size.width];
	[_scrollView setZoomScale:1];
	[_imageView setHidden:NO];
}

#pragma mark - Actions

- (IBAction)tapGestureRecognizerAction:(UITapGestureRecognizer *)sender{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
