//
//  ThItemActionMenu.m
//  Forest
//

#import "ThItemActionMenu.h"
#import "MyNavigationVC.h"
#import "ThListTransaction.h"
#import "BoardManager.h"
#import "ThManager.h"
#import "ActionLayout.h"
#import "ThemeManager.h"
#import "NextSearchVC.h"
#import "CopyVC.h"
#import "MySplitVC.h"
#import "Th+ParseAdditions.h"

#import "UIViewController+WrapWithNavigationController.h"
#import "FavSelectFragment.h"

@interface ThItemActionMenu ()

@property (nonatomic) ActionButtonInfo *moveBoardInfo;
@property (nonatomic) ActionButtonInfo *startEditButtonInfo;
@property (nonatomic) ActionButtonInfo *deleteThDataButtonInfo;
@property (nonatomic) ActionButtonInfo *beginCopyButtonInfo;

@property (nonatomic) ActionButtonInfo *nextSearchButtonInfo;
@property (nonatomic) FavSelectFragment *favSelectFragment;

@property (nonatomic) ActionButtonInfo *titleCopyINfo;
@property (nonatomic) ActionButtonInfo *urlCopyInfo;
@property (nonatomic) ActionButtonInfo *allCopyInfo;
@property (nonatomic) ActionButtonInfo *selectCopyInfo;
@end

@implementation ThItemActionMenu

@synthesize thVm = _thVm;

- (void)dealloc
{

}

- (NSArray *)createAllButtons
{
    if (self.forCopy) {
        if (self.allCopyInfo == nil) {
            self.allCopyInfo = [[ActionButtonInfo alloc] initWithTitle:@"タイトル+URL" withImageName:@"copy_30.png"];
            self.titleCopyINfo = [[ActionButtonInfo alloc] initWithTitle:@"タイトル" withImageName:@"copy_30.png"];
            self.urlCopyInfo = [[ActionButtonInfo alloc] initWithTitle:@"URL" withImageName:@"copy_30.png"];
            self.selectCopyInfo = [[ActionButtonInfo alloc] initWithTitle:@"選択" withImageName:@"copy_30.png"];
        }

        return @[
            self.allCopyInfo,
            self.titleCopyINfo,
            self.urlCopyInfo,
            self.selectCopyInfo
        ];
    } else {

        if (self.moveBoardInfo == nil) {
            self.moveBoardInfo = [[ActionButtonInfo alloc] initWithTitle:@"板へ" withImageName:@"home2_30.png"];
            self.startEditButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"編集開始" withImageName:@"check_30.png"];
            self.deleteThDataButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"データ消去" withImageName:@"delete_30.png"];
            self.nextSearchButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"次スレ検索" withImageName:@"flash_light.png"];
            self.beginCopyButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"コピー" withImageName:@"copy_30.png"];
        }

        NSMutableArray *buttons = [NSMutableArray arrayWithArray:@[ self.moveBoardInfo, self.deleteThDataButtonInfo, self.beginCopyButtonInfo, self.nextSearchButtonInfo ]];

        if (self.canEdit) {
            [buttons addObject:self.startEditButtonInfo];
        }
        return buttons;
    }
}

// @override
- (void)onLayoutCompleted
{
    [self.favSelectFragment onLayoutCompleted];
}

- (NSArray *)createAboveViews
{
    if (self.forCopy == NO) {
        self.favSelectFragment = [[FavSelectFragment alloc] init];
        self.favSelectFragment.th = self.thVm.th;
        return @[ self.favSelectFragment.view ];
    }
    return nil;
}

- (ThVm *)thVm
{
    return _thVm;
}

- (void)setThVm:(ThVm *)thVm
{
    _thVm = thVm;
    [self.favSelectFragment changeTh:thVm.th];
}

- (void)onButtonTap:(ActionButtonInfo *)info
{
    [super changeButtonStyle:info asTouch:NO];

    if (info.button == self.moveBoardInfo.button) {
        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
          [[MySplitVC instance] closeActionMenu:nil complete:nil];

          ThListTransaction *thlistTransaction = [[ThListTransaction alloc] init];

          Board *board = [[BoardManager sharedManager] boardForTh:self.thVm.th];
          [thlistTransaction startOpenThListTransaction:board];
        });

    } else if (info.button == self.startEditButtonInfo.button) {
        [[MySplitVC instance] closeActionMenu:nil complete:nil];

        [self.thListBaseVC setEditing:YES animated:YES];
        if (self.indexPath) {
            UITableView *tableView = [self.thListBaseVC thisTableView];
            [tableView selectRowAtIndexPath:self.indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    } else if (info.button == self.deleteThDataButtonInfo.button) {
        if (self.thVm.th) {
            self.thVm.th.lastReadTime = 0;
            self.thVm.th.read = 0;
            self.thVm.th.localCount = 0;
            self.thVm.th.count = 0;
            [[HistoryVC sharedInstance] removeHistory:self.thVm.th];
            [[ThManager sharedManager] deleteThDataAsync:self.thVm.th];
            [self.thVm.th clearResponses];
        }
        [[MySplitVC instance] closeActionMenu:nil complete:nil];

    } else if (info.button == self.nextSearchButtonInfo.button) {

        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             ThListTransaction *thlistTransaction = [[ThListTransaction alloc] init];
                                             thlistTransaction.isNextSearch = YES;
                                             thlistTransaction.th = self.thVm.th;

                                             Board *board = [[BoardManager sharedManager] boardForTh:self.thVm.th];
                                             [thlistTransaction startOpenThListTransaction:board];
                                           }];
    } else if (info == self.beginCopyButtonInfo) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             ThItemActionMenu *thItemActionMenu = [[ThItemActionMenu alloc] init];

                                             thItemActionMenu.thListBaseVC = self.thListBaseVC;
                                             thItemActionMenu.isVerticalMode = YES;
                                             thItemActionMenu.thVm = self.thVm;
                                             thItemActionMenu.forCopy = YES;
                                             [thItemActionMenu build];
                                             [[MySplitVC instance] openActionMenu:thItemActionMenu];
                                           }];
    }

    if (self.forCopy) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             if (info == self.allCopyInfo) {
                                                 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                 pasteboard.string = [NSString stringWithFormat:@"%@\n%@", self.thVm.th.title, [self.thVm.th threadUrl]];

                                             } else if (info == self.titleCopyINfo) {
                                                 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                 pasteboard.string = self.thVm.th.title;
                                             } else if (info == self.urlCopyInfo) {
                                                 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                 pasteboard.string = [self.thVm.th threadUrl];
                                             } else if (info == self.selectCopyInfo) {
                                                 CopyVC *copyVc = [[CopyVC alloc] init];
                                                 copyVc.text = [NSString stringWithFormat:@"%@\n%@", self.thVm.th.title, [self.thVm.th threadUrl]];

                                                 UINavigationController *con = [copyVc wrapWithNavigationController];

                                                 [[MySplitVC instance] presentViewController:con
                                                                                         animated:YES
                                                                                       completion:^{
                                                                                       }];
                                             }
                                           }];
    }
}

@end
