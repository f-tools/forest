//
//  DynamicBaseViewController.m
//  Forest
//

#import "DynamicBaseVC.h"
#import "ThemeManager.h"
#import "MyNavigationVC.h"
#import "ResVC.h"
#import "AppDelegate.h"
#import "Env.h"
#import "ViewController+Additions.h"
#import "GestureEntry.h"
#import "GestureManager.h"

@interface DynamicBaseVC ()

@end

@implementation DynamicBaseVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _currentCellTag = 2;
    }
    return self;
}

- (void)dealloc
{
    // 通知を解除する
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self
                  name:UIDeviceOrientationDidChangeNotification
                object:nil]; //

    [nc removeObserver:self
                  name:@"themeChanged"
                object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(themeChangeHandler:) name:@"themeChanged" object:nil];

    [self changeTheme];

    [nc addObserver:self
           selector:@selector(didChangedOrientation:)
               name:UIDeviceOrientationDidChangeNotification
             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    BOOL didRegenerate = NO;
    if (self.shouldCheckOrientationWhenViewWillAppear) {
        didRegenerate = [self checkOrientation:YES];
    }

    if (didRegenerate == NO) {
        if (self.shouldReloadTableViewWhenViewWillAppear) {
            UITableView *tableView = [self thisTableView];
            [self reloadTableData:tableView];
        }
    }

    self.prevWidth = [self tableWidthForOrientation];

    self.shouldCheckOrientationWhenViewWillAppear = NO;
    self.shouldReloadTableViewWhenViewWillAppear = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)themeChangeHandler:(NSNotification *)center
{
    [self changeTheme];
    //[self startRegenerateTableDataIfVisible];
}

- (void)changeTheme
{
    UITableView *tableView = [self thisTableView];
    tableView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    tableView.separatorColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];

    self.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];
    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

    [self onThemeChanged];

    //[self startRegenerateTableDataIfVisible];
}

- (void)onThemeChanged
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didChangedOrientation:(NSNotification *)notification
{
    if ([self isViewVisible]) {
        [self checkOrientation:YES];
    } else {
        self.shouldCheckOrientationWhenViewWillAppear = YES;
    }
}

// regenerateを発動したかどうかを返す
- (BOOL)checkOrientation:(BOOL)startBackgroundParse
{
    //CGFloat width = [self tableWidthForOrientation];
    CGFloat width = self.view.frame.size.width;
    myLog(@"checkOrientation, %f, prevWidth =%f", width, self.prevWidth);
    if (width == self.prevWidth) {
        return NO;
    }
    self.prevWidth = width;
    [self onOrientationChanged:width];

    [self startRegenerateTableData:startBackgroundParse];

    return YES;
}

// subclassで呼ばれるonOrientationChanged
// @virtual
- (void)onOrientationChanged:(CGFloat)width
{
}

- (CGFloat)tableWidthForOrientation
{
    UITableView *tableView = [self thisTableView];
    CGSize size = [Env fixSize:tableView.frame.size];

    return size.width;
}

- (UITableView *)thisTableView
{
    return nil;
}

//reloadDataはtableViewインスタンスのsynchronized下で行う
- (void)reloadTableData:(UITableView *)tableView
{
    if (tableView) {
        @synchronized(tableView)
        {
            [tableView reloadData];
            self.shouldReloadTableViewWhenViewWillAppear = NO;
        }
    }
}

- (void)startRegenerateTableDataIfVisible
{
    self.currentCellTag++;

    UITableView *tableView = [self thisTableView];
    if (tableView) {
        if ([self isViewVisible]) {
            [self startRegenerateTableData];
        } else {
            self.shouldReloadTableViewWhenViewWillAppear = YES;
        }
    }
}

- (void)setCurrentCellTag:(NSUInteger)currentCellTag
{
    NSInteger max = currentCellTag;
    UITableView *tableView = [self thisTableView];
    if ([tableView isKindOfClass:[FastTableView class]]) {
        FastTableView *fastTableView = (FastTableView *)tableView;
        max = fastTableView.statusIndex > currentCellTag ? fastTableView.statusIndex + 1 : currentCellTag;
        fastTableView.statusIndex = max;
    }

    _currentCellTag = max;
}

- (void)startRegenerateTableData
{
    [self startRegenerateTableData:YES];
}

// 全てのセルを再描画する。
// STEP 1: reloadDataを呼ぶ
// STEP 2: バックグラウンドでの全てのThVmの解析を開始する。
- (void)startRegenerateTableData:(BOOL)startBackgroundParse
{
    self.currentCellTag++;
    UITableView *tableView = [self thisTableView];

    [self reloadTableData:tableView];

    if (startBackgroundParse) {
        [self startBackgroundParse];
    }
}

- (void)startBackgroundParse
{
}

- (void)tableViewScrollToBottom:(UITableView *)tableView animated:(BOOL)animated
{
    @synchronized(tableView)
    {
        NSInteger sections = [tableView numberOfSections];
        if (sections == 0) return;

        if (tableView.contentSize.height > tableView.bounds.size.height) {
            tableView.contentOffset = CGPointMake(0, tableView.contentSize.height - tableView.bounds.size.height + tableView.contentInset.bottom);

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
              dispatch_async(dispatch_get_main_queue(),
                             ^{

                               tableView.contentOffset = CGPointMake(0, tableView.contentSize.height - tableView.bounds.size.height + tableView.contentInset.bottom);

                               [UIView animateWithDuration:0.0
                                   delay:0.2
                                   options:UIViewAnimationOptionCurveLinear
                                   animations:^{
                                   }
                                   completion:^(BOOL canceled) {

                                     tableView.contentOffset = CGPointMake(0, tableView.contentSize.height - tableView.bounds.size.height + tableView.contentInset.bottom);

                                   }];
                             });
            });
        }
    }
}

- (void)tableViewScrollToBottomAnimated:(BOOL)animated
{
    [self tableViewScrollToBottom:[self thisTableView] animated:animated];
}

- (void)tableViewScrollToTop:(UITableView *)tableView animated:(BOOL)animated
{
    //NSInteger numberOfRows = [tableView numberOfRowsInSection:0];
    if (tableView.contentSize.height > 0) {
        tableView.contentOffset = CGPointMake(0, -tableView.contentInset.top);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          dispatch_async(dispatch_get_main_queue(),
                         ^{
                           tableView.contentOffset = CGPointMake(0, -tableView.contentInset.top);

                           [UIView animateWithDuration:0.0
                               delay:0.2
                               options:UIViewAnimationOptionCurveLinear
                               animations:^{
                               }
                               completion:^(BOOL canceled) {

                                 tableView.contentOffset = CGPointMake(0, -tableView.contentInset.top);

                               }];
                         });
        });
    }
}

- (void)tableViewScrollToTopAnimated:(BOOL)animated
{
    [self tableViewScrollToTop:[self thisTableView] animated:animated];
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
