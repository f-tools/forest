//
//  BaseModalNavigationController.m
//  Forest
//

#import "BaseModalNavigationVC.h"
#import "Env.h"
#import "ThemeManager.h"
#import "SearchWebViewController.h"
#import "UIViewController+WrapWithNavigationController.h"
#import <objc/runtime.h>


@interface MyCategoryIVars : NSObject

@property (nonatomic) BOOL isActionMenuOpen;
@property (nonatomic) UIView *modalView;
@property (nonatomic) UIView *actionMenuView;
@property (nonatomic) UIView *actionScrollView;
@property (nonatomic) UIView *actionMenuSeparator;
@property (nonatomic) UIView *actionCancelButton;
@property (nonatomic) NSLayoutConstraint *actionMenuTopConstraint;
@property (nonatomic) UIView *modalBackground;
@property (nonatomic) ActionMenuBase *actionMenu;

@property (nonatomic) BOOL firstCreation;


+ (MyCategoryIVars*)fetch:(id)targetInstance;

@end

@implementation MyCategoryIVars



static void* KEY_CONNECTION_MYCLASS = &KEY_CONNECTION_MYCLASS;

+ (MyCategoryIVars*)fetch:(id)targetInstance
{
     MyCategoryIVars *ivars = objc_getAssociatedObject(targetInstance, KEY_CONNECTION_MYCLASS);
    if (ivars == nil) {
        ivars = [[MyCategoryIVars alloc] init];
        ivars.firstCreation = YES;
        objc_setAssociatedObject(targetInstance, KEY_CONNECTION_MYCLASS, ivars, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (ivars.firstCreation) {
        ivars.firstCreation = NO;
    }

    return ivars;
}

- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
}

@end



static void *UIControlRACCommandKey = &UIControlRACCommandKey;
static void *UIControlEnabledDisposableKey = &UIControlEnabledDisposableKey;

@implementation UIViewController (BaseModalNavigationVC)



- (ActionMenuBase*)actionMenu
{
    return [self fetch].actionMenu;
}

- (void)setActionMenu:(ActionMenuBase*)obj
{
    [self fetch].actionMenu = obj;
}

- (BOOL)isActionMenuOpen
{
    return [self fetch].isActionMenuOpen;
}

- (void)setIsActionMenuOpen:(BOOL)obj
{
    [self fetch].isActionMenuOpen = obj;
}


- (MyCategoryIVars*) fetch {
    MyCategoryIVars* vars = [MyCategoryIVars fetch:self];
    
    if (vars.firstCreation) {
        [self onViewDidLoad];
    }
    
    return vars;
}

- (void)onViewDidLoad
{
    [self fetch].actionMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [self fetch].actionScrollView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];

    UIButton *modalBackground = [UIButton buttonWithType:UIButtonTypeCustom];
    [self fetch].modalBackground = modalBackground;
    [self fetch].modalBackground.hidden = YES;

    [self fetch].modalBackground.backgroundColor = [UIColor clearColor];

    [self fetch].modalBackground.clipsToBounds = YES;

    [modalBackground addTarget:self
                        action:@selector(modalBackgroundTouchInsideUp:)
              forControlEvents:UIControlEventTouchUpInside];

    [self fetch].modalBackground.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:[self fetch].modalBackground];
    UIView *selfView = self.view;

    NSDictionary *viewMap = NSDictionaryOfVariableBindings(selfView, modalBackground);

    NSArray *constraintList = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[modalBackground]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:viewMap];
    [selfView addConstraints:constraintList];
    constraintList = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[modalBackground]|"
                                                             options:0
                                                             metrics:nil
                                                               views:viewMap];
    [selfView addConstraints:constraintList];

    [self fetch].actionMenuView.translatesAutoresizingMaskIntoConstraints = NO;

    [[self fetch].modalBackground addSubview:[self fetch].actionScrollView];
    [self fetch].actionScrollView.translatesAutoresizingMaskIntoConstraints = NO;

    [[self fetch].actionScrollView addSubview:[self fetch].actionMenuView];

    [[self fetch].modalBackground addConstraints:@[

        [NSLayoutConstraint constraintWithItem:[self fetch].actionScrollView
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                        toItem:[self fetch].modalBackground
                                     attribute:NSLayoutAttributeHeight
                                    multiplier:1.0
                                      constant:0]
    ]];

    [[self fetch].modalBackground addConstraints:@[
        [NSLayoutConstraint constraintWithItem:[self fetch].actionScrollView
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:[self fetch].modalBackground
                                     attribute:NSLayoutAttributeLeft
                                    multiplier:1.0
                                      constant:0],

        [NSLayoutConstraint constraintWithItem:[self fetch].actionScrollView
                                     attribute:NSLayoutAttributeRight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:[self fetch].modalBackground
                                     attribute:NSLayoutAttributeRight
                                    multiplier:1
                                      constant:-0],
    ]];

    [[self fetch].actionScrollView addConstraints:@[
        [NSLayoutConstraint constraintWithItem:[self fetch].actionMenuView
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:[self fetch].actionScrollView
                                     attribute:NSLayoutAttributeLeft
                                    multiplier:1.0
                                      constant:0],

        [NSLayoutConstraint constraintWithItem:[self fetch].actionMenuView
                                     attribute:NSLayoutAttributeRight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:[self fetch].actionScrollView
                                     attribute:NSLayoutAttributeRight
                                    multiplier:1
                                      constant:-0],

        [NSLayoutConstraint constraintWithItem:[self fetch].actionMenuView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:[self fetch].actionScrollView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1
                                      constant:0],
        [NSLayoutConstraint constraintWithItem:[self fetch].actionScrollView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:[self fetch].actionMenuView
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1
                                      constant:0]

    ]];

    [self fetch].actionMenuTopConstraint = [NSLayoutConstraint constraintWithItem:[self fetch].actionScrollView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:[self fetch].modalBackground
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1
                                                                  constant:-0];
    [[self fetch].modalBackground addConstraints:@[
        [self fetch].actionMenuTopConstraint
    ]];


}


