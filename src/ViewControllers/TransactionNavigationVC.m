//
//  TransactionNavigationVC.m
//  Forest
//

#import "TransactionNavigationVC.h"
#import "ThemeManager.h"
#import "ResVC.h"
#import "Transaction.h"
#import "AppDelegate.h"
#import "UIView+NSObjectProperty.h"
#import "PostNaviVC.h"

#import "MySplitVC.h"

static const NSInteger kTransactionNavbarTag = 38;


@interface TransactionNavigationVC ()

@property (nonatomic) UIView *navBorder;

@property (nonatomic) UIViewController *memoViewController;

@property (nonatomic) CGFloat _statusBarHeight;

@property (nonatomic) UIView *alternateNavbarView;

@property (nonatomic) UIView *navContainer;

@end

@implementation TransactionNavigationVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.canBack = YES;
}


- (void)_setAlternateViewHidden:(BOOL)hidden
{
    self.alternateNavbarView.hidden = hidden;
}

- (void)setNavigationBarHidden:(BOOL)hidden
{
    [super setNavigationBarHidden:hidden];
    [self _setAlternateViewHidden:hidden];
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    [super setNavigationBarHidden:hidden animated:animated];
    [self _setAlternateViewHidden:hidden];
}


- (void)updateViewConstraints
{
    [super updateViewConstraints];
}

- (CGFloat)calcAlternateNavbarViewHeight
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL portrait = !UIInterfaceOrientationIsLandscape(orientation);
    BOOL isIPad = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone);
    return self._statusBarHeight + ((isIPad || portrait) ? 44 : 32);
}

- (void)viewWillLayoutSubviews
{
    self._statusBarHeight = [Env getStatusBarHeight]; //

    NSLayoutConstraint *heightConstraint = self.alternateNavbarView.constraints.firstObject;
    heightConstraint.constant = [self calcAlternateNavbarViewHeight];

    [self.alternateNavbarView setNeedsUpdateConstraints];
    [self.navigationBar setNeedsUpdateConstraints];
    [self.view setNeedsDisplay];

    self.navBorder.frame = CGRectMake(0, self.navigationBar.frame.size.height - 0.5, self.navigationBar.frame.size.width, 0.5);
    [self.navBorder setNeedsDisplay];

    [super viewWillLayoutSubviews];
}

- (void)viewDidLoad
{

    self.memoViewController = [[UIViewController alloc] init];
    [super viewDidLoad];

    self.transactions = [NSMutableArray array];

    self.delegate = self;

    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];

    self.navigationBar.shadowImage = [UIImage new];
    self.navigationBar.translucent = YES;

    self.navBorder = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height - thinLineWidth, self.navigationBar.frame.size.width, thinLineWidth)]; 

    [self.navBorder setOpaque:YES];

    [self.navigationBar addSubview:self.navBorder];

    [self.navBorder setNeedsUpdateConstraints];

    self.alternateNavbarView = [[UIView alloc] init];
    self.alternateNavbarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.alternateNavbarView belowSubview:self.navigationBar];

    [self.view addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.alternateNavbarView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.view
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:0],

        [NSLayoutConstraint constraintWithItem:self.alternateNavbarView
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.view
                                     attribute:NSLayoutAttributeLeft
                                    multiplier:1.0
                                      constant:0],

        [NSLayoutConstraint constraintWithItem:self.alternateNavbarView
                                     attribute:NSLayoutAttributeRight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.view
                                     attribute:NSLayoutAttributeRight
                                    multiplier:1
                                      constant:0],
    ]];

    [self.alternateNavbarView addConstraint:[NSLayoutConstraint constraintWithItem:self.alternateNavbarView
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:[self calcAlternateNavbarViewHeight]]];

    [self changeTheme];

}

- (void)didChangedOrientation:(NSNotification *)notification
{
}

- (void)changeNavigationBarTheme:(UINavigationBar *)navbar
{
    UIColor *backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeHomeNavigationBarBackgroundColor];
    navbar.backgroundColor = backgroundColor;
}

#pragma mark - Transactions

- (BOOL)canNavigate
{
    return [self canNavigate:nil];
}

- (BOOL)canNavigate:(Transaction *)exceptTransaction
{
    return self.canBack && [self _isDoingNavigation:exceptTransaction] == NO;
}

- (BOOL)_isDoingNavigation
{
    return [self _isDoingNavigation:nil];
}

