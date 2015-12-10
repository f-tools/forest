//
//  ResVCActionMenu.m
//  Forest
//

#import "ResVCActionMenu.h"
#import "MyNavigationVC.h"
#import "ThListTransaction.h"
#import "BoardManager.h"
#import "ThManager.h"
#import "ActionLayout.h"
#import "ThemeManager.h"
#import "AppDelegate.h"
#import "SearchWebViewController.h"
#import "FontSizeActionMenu.h"
#import "FavSelectFragment.h"
#import "NGListVC.h"
#import "MySplitVC.h"

@interface ResVCActionMenu ()

@property (nonatomic) ActionButtonInfo *nextSearchButtonInfo;
@property (nonatomic) ActionButtonInfo *treeToggleButtonInfo;
@property (nonatomic) ActionButtonInfo *moveBoardButtonInfo;
@property (nonatomic) ActionButtonInfo *toolButtonInfo; // さらにツールのボタン

@property (nonatomic) FavSelectFragment *favSelectFragment;

//他ツール
@property (nonatomic) ActionButtonInfo *createNextThreadButtonInfo;
@property (nonatomic) ActionButtonInfo *ngManageButtonInfo; // NG管理
@property (nonatomic) ActionButtonInfo *fontConfButtonInfo;

@property (nonatomic) UISlider *listController;

@end

@implementation ResVCActionMenu

- (void)dealloc
{
}

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

- (NSArray *)createAllButtons
{
    if (self.forTool) {
        if (self.fontConfButtonInfo == nil) {

            self.fontConfButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"文字サイズ" withImageName:@"zoom_in_30.png"];
            ;

            self.createNextThreadButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"次スレ作成" withImageName:@"file_30.png"];
            self.ngManageButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"NG管理" withImageName:@"ng_shield_30.png"];
        }

        return @[ self.fontConfButtonInfo, self.createNextThreadButtonInfo ];

    } else {
        if (self.moveBoardButtonInfo == nil) {
            self.treeToggleButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"ツリー切替" withImageName:@"tree_30.png"];
            self.moveBoardButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"板へ" withImageName:@"home2_30.png"];
            self.nextSearchButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"次スレ検索" withImageName:@"flash_light.png"];
            self.toolButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"他ツール" withImageName:nil];
        }
        return @[ self.nextSearchButtonInfo, self.moveBoardButtonInfo, self.toolButtonInfo, self.treeToggleButtonInfo ];
    }
}

// @overide
- (void)onLayoutCompleted
{
    [self.favSelectFragment onLayoutCompleted];

    self.listController.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *superView = self.listController.superview;
    [self.listController addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.listController
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0
                                      constant:28]
    ]];
    [superView addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.listController
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:superView
                                     attribute:NSLayoutAttributeLeft
                                    multiplier:1.0
                                      constant:40],
        [NSLayoutConstraint constraintWithItem:self.listController

                                     attribute:NSLayoutAttributeRight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:superView
                                     attribute:NSLayoutAttributeRight
                                    multiplier:1.0
                                      constant:-40]
    ]];
}

