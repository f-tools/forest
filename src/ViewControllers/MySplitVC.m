#import "MySplitVC.h"
#import "ThemeManager.h"
#import "NextSearchVC.h"
#import "ThListVC.h"
#import "MyNavigationVC.h"
#import "Views.h"

static MySplitVC *_instance;


@interface MySplitVC ()

@property (nonatomic) UIView *separatorView;
@property (nonatomic) NSLayoutConstraint *leftWidthConstriant;

@property (nonatomic) PostNaviVC *postNaviVC;
@property (nonatomic) PostNaviVC *postCreateNaviVC;

@end

@implementation MySplitVC

static NSString *const kTabletModeKey = @"tabletMode";

+ (MySplitVC *)instance
{
    return _instance;
}

+ (MyNavigationVC *)sideNavInstance 
{
    if ([self instance].isTabletMode ==true) {
        return [self instance].leftMyNavigationVC;
    } else {
        return [self instance].phoneMyNavigationVC;
    }

}

- (void) dealloc {

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self
                  name:@"themeChanged"
                object:nil];
}

- (void)viewDidLoad
{
    _instance = self;

    [super viewDidLoad];

    if ([Env getConfBOOLForKey:kTabletModeKey withDefault:NO]) {
        [self buildTabletUI];
    } else {
        [self buildPhoneUI];
    }

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(themeChangeHandler:) name:@"themeChanged" object:nil];

    //[self changeTheme];
}

- (void)viewWillLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.leftWidthConstriant.constant = self.view.bounds.size.width / 3;

    [self.view layoutIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)themeChangeHandler:(NSNotification *)center
{
    if (self.isTabletMode) {
        self.separatorView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    }
}

- (void)changeTabletMode:(BOOL)enabled
{
    if (self.isTabletMode == enabled) {
        return;
    }

    self.isTabletMode = enabled;
    if (self.isTabletMode) {
        [self removePhoneViwes];
        [self buildTabletUI];
    } else {
        [self removeTabletViews];
        [self buildPhoneUI];
    }
}

- (MyNavigationVC *)resParentMyNavigationVC
{
    if (self.isTabletMode) {
        return self.rightMyNavigationVC;
    } else {
        return self.phoneMyNavigationVC;
    }
}

- (CGFloat)thListTableViewWidth:(ThListBaseVC *)thListVC
{
    if (self.isTabletMode) {
        return self.leftMyNavigationVC.view.bounds.size.width;
    } else {
        return self.phoneMyNavigationVC.view.bounds.size.width;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//　タブレットモードでコンテンツパネルでスレを開くリクエスト
// タブはまだないのでこの仕様でOK。
- (void)showThInRight:(Th *)th
{
}

- (void)buildPhoneUI
{
    self.isTabletMode = NO;

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PhoneStory" bundle:nil];
    if (sb) {
        self.phoneMyNavigationVC = (MyNavigationVC *)[sb instantiateViewControllerWithIdentifier:@"phoneNavi"];
        [self addChildViewController:self.phoneMyNavigationVC];
        [self.view addSubview:self.phoneMyNavigationVC.view];
        [Views _constraintParentFit:self.phoneMyNavigationVC.view withParentView:self.view];
        [self.phoneMyNavigationVC didMoveToParentViewController:self];
    }
}

- (void)buildTabletUI
{
    self.isTabletMode = YES;

    //左側一覧用「MyNavigationVC」を配置
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PhoneStory" bundle:nil];
    self.leftMyNavigationVC = (MyNavigationVC *)[sb instantiateViewControllerWithIdentifier:@"phoneNavi"];
    [self addChildViewController:self.leftMyNavigationVC];
    [self.view addSubview:self.leftMyNavigationVC.view];
    [self.leftMyNavigationVC didMoveToParentViewController:self];

    self.rightMyNavigationVC = [[MyNavigationVC alloc] init];
    ;
    [self addChildViewController:self.rightMyNavigationVC];
    [self.view addSubview:self.rightMyNavigationVC.view];
    [self.rightMyNavigationVC didMoveToParentViewController:self];

    self.separatorView = [UIView new];
    self.separatorView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    [self.view addSubview:self.separatorView];

    [self modifyTabletModeConstraints:NO];
}

- (void)removeTabletViews
{
    [self.leftMyNavigationVC willMoveToParentViewController:nil];
    [self.leftMyNavigationVC.view removeFromSuperview];
    [self.leftMyNavigationVC removeFromParentViewController];

    self.leftMyNavigationVC = nil;

    [self.rightMyNavigationVC willMoveToParentViewController:nil];
    [self.rightMyNavigationVC.view removeFromSuperview];
    [self.rightMyNavigationVC removeFromParentViewController];

    self.rightMyNavigationVC = nil;
}

- (void)removePhoneViwes
{
    [self.phoneMyNavigationVC willMoveToParentViewController:nil];
    [self.phoneMyNavigationVC.view removeFromSuperview];
    [self.phoneMyNavigationVC removeFromParentViewController];
    self.phoneMyNavigationVC = nil;
}

- (void)modifyTabletModeConstraints:(BOOL)remove
{
    UIView *leftMyNavView = self.leftMyNavigationVC.view;
    UIView *rightView = self.rightMyNavigationVC.view;

    leftMyNavView.translatesAutoresizingMaskIntoConstraints = NO;
    rightView.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *separator = self.separatorView;
    separator.translatesAutoresizingMaskIntoConstraints = NO;

    NSDictionary *views = NSDictionaryOfVariableBindings(leftMyNavView, separator, rightView);
    NSDictionary *metrics = @{ @"width" : @(self.view.frame.size.height / 3) };

    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:
                                                   [NSString stringWithFormat:
                                                                 @"H:|[leftMyNavView(width)][separator(==0.5)][rightView]|"]
                                                                   options:0
                                                                   metrics:metrics
                                                                     views:views];

    for (NSLayoutConstraint *con in constraints) {
        if (con.firstAttribute == NSLayoutAttributeWidth && con.firstItem == leftMyNavView) {
            self.leftWidthConstriant = con;
        }
    }

    [self.view addConstraints:constraints];

    constraints = [NSLayoutConstraint constraintsWithVisualFormat:
                                          [NSString stringWithFormat:
                                                        @"V:|[leftMyNavView]|"]
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.view addConstraints:constraints];

    constraints = [NSLayoutConstraint constraintsWithVisualFormat:
                                          [NSString stringWithFormat:@"V:|[separator]|"]
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.view addConstraints:constraints];

    constraints = [NSLayoutConstraint constraintsWithVisualFormat:
                                          [NSString stringWithFormat:@"V:|[rightView]|"]
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.view addConstraints:constraints];
}

- (PostNaviVC *)sharedPostNaviVC
{
    if (self.postNaviVC == nil) {
        self.postNaviVC = [[PostNaviVC alloc] init];
    }
    return self.postNaviVC;
}

- (PostNaviVC *)sharedCreatePostNaviVC
{
    if (self.postCreateNaviVC == nil) {
        self.postCreateNaviVC = [[PostNaviVC alloc] init];
    }
    return self.postCreateNaviVC;
}

- (void)moveToConfig
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"myViewController"];
    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [[MySplitVC instance] presentViewController:vc animated:YES completion:NULL];

    //[self performSegueWithIdentifier:@"segueToConfig" sender:self];
}

@end