- (BOOL)_isDoingNavigation:(Transaction *)exceptTransaction
{
    @synchronized(self.transactions)
    {
        NSUInteger count = [self.transactions count];
        if (count > 0) {
            Transaction *ts = [self.transactions objectAtIndex:count - 1];
            if (ts.isNavigationTransaction && ts != exceptTransaction) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)startTransaction:(Transaction *)transaction
{
    if ([self _isDoingNavigation]) {
        return NO;
    }

    Transaction *lastTransaction = nil;
    @synchronized(self.transactions)
    {
        lastTransaction = [self.transactions lastObject];
        [self.transactions addObject:transaction];
    }

    transaction.viewController = self.topViewController;
    transaction.delegate = self;

    [self addNavbarForTransaction:transaction
                           hidden:NO
            hidePrevNavigationBar:lastTransaction ? lastTransaction.navigationBar : self.navigationBar];

    return YES;
}

- (void)addNavbarForTransaction:(Transaction *)transaction
                         hidden:(BOOL)hidden
          hidePrevNavigationBar:(UINavigationBar *)hideNavigationBar
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    NSInteger navBarHeight = 44;
    BOOL isIPad = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone);
    if (isIPad || UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
    } else {
        navBarHeight = 32;
    }

    CGSize size = [Env fixSize:self.view.frame.size];

    CGFloat height = navBarHeight + self._statusBarHeight;
    CGFloat progressHeight = 4;

    // 色を変える
    UINavigationBar *navbar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, -height, size.width, height)];
    [self changeNavigationBar:navbar alpha:hidden ? 0.001 : 1.0];
    [navbar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];

    navbar.shadowImage = [UIImage new];
    navbar.translucent = YES;
    [self changeNavigationBarTheme:navbar];

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                                                 target:nil
                                                                                 action:@selector(onTapCancelButton:)];

    UINavigationItem *newNavItem = [[UINavigationItem alloc] initWithTitle:transaction.title];

    newNavItem.rightBarButtonItem = rightButton;
    //  newNavItem.leftBarButtonItem = leftButton;

    UILabel *navigationTitle = [[UILabel alloc] init];
    //ラベルの大きさと位置を調整
    navigationTitle.frame = CGRectMake(10, 10, self.view.frame.size.width - 20, 25);
    navigationTitle.text = transaction.title;               //テキスト名
    navigationTitle.font = [UIFont systemFontOfSize:13.0];  //fontサイズ
    navigationTitle.backgroundColor = [UIColor clearColor]; //Labelの背景色
    //navigationTitle.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];     //影の部分

    //文字揃え　（NSTextAlignmentLightとNSTextAligmentLeftもある）
    navigationTitle.textAlignment = NSTextAlignmentCenter;
    navigationTitle.textColor = [[ThemeManager sharedManager] colorForKey:ThemeSubTextColor]; //文字色

    //navigationItemのtitleViewをLabelに置き換える
    newNavItem.titleView = navigationTitle;

    // ナビゲーションバーにナビゲーションアイテムを設置
    [navbar pushNavigationItem:newNavItem animated:YES];

    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, height - progressHeight / 2 - 0.5, size.width, progressHeight)];
    [progressView setProgressViewStyle:UIProgressViewStyleBar];
    [progressView setProgress:transaction.progress animated:NO];

    UIView *navBorder = [[UIView alloc] initWithFrame:CGRectMake(0, navbar.frame.size.height, size.width, 0.5)];
    [navBorder setOpaque:YES];
    [navBorder setBackgroundColor:[[ThemeManager sharedManager] colorForKey:ThemeHomeNavigationBarBorderColor]];

    navbar.tag = kTransactionNavbarTag;
    [self.view addSubview:navbar];
    [navbar addSubview:navBorder];
    [navbar addSubview:progressView];

    [UIView animateWithDuration:0.15
        delay:0.2
        options:0
        animations:^{
          if (hideNavigationBar) {
              [self changeNavigationBar:hideNavigationBar alpha:0.001];
          }
        }
        completion:^(BOOL finished){

        }];

    [UIView animateWithDuration:0.35
        delay:0
        options:0
        animations:^{
          navbar.frame = CGRectMake(0, 0, size.width, height);
          [navbar setNeedsDisplay];
        }
        completion:^(BOOL finished){

        }];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];


    transaction.progressView = progressView;
    transaction.navigationBar = navbar;
    transaction.navBorder = navBorder;
    transaction.navItem = newNavItem;
    transaction.cancelRightButton = rightButton;
    transaction.navigationTitleLabel = navigationTitle;
}

- (void)onTapCancelButton:(id)sender
{
    Transaction *trans;
    @synchronized(self.transactions)
    {
        if ([self.transactions count] == 0) return;
        for (Transaction *tr in self.transactions) {
            if (tr.cancelRightButton == sender) {
                trans = tr;
                break;
            }
        }
    }
    if (trans) {
        trans.isCanceled = YES;

        if (trans) {
            if ([trans respondsToSelector:@selector(didCancel:)]) {
                [trans didCancel:trans];
            }
            [self closeTransaction:trans removeTransaction:YES];
        }
    }
}

- (void)closeTransaction:(Transaction *)transaction
{
    [self closeTransaction:transaction removeTransaction:YES];
}