- (NSArray *)createAboveViews
{
    if (self.forTool) return nil;

    self.listController = [[UISlider alloc] init];

    [self.listController addTarget:self action:@selector(listControllerValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.listController addTarget:self action:@selector(listControllerTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.listController addTarget:self action:@selector(listControllerTouchupInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.listController addTarget:self action:@selector(listControllerTouchupInside:) forControlEvents:UIControlEventTouchUpOutside];

    NSInteger height = (self.resVC.tableView.contentSize.height - self.resVC.tableView.bounds.size.height);

    self.listController.value = height <= 0 ? 0 : (CGFloat)self.resVC.tableView.contentOffset.y / height;

    self.favSelectFragment = [[FavSelectFragment alloc] init];
    self.favSelectFragment.th = self.resVC.th;

    return @[ self.listController, self.favSelectFragment.view ];
}

- (void)onButtonTap:(ActionButtonInfo *)info
{
    if (info == self.toolButtonInfo) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             self.forTool = YES;
                                             [self build];
                                             [self open];
                                           }];
    } else if (info == self.ngManageButtonInfo) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             NGListNavigationController *con = [[NGListNavigationController alloc] init];
                                             [[MySplitVC instance] presentViewController:con
                                                                                     animated:YES
                                                                                   completion:^{
                                                                                   }];
                                           }];
    } else if (info == self.createNextThreadButtonInfo) {

        PostNaviVC *postNaviVC = [[MySplitVC instance] sharedCreatePostNaviVC];
        Board *board = [[BoardManager sharedManager] boardForTh:self.resVC.th];
        postNaviVC.board = board;
        NSString* firstResText = [[self.resVC.th.responses objectAtIndex:0] naturalText];
        [postNaviVC applyOriginThread:self.resVC.th res1Text:firstResText ? firstResText : @""];

        postNaviVC.onPostCompleted = ^(BOOL success) {
          ThListTransaction *thListTransaction = [[ThListTransaction alloc] init];
          [thListTransaction startOpenThListTransaction:board];
        };

        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             [[MySplitVC instance] presentViewController:postNaviVC
                                                                                     animated:YES
                                                                                   completion:^{

                                                                                   }];
                                           }];
    }

    if (info.button == self.fontConfButtonInfo.button) {
        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
          [[MySplitVC instance] closeActionMenu:nil
                                             complete:^{

                                               FontSizeActionMenu *actionMenu = [[FontSizeActionMenu alloc] init];
                                               actionMenu.forRes = YES;
                                               [actionMenu build];
                                               [[MySplitVC instance] openActionMenu:actionMenu];

                                             }];
        });

    } else if (info.button == self.treeToggleButtonInfo.button) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             [self.resVC toggleTreeMode];
                                           }];

    } else if (info.button == self.treeToggleButtonInfo.button) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             [[MySplitVC instance] moveToConfig];

                                           }];
    } else if (info.button == self.moveBoardButtonInfo.button) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{

                                             ThListTransaction *thlistTransaction = [[ThListTransaction alloc] init];

                                             Board *board = [[BoardManager sharedManager] boardForTh:self.resVC.th];
                                             [thlistTransaction startOpenThListTransaction:board];
                                           }];

    } else if (info.button == self.self.nextSearchButtonInfo.button) {

        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             ThListTransaction *thlistTransaction = [[ThListTransaction alloc] init];
                                             thlistTransaction.isNextSearch = YES;
                                             thlistTransaction.th = self.resVC.th;

                                             Board *board = [[BoardManager sharedManager] boardForTh:self.resVC.th];
                                             [thlistTransaction startOpenThListTransaction:board];
                                           }];
    }
}

- (IBAction)listControllerEditingDidBegin:(id)sender
{
}

- (IBAction)listConstrollerEditingDigEnd:(id)sender
{
}

- (IBAction)listControllerTouchDown:(id)sender
{
    self.view.backgroundColor = [UIColor clearColor];
    [[MySplitVC instance] setActionMenuBackgroundColor:[UIColor clearColor]];
    self.favSelectFragment.view.alpha = 0.0;

    for (ActionButtonInfo *info in [self createAllButtons]) {
        info.button.alpha = 0.0;
    }
}

- (IBAction)listControllerTouchupInside:(id)sender
{
    [[MySplitVC instance] closeActionMenu:nil
                                       complete:^{

                                       }];
}

- (IBAction)listControllerValueChanged:(id)sender
{
    UITableView *tableView = self.resVC.tableView;
    CGFloat distance = (tableView.contentInset.top + tableView.contentSize.height + tableView.contentInset.bottom - tableView.bounds.size.height);
    tableView.contentOffset = CGPointMake(0, -tableView.contentInset.top + distance * self.listController.value);
    [tableView flashScrollIndicators];
}

- (IBAction)treeToggleValueChanged:(id)sender
{
}

@end
