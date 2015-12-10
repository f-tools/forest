//
//  BoardActionMenu.m
//  Forest
//

#import "BoardActionMenu.h"
#import "MyNavigationVC.h"
#import "ThListTransaction.h"
#import "BoardManager.h"
#import "ThManager.h"
#import "ActionLayout.h"
#import "ThemeManager.h"
#import "NextSearchVC.h"
#import "MySplitVC.h"
#import "FavSelectFragment.h"

@interface BoardActionMenu ()

@property (nonatomic) ActionButtonInfo *addFavInfo;
@property (nonatomic) ActionButtonInfo *createThreadInfo;
@property (nonatomic) ActionButtonInfo *deleteExternalBoardInfo;

@end

@implementation BoardActionMenu

- (void)dealloc
{
}

- (NSArray *)createAllButtons
{
    if (self.addFavInfo == nil) {
        self.addFavInfo = [[ActionButtonInfo alloc] initWithTitle:@"お気に入り" withImageName:@"star_gray_30.png"];
        self.deleteExternalBoardInfo = [[ActionButtonInfo alloc] initWithTitle:@"外部板削除" withImageName:@"delete_30.png"];
        self.createThreadInfo = [[ActionButtonInfo alloc] initWithTitle:@"スレッド作成" withImageName:@"file_30.png"];
    }

    NSMutableArray *buttons = [NSMutableArray arrayWithArray:@[ self.addFavInfo, self.createThreadInfo ]];
    BoardManager *bm = [BoardManager sharedManager];
    if ([bm containsExternalBoard:self.board]) {
        [buttons addObject:self.deleteExternalBoardInfo];
    }

    return buttons;
}

- (void)onLayoutCompleted
{
}

- (NSArray *)createAboveViews
{
    return nil;
}

- (void)onButtonTap:(ActionButtonInfo *)info
{
    [super changeButtonStyle:info asTouch:NO];

    if (info.button == self.addFavInfo.button) {
        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
          [[BoardManager sharedManager] addFavBoard:self.board];
          [[MySplitVC instance] closeActionMenu:nil
                                       complete:^{
                                       [self.boardVC reloadTable];
                                       }];

        });

    } else if (info == self.createThreadInfo) {
        [[MySplitVC instance] closeActionMenu:nil
                                     complete:^{

                                             PostNaviVC *postNaviVC = [[MySplitVC instance] sharedCreatePostNaviVC];
                                             postNaviVC.board = self.board;
                                             postNaviVC.onPostCompleted = ^(BOOL success) {

                                               ThListTransaction *thListTransaction = [[ThListTransaction alloc] init];
                                               [thListTransaction startOpenThListTransaction:self.board];

                                             };

                                             [[MySplitVC instance] presentViewController:postNaviVC
                                                                                     animated:YES
                                                                                   completion:^{

                                                                                   }];
                                           }];
    } else if (info == self.deleteExternalBoardInfo) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             [[BoardManager sharedManager] removeExternalBoard:self.board];
                                             [self.boardVC reloadTable];
                                           }];
    }

}

@end