- (void)closeTransaction:(Transaction *)transaction removeTransaction:(BOOL)removeTransaction
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    Transaction *prevTransaction = nil;
    if (removeTransaction) {
        @synchronized(self.transactions)
        {
            [self.transactions removeObject:transaction];
            prevTransaction = [self.transactions lastObject];
        }
    }

    [UIView animateWithDuration:0.35
        delay:0
        options:0
        animations:^{
          transaction.navigationBar.frame = CGRectMake(0, -transaction.navigationBar.frame.size.height, transaction.navigationBar.frame.size.width, transaction.navigationBar.frame.size.height);
          [transaction.navigationBar setNeedsDisplay];
          [self changeNavigationBar:prevTransaction ? prevTransaction.navigationBar : self.navigationBar alpha:1.0];

        }
        completion:^(BOOL finished) {
          [transaction.navigationBar popNavigationItemAnimated:NO];

          [transaction.progressView removeFromSuperview];
          [transaction.navBorder removeFromSuperview];
          [transaction.navigationBar removeFromSuperview];
          transaction.progressView = nil;
          transaction.navigationBar = nil;
          transaction.navItem.rightBarButtonItem = nil;
          transaction.navItem = nil;

          transaction.navBorder = nil;
        }];
}


#pragma - mark @protocol TransactionDelegate

- (void)titleChanged:(Transaction *)transaction
{
    [transaction.navItem setTitle:transaction.title];
    transaction.navigationTitleLabel.text = transaction.title;
    [transaction.navigationTitleLabel setNeedsDisplay];
}

- (void)progressChanged:(Transaction *)transaction
           withProgress:(CGFloat)progress
{
    @synchronized(transaction)
    {
        transaction.progress = progress;
        if (progress == 1) {
            [transaction.progressView setProgress:progress animated:NO];
            return;
        }

        NSTimeInterval now = [NSDate date].timeIntervalSince1970;
        BOOL later = now - transaction.prevProgressChangeTime <= 1.0f;

        if (later) {
            //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),^{
            //        dispatch_async(dispatch_get_main_queue(), ^{
            //            [NSThread sleepForTimeInterval:0.2];
            //             [transaction.progressView setProgress:progress animated:YES];
            //        });
            //
            //        });

        } else {
            transaction.prevProgressChangeTime = now;
            [transaction.progressView setProgress:progress animated:YES];
        }
    }
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

      dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized(self.transactions)
        {

            //念のためすべて消去
            NSArray *subviews = [self.view subviews];
            for (UIView *subview in subviews) {
                if (subview.tag == kTransactionNavbarTag) {
                    [subview removeFromSuperview];
                }
            }

            NSMutableArray *showTransactions = [NSMutableArray array];
            for (Transaction *transaction in self.transactions) {
                if (transaction.viewController == viewController) {
                    //[self.view addSubview:transaction.progressView];
                    //[self.view addSubview:transaction.navigationBar];
                    [showTransactions addObject:transaction];
                }
            }

            for (Transaction *transaction in showTransactions) {
                [self addNavbarForTransaction:transaction
                                       hidden:transaction != [showTransactions lastObject]
                        hidePrevNavigationBar:transaction == [showTransactions firstObject] ? self.navigationBar : nil];
            }
        }
      });
    });
}

- (void)changeNavigationBar:(UINavigationBar *)bar alpha:(CGFloat)alpha
{
    bar.alpha = alpha;
    if (bar == self.navigationBar) {
        self.alternateNavbarView.alpha = alpha;
    }
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    self.canBack = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [NSThread sleepForTimeInterval:0.72];
      self.canBack = YES;
    });

    @synchronized(self.transactions)
    {
        for (Transaction *transaction in self.transactions) {
            [self closeTransaction:transaction removeTransaction:transaction.isNavigationTransaction];
        }
    }

    [self changeNavigationBar:self.navigationBar alpha:1.0];

}





// @override
- (void)themeChanged:(NSNotification *)center
{
    [self changeTheme:center && [center.userInfo objectForKey:@"confChange"] == nil];
}

- (void)changeTheme
{
    [self changeTheme:YES];
}

- (void)changeTheme:(BOOL)needShowModalView
{
    if (needShowModalView) {
        [self showAndHideModalView];
    }

    ThemeManager *tm = [ThemeManager sharedManager];
    self.view.tintColor = [tm colorForKey:ThemeAccentColor];

    self.alternateNavbarView.backgroundColor = [tm colorForKey:ThemeHomeNavigationBarBackgroundColor];

    self.view.backgroundColor = [tm colorForKey:ThemeMainBackgroundColor];

    // 黒文字か白文字か
    [[UIApplication sharedApplication] setStatusBarStyle:[tm statusBarStyle] animated:YES];

    [self.navBorder setBackgroundColor:[[ThemeManager sharedManager]
                                           colorForKey:ThemeHomeNavigationBarBorderColor]];

    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[[ThemeManager sharedManager] colorForKey:ThemeNormalColor], NSForegroundColorAttributeName, nil]];

    // Enabling iOS 7 screen-edge-pan-gesture for pop action
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        //self.interactivePopGestureRecognizer.delegate = nil;
    }
}

- (void)showAndHideModalView
{
    [self presentViewController:self.memoViewController animated:NO completion:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      dispatch_sync(dispatch_get_main_queue(), ^{
        [self.memoViewController dismissViewControllerAnimated:NO completion:nil];
      });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (BOOL)shouldAutorotate
{
    return YES;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
