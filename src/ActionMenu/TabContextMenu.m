#import "TabContextMenu.h"
#import "MyNavigationVC.h"
#import "ThListTransaction.h"
#import "BoardManager.h"
#import "ThManager.h"
#import "ActionLayout.h"
#import "ThemeManager.h"
#import "AppDelegate.h"
#import "SearchWebViewController.h"
#import "FontSizeActionMenu.h"
#import "NGListVC.h"
#import "SyncManager.h"
#import "SyncTransaction.h"
#import "ThemeVC.h"
#import "MySplitVC.h"
#import "UIViewController+WrapWithNavigationController.h"

#import "BaseModalNavigationVC.h"

@interface TabContextMenu ()

@property (nonatomic) ActionButtonInfo *confButtonInfo;
@property (nonatomic) ActionButtonInfo *searchButtonInfo;
@property (nonatomic) ActionButtonInfo *fontConfButtonInfo;
@property (nonatomic) ActionButtonInfo *ngListButtonInfo;
@property (nonatomic) ActionButtonInfo *syncButtonInfo;

@property UISegmentedControl *themeSegmentedControl;

@end

@implementation TabContextMenu

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self
                  name:@"themeChanged"
                object:nil];
}

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

- (NSArray *)createAllButtons
{
    if (self.confButtonInfo == nil) {
        self.confButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"設定" withImageName:@"settings_30.png"];
        self.searchButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"全板検索" withImageName:@"search_30.png"];
        self.fontConfButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"文字サイズ"
                                                            withImageName:@"zoom_in_30.png"];
        self.ngListButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"NG管理"
                                                          withImageName:@"ng_shield_30.png"];
        self.syncButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"Sync2ch" withImageName:@"sync_30.png"];
    }

    NSMutableArray *buttons = [NSMutableArray arrayWithArray:@[ self.confButtonInfo, self.searchButtonInfo, self.ngListButtonInfo ]];

    if (self.isBoardContext == NO) {
        [buttons addObject:self.fontConfButtonInfo];
    }

    NSString *syncId = [Env getConfStringForKey:@"Sync2ch_ID" withDefault:nil];
    NSString *syncPass = [Env getConfStringForKey:@"Sync2ch_PASS" withDefault:nil];

    if (syncId && syncPass && [syncId length] > 2 && [syncPass length] > 2) {
        [buttons addObject:self.syncButtonInfo];
    }
    return buttons;
}

- (NSArray *)createAboveViews
{

    ThemeManager *tm = [ThemeManager sharedManager];
    NSMutableArray *themeItems = [NSMutableArray array];
    [themeItems addObject:@"Light"];
    [themeItems addObject:@"Dark"];
    if (tm.selectedTheme != tm.lightTheme && tm.selectedTheme != tm.darkTheme) {
        [themeItems addObject:[tm.selectedTheme objectForKey:@"name"]];
    }
    [themeItems addObject:@"Other.."];

    self.themeSegmentedControl = [[UISegmentedControl alloc] initWithItems:themeItems];
    self.themeSegmentedControl.translatesAutoresizingMaskIntoConstraints = NO;

    [self.themeSegmentedControl addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.themeSegmentedControl
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0
                                      constant:28],
        [NSLayoutConstraint constraintWithItem:self.themeSegmentedControl

                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0
                                      constant:223]
    ]];

    self.themeSegmentedControl.selectedSegmentIndex =
        [tm selectedTheme] == [tm darkTheme] ? 1 : (tm.lightTheme == tm.selectedTheme ? 0 : 2);

    [self.themeSegmentedControl addTarget:self
                                   action:@selector(themeChangedAction:)
                         forControlEvents:UIControlEventValueChanged];

    return @[ self.themeSegmentedControl ];
}

- (IBAction)themeChangedAction:(id)sender
{
    double delayInSeconds = 0.2f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
      [[MySplitVC instance] closeActionMenu:nil
                                         complete:^{
                                           ThemeManager *themeManager = [ThemeManager sharedManager];
                                           if (self.themeSegmentedControl.selectedSegmentIndex == 0) {
                                               [themeManager changeToLightTheme];
                                           } else if (self.themeSegmentedControl.selectedSegmentIndex == 1) {
                                               [themeManager changeToDarkTheme];
                                           } else {
                                               ThemeVC *manageVC = [[ThemeVC alloc] init];
                                               id d = [manageVC wrapWithNavigationController];

                                               [[MySplitVC instance] presentViewController:d animated:YES completion:nil];
                                           }

                                         }];
    });
}

- (void)onButtonTap:(ActionButtonInfo *)info
{

    if (info.button == self.fontConfButtonInfo.button) {
        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
          [[MySplitVC instance] closeActionMenu:nil
                                             complete:^{
                                               FontSizeActionMenu *actionMenu = [[FontSizeActionMenu alloc] init];
                                               [actionMenu build];

                                               [[MySplitVC instance] openActionMenu:actionMenu];
                                             }];

        });

    } else if (info.button == self.confButtonInfo.button) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                               [[MySplitVC instance] moveToConfig];
                                           }];
    } else if (info.button == self.searchButtonInfo.button) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             SearchWebViewController *searchWebViewController = [[SearchWebViewController alloc] init];
                                             searchWebViewController.searchUrl = @"http://ff2ch.syoboi.jp";
                                               if ([MySplitVC instance].isTabletMode) {
                                                   [[MainVC instance] showThListVC:searchWebViewController];
                                               } else {
                                               
                                                   [[MyNavigationVC instance] pushMyViewController:searchWebViewController];
                                               }
                                           }];
    } else if (info.button == self.ngListButtonInfo.button) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             NGListNavigationController *con = [[NGListNavigationController alloc] init];
                                             [[MySplitVC instance] presentViewController:con
                                                                                     animated:YES
                                                                                   completion:^{
                                                                                   }];
                                           }];
    } else if (info.button == self.syncButtonInfo.button) {
        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
          [[MySplitVC instance] closeActionMenu:nil complete:nil];

          SyncTransaction *syncTransaction = [[SyncTransaction alloc] init];
          [syncTransaction startTransaction];
        });
    }
}

@end
