//
//  AGPhotoBrowserZoomableView.m
//  AGPhotoBrowser
//
//  Created by Dimitris-Sotiris Tsolis on 24/11/13.
//  Copyright (c) 2013 Andrea Giavatto. All rights reserved.
//

#import "AGPhotoBrowserZoomableView.h"

@interface AGPhotoBrowserZoomableView ()

@property (nonatomic, strong, readwrite) UIImageView *imageView;

@end

@implementation AGPhotoBrowserZoomableView

- (void)dealloc
{

    if (self.imageView) {
        self.imageView.image = nil;
    }
    if (self.imageView.superview) {
        [self.imageView removeFromSuperview];
    }

    self.imageView = nil;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.delegate = self;
        self.bounces = NO;
        self.bouncesZoom = NO;

        self.imageView = [[UIImageView alloc] initWithFrame:frame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.minimumZoomScale = 1.f;
        self.maximumZoomScale = 5.0f;
        self.canPan = YES;
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(doubleTapped:)];
        doubleTap.numberOfTapsRequired = 1;
        //   [self addGestureRecognizer:doubleTap];

        [self addSubview:self.imageView];
    }
    return self;
}

#pragma mark - Public methods

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;

    /*
    CGFloat iw = image.size.width;
    CGFloat ih = image.size.height;
    
    if (iw == 0 || ih == 0) return;

    CGRect tableFrame = [UIScreen mainScreen].bounds;
    
    CGFloat scW =  self.frame.size.height;
    CGFloat scH = self.frame.size.width;

    CGFloat iRatio = iw / ih;
    CGFloat scRatio = scW / scH;

    CGFloat originX;
    CGFloat originY;
    CGFloat width;
    CGFloat height;

    if (scRatio > iRatio) { //portrait
        height = scH;
        width = iw * (scH/ih);
        originX = (scW - width)/2;
        originY = 0;
    } else { //landscape
        width = scW;
        height = ih * (scW/iw);
        originX = 0;
        originY = (scH - height)/2;
    }
    if (self.imageView) {
        if (originY != NAN)
        self.imageView.frame = CGRectMake(originX, originY, width, height);
    }
 */
}

- (void)_updateImageViewSize
{
    // Get image size
    CGSize imageSize;
    imageSize = _imageView.image.size;

    // Decide image view size
    CGRect bounds;
    CGRect rect;
    bounds = self.bounds;
    rect.origin = CGPointZero;
    if (imageSize.width / imageSize.height > CGRectGetWidth(bounds) / CGRectGetHeight(bounds)) {
        rect.size.width = CGRectGetWidth(bounds);
        rect.size.height = floor(imageSize.height / imageSize.width * CGRectGetWidth(rect));
    } else {
        rect.size.height = CGRectGetHeight(bounds);
        rect.size.width = imageSize.width / imageSize.height * CGRectGetHeight(rect);
    }

    // Set image view frame
    _imageView.frame = rect;
}

- (void)_updateImageViewOrigin
{
    // Get image view frame
    CGRect rect;
    rect = _imageView.frame;

    // Get scroll view bounds
    CGRect bounds;
    bounds = self.bounds;

    // Compare image size and bounds
    rect.origin = CGPointZero;
    if (CGRectGetWidth(rect) < CGRectGetWidth(bounds)) {
        rect.origin.x = floor((CGRectGetWidth(bounds) - CGRectGetWidth(rect)) * 0.5f);
    }
    if (CGRectGetHeight(rect) < CGRectGetHeight(bounds)) {
        rect.origin.y = floor((CGRectGetHeight(bounds) - CGRectGetHeight(rect)) * 0.5f);
    }

    // Set image view frame
    _imageView.frame = rect;
}

#pragma mark - Touch handling

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self.zoomableDelegate respondsToSelector:@selector(didDoubleTapZoomableView:)]) {
        [self.zoomableDelegate didDoubleTapZoomableView:self];
    }
}

#pragma mark - Recognizer

- (void)doubleTapped:(UITapGestureRecognizer *)recognizer
{
    if (self.zoomScale > 1.0f) {
        [UIView animateWithDuration:0.35
                         animations:^{
                           self.zoomScale = 1.0f;
                         }];
    } else {
        [UIView animateWithDuration:0.35
                         animations:^{
                           CGPoint point = [recognizer locationInView:self];
                           [self zoomToRect:CGRectMake(point.x, point.y, 0, 0) animated:YES];
                         }];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.canPan = NO;

    //horizontal check
    if (self.contentSize.width <= self.bounds.size.width) {
        self.canPan = YES;
    } else {
        if (self.contentOffset.x < 10 || self.contentOffset.x + self.bounds.size.width > -10 + self.contentSize.width) {
            self.canPan = YES;
        }
    }

    //vertical check
    if (self.contentSize.height <= self.bounds.size.height) {
        self.canPan = YES;
    } else {
        if (self.contentOffset.y < 10 || self.contentOffset.y + self.bounds.size.height > -10 + self.contentSize.height) {
            self.canPan = YES;
        }
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    //self.contentInset = UIEdgeInsetsMake(3, 3, 3, 3);
    //myLog(@"acale = %f", scale);
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{   // Update image view origin
    // [self _updateImageViewOrigin];
    //myLog(@"didzoom %f", self.contentSize.height);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
