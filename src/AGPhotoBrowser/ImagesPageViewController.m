/*
 ImagesPageViewController.m
 
 The MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "ImagesPageViewController.h"
#import "ImageItemViewController.h"
#import "ImageScrollView.h"

#import "AGPhotoBrowserView.h"

#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/SDWebImageManager.h>
#import "BaseModalNavigationVC.h"

@interface ImagesPageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, ImageItemViewControllerDataSource>

@property (nonatomic, strong) NSArray *assets;
@property (nonatomic, assign, getter=isStatusBarHidden) BOOL statusBarHidden;

@property (nonatomic, strong) UIWindow *previousWindow;
@property (nonatomic, strong) UIWindow *currentWindow;

@property (nonatomic, strong) BaseModalNavigationVC *baseModalNavigationVC;

@end

@implementation ImagesPageViewController

- (id)initWithImageUrls:(NSArray *)imageUrls
{
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                  options:@{ UIPageViewControllerOptionInterPageSpacingKey : @30.f }];
    if (self) {
        self.assets = imageUrls;
        self.dataSource = self;
        self.delegate = self;
        //self.view.backgroundColor   = [UIColor whiteColor];
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)show
{
    [self showFromIndex:0];
}

- (UINavigationController *)wrapNavigationController
{
    BaseModalNavigationVC *navCon = [[BaseModalNavigationVC alloc] init];
    [navCon.view setBackgroundColor:[UIColor clearColor]];

    [navCon pushViewController:self animated:YES];
    self.baseModalNavigationVC = navCon;

    return navCon;

    //    [[MySplitVC instance] presentViewController:navCon animated:YES completion:^ {
    //
    //    }];
}

- (void)showFromIndex:(NSInteger)initialIndex
{
    self.previousWindow = [[UIApplication sharedApplication] keyWindow];

    self.currentWindow = [[UIWindow alloc] init];
    self.currentWindow.rootViewController = [self wrapNavigationController];
    [self.currentWindow setFrame:self.previousWindow.bounds];

    [self.currentWindow makeKeyAndVisible];

    self.currentWindow.windowLevel = UIWindowLevelStatusBar;
    self.currentWindow.hidden = NO;
    self.currentWindow.backgroundColor = [UIColor clearColor];
    self.view.alpha = 0.0;
    //[self.currentWindow addSubview:self.view];
    self.view.userInteractionEnabled = NO;

    [self fadeNavigationBarAway];

    [UIView animateWithDuration:0.2
        animations:^() {
          //self.view.backgroundColor = [UIColor colorWithWhite:0. alpha:1.];
          self.view.alpha = 1.;
        }
        completion:^(BOOL finished) {
          if (finished) {
              self.view.userInteractionEnabled = YES;
              [self setPageIndex:initialIndex];
              //self.displayingDetailedView = YES;
          }
        }];
}

- (void)hideWithCompletion:(void (^)(BOOL finished))completionBlock
{
    [UIView animateWithDuration:0.2
        animations:^() {
          self.view.alpha = 0.;
          self.view.backgroundColor = [UIColor colorWithWhite:0. alpha:0.];
        }
        completion:^(BOOL finished) {
          self.view.userInteractionEnabled = NO;
          [self.view removeFromSuperview];
          [self.baseModalNavigationVC.view removeFromSuperview];
          [self.baseModalNavigationVC removeFromParentViewController];
          [self.previousWindow makeKeyAndVisible];
          self.currentWindow.hidden = YES;
          self.currentWindow = nil;
          if (completionBlock) {
              completionBlock(finished);
          }
        }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addNotificationObserver];
}

- (void)dealloc
{
    [self removeNotificationObserver];
}

- (BOOL)prefersStatusBarHidden
{
    return self.isStatusBarHidden;
}

#pragma mark - Update Title

- (void)setTitleIndex:(NSInteger)index
{
    NSInteger count = self.assets.count;
    self.title = [NSString stringWithFormat:@"%zd of %zd", index, count];
}

#pragma mark - Page Index

- (NSInteger)pageIndex
{
    return ((ImageItemViewController *)self.viewControllers[0]).pageIndex;
}

- (void)setPageIndex:(NSInteger)pageIndex
{
    NSInteger count = self.assets.count;

    if (pageIndex >= 0 && pageIndex < count) {
        ImageItemViewController *page = [ImageItemViewController imageItemViewControllerForPageIndex:pageIndex];
        page.dataSource = self;

        [self setViewControllers:@[ page ]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:NULL];

        [self setTitleIndex:pageIndex + 1];
    }
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger index = ((ImageItemViewController *)viewController).pageIndex;

    if (index > 0) {
        ImageItemViewController *page = [ImageItemViewController imageItemViewControllerForPageIndex:(index - 1)];
        page.dataSource = self;

        return page;
    }

    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger count = self.assets.count;
    NSInteger index = ((ImageItemViewController *)viewController).pageIndex;

    if (index < count - 1) {
        ImageItemViewController *page = [ImageItemViewController imageItemViewControllerForPageIndex:(index + 1)];
        page.dataSource = self;

        return page;
    }

    return nil;
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        ImageItemViewController *vc = (ImageItemViewController *)pageViewController.viewControllers[0];
        NSInteger index = vc.pageIndex + 1;

        [self setTitleIndex:index];
    }
}

#pragma mark - Notification Observer

- (void)addNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self
               selector:@selector(scrollViewTapped:)
                   name:@"ImageScrollViewTappedNotification"
                 object:nil];
}

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ImageScrollViewTappedNotification" object:nil];
}

#pragma mark - Tap Gesture

- (void)scrollViewTapped:(NSNotification *)notification
{
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)notification.object;

    if (gesture.numberOfTapsRequired == 1) {
        //[self toogleNavigationBar:gesture];
        [self hideWithCompletion:nil];
    }
}

#pragma mark - Fade in / away navigation bar

- (void)toogleNavigationBar:(id)sender
{
    if (self.isStatusBarHidden)
        [self fadeNavigationBarIn];
    else
        [self fadeNavigationBarAway];
}

- (void)fadeNavigationBarAway
{
    self.statusBarHidden = YES;

    [UIView animateWithDuration:0.2
        animations:^{
          [self setNeedsStatusBarAppearanceUpdate];
          [self.navigationController.navigationBar setAlpha:0.0f];
          [self.navigationController setNavigationBarHidden:YES];
          self.view.backgroundColor = [UIColor blackColor];
        }
        completion:^(BOOL finished){

        }];
}

- (void)fadeNavigationBarIn
{
    self.statusBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO];

    [UIView animateWithDuration:0.2
                     animations:^{
                       [self setNeedsStatusBarAppearanceUpdate];
                       [self.navigationController.navigationBar setAlpha:1.0f];
                       self.view.backgroundColor = [UIColor whiteColor];
                     }];
}

#pragma mark - CTAssetItemViewControllerDataSource

- (NSString *)imageUrlAtIndex:(NSUInteger)index;
{
    return [self.assets objectAtIndex:index];
}

@end