- (BOOL)openActionMenuForTh:(UIView *)modalView
{
    return YES;
}

- (void)setActionMenuBackgroundColor:(UIColor *)color
{
    [self fetch].actionMenuView.backgroundColor = color;
    [self fetch].modalBackground.backgroundColor = color;
    [self fetch].actionMenuSeparator.backgroundColor = color;
    [self fetch].actionCancelButton.alpha = 0.0;
}

- (IBAction)onCancelTouchUpInside:(id)sender
{
    [self closeActionMenu:nil complete:nil];
}

static UIViewController *_openActionMenuVC;
- (BOOL)openActionMenu:(ActionMenuBase *)actionMenu
{
    self.actionMenu = actionMenu;
    UIView *modalView = actionMenu.view;

    [modalView removeFromSuperview];

    UIView *separator = [[UIView alloc] init];
    [self fetch].actionMenuSeparator = separator;
    separator.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    [self fetch].actionMenuView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeActionSheetBackgroundColor];
    separator.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self fetch].actionCancelButton = cancelButton;
    [cancelButton setTitle:@"キャンセル" forState:UIControlStateNormal];

    [cancelButton setTitleColor:[[ThemeManager sharedManager] colorForKey:ThemeSubTextColor] forState:UIControlStateNormal];
    [cancelButton setTitleColor:[[ThemeManager sharedManager] colorForKey:ThemeAccentColor] forState:UIControlStateHighlighted];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self
                     action:@selector(onCancelTouchUpInside:)
           forControlEvents:UIControlEventTouchUpInside];

    [[self fetch].actionMenuView addSubview:separator];
    [[self fetch].actionMenuView addSubview:modalView];
    [[self fetch].actionMenuView addSubview:cancelButton];
    modalView.backgroundColor = [UIColor clearColor];

    NSDictionary *views = NSDictionaryOfVariableBindings(separator, modalView, cancelButton);

    [[self fetch].actionMenuView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[separator]|" options:0 metrics:nil views:views]];
    [[self fetch].actionMenuView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[modalView]|" options:0 metrics:nil views:views]];
    [[self fetch].actionMenuView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cancelButton]|" options:0 metrics:nil views:views]];

    //separator constraint
    [[self fetch].actionMenuView addConstraints:@[
        [NSLayoutConstraint constraintWithItem:separator
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:[self fetch].actionMenuView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:0]
    ]];
    [separator addConstraints:@[
        [NSLayoutConstraint constraintWithItem:separator
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0
                                      constant:0.5]
    ]];

    [[self fetch].actionMenuView addConstraints:@[

        [NSLayoutConstraint constraintWithItem:modalView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:separator
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1
                                      constant:0]
    ]

    ];

    [[self fetch].actionMenuView addConstraints:@[
        [NSLayoutConstraint constraintWithItem:cancelButton
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:modalView
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:0]
    ]];
    [cancelButton addConstraints:@[
        [NSLayoutConstraint constraintWithItem:cancelButton
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0
                                      constant:55]
    ]];
    [[self fetch].actionMenuView addConstraints:@[

        [NSLayoutConstraint constraintWithItem:[self fetch].actionMenuView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:cancelButton
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1
                                      constant:0]
    ]

    ];

    [[self fetch].actionMenuView layoutIfNeeded];

    [self fetch].modalView = modalView;

    [self openActionMenuForTh:nil open:YES];
    
    return YES;

}

- (void)closeActionMenu:(UIView *)modalView complete:(void (^)(void))completionBlock
{
    [self openActionMenuForTh:nil open:NO completion:completionBlock];
}

- (IBAction)modalBackgroundTouchInsideUp:(id)sender
{
    [self openActionMenuForTh:nil open:NO];
}

- (void)openActionMenuForTh:(UIView *)thVm open:(BOOL)open
{
    [self openActionMenuForTh:thVm open:open completion:nil];
}

- (void)openUrlInDefaultWay:(NSString *)url
{
    BOOL useEmbedBrowser = [Env getConfBOOLForKey:@"useEmbedBrowser" withDefault:YES];
    if (useEmbedBrowser) {
        SearchWebViewController *searchWebViewController = [[SearchWebViewController alloc] init];
        searchWebViewController.searchUrl = url;
        UINavigationController *con = [searchWebViewController wrapWithNavigationController];

        [self presentViewController:con
                           animated:YES
                         completion:^{
                         }];

    } else {
        NSURL *nsurl = [NSURL URLWithString:url];
        [[UIApplication sharedApplication] openURL:nsurl];
    }
}

- (void)openActionMenuForTh:(UIView *)thVm open:(BOOL)open completion:(void (^)(void))completionBlock
{

    _openActionMenuVC = open ? self : _openActionMenuVC;
    if ([_openActionMenuVC fetch].actionMenuTopConstraint) {
        [[_openActionMenuVC fetch].modalBackground removeConstraint:[self fetch].actionMenuTopConstraint];
    }

    [_openActionMenuVC fetch].actionMenuTopConstraint = [NSLayoutConstraint constraintWithItem:[_openActionMenuVC fetch].actionScrollView
                                                                 attribute:open ? NSLayoutAttributeBottom : NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:[_openActionMenuVC fetch].modalBackground
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1
                                                                  constant:-0];

    [[_openActionMenuVC fetch].modalBackground addConstraints:@[ [_openActionMenuVC fetch].actionMenuTopConstraint ]];

    _openActionMenuVC.isActionMenuOpen = open;

    UIView *superView = _openActionMenuVC.view;
    if (open) {
        //_openActionMenuVC = self;
        [self fetch].modalBackground.hidden = NO;
        [self.view bringSubviewToFront:[_openActionMenuVC fetch].modalBackground];
    }

    [UIView animateWithDuration:0.2
        animations:^{
          [[_openActionMenuVC fetch].actionMenuView layoutIfNeeded];
          [_openActionMenuVC.view layoutIfNeeded];
          [[_openActionMenuVC fetch].modalView layoutIfNeeded];
          [[_openActionMenuVC fetch].actionScrollView layoutIfNeeded];
          [_openActionMenuVC fetch].modalBackground.backgroundColor = open ? [UIColor colorWithRed:0 green:0 blue:0 alpha:0.35] : [UIColor clearColor];
          [[_openActionMenuVC fetch].modalBackground layoutIfNeeded];

        }
        completion:^(BOOL s) {
          if (open == NO) {
              [_openActionMenuVC fetch].modalBackground.hidden = YES;
              NSArray *subViews = [[_openActionMenuVC fetch].actionMenuView subviews];

              for (UIView *subView in subViews) {
                  [subView removeFromSuperview];
              }
          }
          if (completionBlock) {
              completionBlock();
          }
        }];
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


@implementation BaseModalNavigationVC


- (void)dealloc
{
}


- (void) viewDidLoad
{
    [super viewDidLoad];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(onThemeChanged:)
               name:@"themeChanged"
             object:nil];
    
    [self changeTheme2:nil];
}



// 通知と値を受けるhogeメソッド
- (void)onThemeChanged:(NSNotification *)center
{
    [self changeTheme2:center];
}

- (void)changeTheme2:(NSNotification *)center
{
    [self themeChanged:center];
}

// @override
- (void)themeChanged:(NSNotification *)center
{
    self.navigationBar.barStyle = [[ThemeManager sharedManager] barStyle];

    [self fetch].actionMenuView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeActionSheetBackgroundColor];
    //[self showAndHideModalView];
    //
    self.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];

    self.navigationBar.barTintColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
    self.navigationBar.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

    [UINavigationBar appearance].titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[[ThemeManager sharedManager] colorForKey:ThemeNormalColor], NSForegroundColorAttributeName, nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
