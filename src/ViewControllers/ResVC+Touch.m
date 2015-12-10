//
//  ResVC+Touch.m
//  Forest
//

#import "ResVC+Touch.h"
#import "LineBreakNode.h"

#import <QuartzCore/QuartzCore.h>
#import "DatParser.h"
#import "ResTableViewCell.h"
#import "TextUtils.h"
#import "ThUpdater.h"
#import "ResVmList.h"
#import "Th+ParseAdditions.h"
#import "AppDelegate.h"
#import "ThemeManager.h"
#import "ThManager.h"
#import "HistoryVC.h"
#import "FavVC.h"
#import "GestureManager.h"
#import "GestureEntry.h"
#import "TopWindow.h"
#import "ResNodeBase.h"
#import "Env.h"
#import "BaseModalNavigationVC.h"
#import "BaseTableVC.h"
#import "ResTransaction.h"
#import "ThListTransaction.h"
#import "ResActionMenu.h"
#import "ImagesPageViewController.h"
#import <SDWebImage/SDWebImageManager.h>
#import "SearchWebViewController.h"
#import "Views.h"
#import "MySplitVC.h"

static NSString *const kResTableViewCellIdentifier = @"ResTableViewCell";

#pragma mark - PopupEntry

@interface PopupEntry ()

@end


@implementation PopupEntry

- (id)init
{
    if (self = [super init]) {
        _tableView = [[ResTableView alloc] init];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
        [_tableView initFastTableView];

        [[ThemeManager sharedManager] changeTableViewStyle:_tableView];

        [_tableView registerClass:[ResTableViewCell class] forCellReuseIdentifier:kResTableViewCellIdentifier];

        _currentCellTag = 2;

        _resVmList = [[ResVmList alloc] init];
    }
    return self;
}

- (FastViewModelBase *)tableView:(FastTableView *)tableView vmAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.resVmList resVmAtIndex:indexPath.row];
}

- (UIView *)putView:(UIView *)view insideShadowWithColor:(UIColor *)color andRadius:(CGFloat)shadowRadius andOffset:(CGSize)shadowOffset andOpacity:(CGFloat)shadowOpacity
{
    CGRect shadowFrame;

    shadowFrame.size = CGSizeMake(view.frame.size.width, view.frame.size.height);

    shadowFrame.origin.x = 0.f;
    shadowFrame.origin.y = 0.f;
    UIView *shadow = [[UIView alloc] initWithFrame:view.frame];
    view.frame = CGRectMake([self extraWidth] / 2.f, [self extraHeight] / 2.f, view.frame.size.width - [self extraWidth], view .frame.size.height - [self extraHeight]);

    shadow.userInteractionEnabled = YES;
    // Shadowをつけると複数のポップアップを出したときに重くなる
    //    shadow.layer.shadowColor = color.CGColor;
    //    shadow.layer.shadowOffset = shadowOffset;
    //    shadow.layer.shadowRadius = shadowRadius;
    //    shadow.layer.masksToBounds = NO;
    shadow.clipsToBounds = NO;
    // shadow.layer.shadowOpacity = shadowOpacity;

    [shadow addSubview:view];
    return shadow;
}

- (void)setShadowEnabled:(BOOL)enabled
{
    //self.view.layer.shadowOpacity = enabled ? 1: 0;
}

- (NSUInteger)extraHeight
{
    return 7.5; // border top, border bottom
}
- (NSUInteger)extraWidth
{
    return 8; // border left, border right
}

- (void)setTarget:(ResVmList *)resVmList withTh:(Th *)th withRect:(CGRect)realRect
{
    self.th = th;
    self.resVmList = resVmList;
    self.tableView.frame = realRect;

    UIView *shadow = [self putView:self.tableView
             insideShadowWithColor:[UIColor blackColor]
                         andRadius:0.0
                         andOffset:CGSizeMake(0.0, 0.0)
                        andOpacity:1.0];

    //type:0 -> anchor tap
    //type:1 -> ID
    //type:2 -> resNum reffered
    //type:3 -> resName
    //type:4 -> cell whole
    //type:5 -> Extract
    shadow.layer.cornerRadius = 0.0;
    shadow.layer.borderColor = [[ThemeManager sharedManager] colorForKey:
                                                                 self.type == 1 ? ThemeResIDPopupBorderColor : (self.type == 5 ? ThemeResExtractPopupBorderColor : ThemeResPopupBorderColor)]
                                   .CGColor;
    shadow.backgroundColor = [[ThemeManager sharedManager] colorForKey:self.type == 1 ? ThemeResIDPopupMarginColor : (self.type == 5 ? ThemeResExtractPopupMarginColor : ThemeResPopupMarginColor)];

    shadow.layer.borderWidth = thinLineWidth;
    shadow.layer.masksToBounds = YES;

    self.view = shadow;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)rowCount
{
    NSUInteger inte = [self.resVmList count];
    return inte;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self rowCount];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ResVm *resVm = [self.resVmList resVmAtIndex:indexPath.row];

    ResTableViewCell *cell = (ResTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kResTableViewCellIdentifier];
    BOOL newCell = self.currentCellTag != cell.tag;
    if (newCell) {
        UIColor *backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

        [cell.resView setBackgroundColor:backgroundColor];
        [cell setBackgroundColor:backgroundColor];

        cell.tag = self.currentCellTag;
    }

    cell.resView.resVm = resVm;
    [cell.resView setFrame:resVm.frameRect];
    [cell.resView setNeedsDisplay];
    [cell.resView onCellShown];

    return cell;
}

@end

@interface ResVC (Po)

@end

@implementation ResVC (Popup)

#pragma mark - ポップアップ

- (void)popupWithResVmList:(ResVmList *)resVmList withCell:(ResTableViewCell *)cell withType:(NSInteger)type
{

    resVmList.highlightType = type;
    PopupEntry *popupEntry = [[PopupEntry alloc] init];
    popupEntry.odd = NO;

    if (self.currentPopupEntry) {
        popupEntry.ngOffMode = self.currentPopupEntry.ngOffMode;
        if (self.currentPopupEntry.ngOffMode) {
            resVmList.showNGRes = YES;
        }
        popupEntry.odd = !self.currentPopupEntry.odd;
    }

    [resVmList changeReadMarkNumber:self.th.read];

    popupEntry.type = type;
    NSUInteger extraHeight = [popupEntry extraHeight];
    NSUInteger popupExtraWidth = [popupEntry extraWidth];

    CGFloat tableViewHeight = self.tableView.bounds.size.height;
    NSUInteger criteriaHeight = tableViewHeight * 0.74;

    NSInteger panMargin = 4;
    NSInteger popupViewWidth = self.tableView.bounds.size.width - panMargin * 2;
    NSUInteger cellWidth = popupViewWidth - popupExtraWidth;

    [resVmList setBottomCellNoBottomLine:YES];

    // ポップアップのセルの高さを全て計算する。
    NSUInteger cellTotalHeight = 0;
    NSUInteger resVmCount = [resVmList count];
    NSInteger row = 0;
    UITableViewScrollPosition position = UITableViewScrollPositionTop;

    //ポップアップの高さを計算する. 全体の74％を超えたらもう計算する必要がない
    BOOL needToCalc = YES;
    NSUInteger popupHeight = 0;

    for (NSInteger i = 0; i < resVmCount; i++) {
        ResVm *resVm = [resVmList resVmAtIndex:i]; //
        resVm.priorCellWidth = cellWidth;
        if (needToCalc) {
            NSUInteger cellHeight = [resVm calcHeight];
            resVm.statusIndex = self.currentCellTag;
            cellTotalHeight += cellHeight; //0.5セパレーター

            if (cellTotalHeight + extraHeight > criteriaHeight) {
                needToCalc = NO;
                popupHeight = criteriaHeight;
                popupEntry.shouldScrollEnabled = YES;
            } else {
                popupHeight = cellTotalHeight + extraHeight;
            }
        }

        if (resVm.highlight) {
            if (resVmCount == 1) {
                resVm.highlight = NO;
            }
            row = i;
            if (i == resVmCount - 1) {
                position = UITableViewScrollPositionBottom;
            }
        }
    }

    if (popupEntry.shouldScrollEnabled == NO) {
        popupEntry.tableView.scrollEnabled = NO;
    }

    CGPoint offset = self.currentPopupEntry ? self.currentPopupEntry.tableView.contentOffset : (self.tableView.contentOffset);

    CGFloat offset2 = (self.currentPopupEntry ? self.currentPopupEntry.view.frame.origin.y : 0) + (cell ? cell.frame.origin.y : 0) - offset.y;
    CGFloat spaceHeight = offset2;

    CGRect realRect;
    if (spaceHeight > popupHeight) {
        realRect = CGRectMake(panMargin, self.tableView.frame.origin.y + 20 + spaceHeight - popupHeight, popupViewWidth, popupHeight);
    } else {
        if (popupHeight > criteriaHeight) {
        } else {
        }
        realRect = CGRectMake(panMargin, self.tableView.frame.origin.y + 21 + (popupEntry.odd ? 0 : 40), popupViewWidth, popupHeight);
    }

    [popupEntry setTarget:resVmList withTh:self.th withRect:realRect];
   

    popupEntry.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.7f, 0.7f);
    popupEntry.view.alpha = 0.0;

    [self.view addSubview:popupEntry.view];

    [popupEntry.tableView reloadTableViewAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                                          withOffset:0
                                          completion:^{
                                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                              [NSThread sleepForTimeInterval:0.152];
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                [self popupView:popupEntry.view];
                                                
                                                if (popupEntry.shouldScrollEnabled) {
                                                    [popupEntry.tableView flashScrollIndicators];
                                                    popupEntry.tableView.scrollEnabled = YES;
                                                }
                                                [popupEntry.tableView startBackgroundParse];

                                              });
                                            });
                                          }];

    if (self.currentPopupEntry) {
        [self.currentPopupEntry.tableView setUserInteractionEnabled:NO];
        self.currentPopupEntry.tableView.scrollEnabled = NO;
        [self.currentPopupEntry setShadowEnabled:NO];
        popupEntry.prev = self.currentPopupEntry;
    }

    self.tableView.scrollEnabled = NO;
    [self.tableView setUserInteractionEnabled:NO];
    self.currentPopupEntry = popupEntry;
}

- (void)popupCenterWithRes:(Res *)res
{
    ResVmList *resVmList = [[ResVmList alloc] init];
    resVmList.th = self.th;
    Res *highlightRes = res;
    if (highlightRes) {
        resVmList.highlightResNumber = highlightRes.number;
    }
    [resVmList setTreeMode:NO];
    [resVmList addResList:self.th.responses];

    [self popupWithResVmList:resVmList withCell:nil withType:4];
}

- (void)popupWithID:(NSString *)idStr withCell:cell highlightRes:(Res *)highlightRes
{
    ResVmList *resVmList = [[ResVmList alloc] init];
    resVmList.th = self.th;
    if (highlightRes) {
        resVmList.highlightResNumber = highlightRes.number;
    }
    [resVmList setTreeMode:NO];

    NSArray *numbers = [self.th.resListById objectForKey:idStr];
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (NSNumber *number in numbers) {
        NSInteger num = [number integerValue];
        Res *res = [self.th resAtNumber:num];

        if (res && [mutableArray containsObject:res] == NO) {
            [mutableArray addObject:res];
        }
    }

    [resVmList addResList:mutableArray];
    if ([resVmList count] == 1 && highlightRes) {
        return;
    }

    [self popupWithResVmList:resVmList withCell:cell withType:1];
}

- (void)popupWithNGRes:(Res *)res withCell:(ResTableViewCell *)cell
{
    ResVmList *resVmList = [[ResVmList alloc] init];
    resVmList.th = self.th;
    resVmList.showNGRes = YES;

    [resVmList setTreeMode:NO];
    [resVmList addResList:@[ res ]];

    [self popupWithResVmList:resVmList withCell:cell withType:4];
    self.currentPopupEntry.ngOffMode = YES;
}

//レス全体タップ用
- (void)popupWithRes:(NSArray *)resList withCell:(ResTableViewCell *)cell withType:(NSInteger)type
{
    if ([resList count] == 0) return;

    ResVmList *resVmList = [[ResVmList alloc] init];
    resVmList.th = self.th;
    resVmList.highlightResNumber = ((Res *)[resList objectAtIndex:0]).number;
    if (type == 0 && [Env getAnchorPopupTree] == NO) {
        [resVmList setTreeMode:NO];
        [resVmList addResList:resList];

    } else {
        [resVmList popupTree:self.th.responses targetResList:resList];
    }

    [self popupWithResVmList:resVmList withCell:cell withType:4];
}

- (void)popupView:(UIView *)view
{

    [UIView animateWithDuration:0.15
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.f, 1.f);
          view.alpha = 1;
        }
        completion:^(BOOL finished){
        }];
}

- (void)handleTouchBeganEvent:(UITouch *)touch
{
    UITableView *tableView = nil;

    self.downPopupEntry = nil;
    self.downCell = nil;

    CGPoint p = [touch locationInView:self.view];
    self.downPoint = p;

    if (self.currentPopupEntry) {
        PopupEntry *popupEntry = self.currentPopupEntry;
        while (popupEntry) {
            CGPoint tapLocatinoInTable = [touch locationInView:popupEntry.tableView];
            if (CGRectContainsPoint(popupEntry.tableView.bounds, tapLocatinoInTable)) {
                self.downPopupEntry = popupEntry;
                if (self.currentPopupEntry == popupEntry) {
                    tableView = popupEntry.tableView;
                }
                break;
            }
            popupEntry = popupEntry.prev;
        }
    } else {
        if (CGRectContainsPoint(self.view.bounds, p)) {
            tableView = self.tableView;
        }
    }

    self.canTap = YES;
    self.isEstablished = NO;

    if (tableView) {
        if (tableView.contentOffset.y < -tableView.contentInset.top) return;

        CGFloat contentOffsetWidthWindow = tableView.contentOffset.y + tableView.bounds.size.height;
        //BOOL leachToBottom = contentOffsetWidthWindow >= tableView.contentSize.height;
        BOOL exceed = tableView.contentSize.height > tableView.bounds.size.height ? contentOffsetWidthWindow > tableView.contentSize.height + self.tableView.contentInset.bottom : tableView.contentOffset.y > 0;

        if (exceed) return;

        if (tableView.isDecelerating) {
            return;
        }

        CGPoint point = [touch locationInView:tableView];
        NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:point];
        if (indexPath) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (cell) {
                self.downCell = cell;
            }
        }
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [NSThread sleepForTimeInterval:0.2];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.canTap) { // Established
            self.isEstablished = YES;
            [self onTapEstablished:touch];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              [NSThread sleepForTimeInterval:0.6];
              dispatch_async(dispatch_get_main_queue(), ^{
                if (self.canTap) {
                    [self onLongTap:touch];
                    self.canTap = NO;
                }
              });
            });
        }
      });
    });
}

- (void)onTapEstablished:(UITouch *)touch
{
    if (self.downCell) {
        if ([self.downCell isKindOfClass:[ResTableViewCell class]]) {
            ResTableViewCell *tableViewCell = (ResTableViewCell *)self.downCell;
            [tableViewCell.resView notifyTapEstablished:touch];
        }
    } else if (self.downPopupEntry) {
    }
}

// Resタップした時の実装
- (void)onTapResNode:(ResNodeBase *)node cell:(ResTableViewCell *)cell
{
    ResVm *resVm = cell.resView.resVm;
    if (node) {
        if ([node isKindOfClass:[ThumbnailInfo class]]) {
            ThumbnailInfo *info = (ThumbnailInfo *)node;
            NSInteger index = 0;
            NSMutableArray *thumbnails = [NSMutableArray array];
            NSInteger i = 0;
            BOOL hit = false;
            for (ResNodeBase *node in resVm.res.bodyNodes) {
                if ([node isKindOfClass:[LinkNode class]]) {
                    LinkNode *linkNode = (LinkNode *)node;
                    if ([linkNode isImageLink]) {
                        NSString *url = [linkNode getUrl];
                        [thumbnails addObject:url];
                        if ([info.url isEqualToString:url]) {
                            hit = true;
                            index = i;
                        }
                        i++;
                    }
                }
            }
            if (hit == false) {
                [thumbnails addObject:info.url];
                // thumbnails = @[info.url];
            }

            self.imageViewVC = [[ImagesPageViewController alloc] initWithImageUrls:thumbnails];
            [self.imageViewVC showFromIndex:index];

        } else if ([node isKindOfClass:[NSNumber class]]) {
            NSNumber *number = (NSNumber *)node;
            NSInteger headerNum = [number integerValue];

            if (headerNum == kResNumberArea) { // Res Number
                if (resVm.res.refferedResSet) {
                    NSMutableArray *mutableArray = [NSMutableArray array];
                    NSArray *sortedResNums = [[resVm.res.refferedResSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                      return [obj1 compare:obj2];

                    }];

                    for (NSNumber *number in sortedResNums) {
                        NSInteger resNumber = [number integerValue];
                        myLog(@"resNumber in ref = %lu", resNumber);

                        Res *childRes = [self.th resAtNumber:resNumber];
                        if (childRes) {
                            [mutableArray addObject:childRes];
                        }
                    }

                    ResVmList *resVmList = [[ResVmList alloc] init];
                    resVmList.th = self.th;
                    [resVmList setTreeMode:NO];
                    [resVmList addResList:mutableArray];

                    [self popupWithResVmList:resVmList withCell:cell withType:2];
                }

            } else if (headerNum == kResNameArea) { // Res Name
                NSMutableArray *mutableArray = [NSMutableArray array];
                for (Res *res in self.th.responses) {
                    if ([res.name isEqualToString:resVm.res.name]) {
                        [mutableArray addObject:res];
                    }
                }
                if ([mutableArray count] > 0) {
                    ResVmList *resVmList = [[ResVmList alloc] init];
                    resVmList.th = self.th;
                    resVmList.highlightResNumber = resVm.res.number;

                    [resVmList setTreeMode:NO];
                    [resVmList addResList:mutableArray];

                    [self popupWithResVmList:resVmList withCell:cell withType:3];
                }

            } else if (headerNum == kResIDArea) { // Res ID
                [self popupWithID:resVm.res.ID withCell:cell highlightRes:resVm.res];

            } else if (headerNum == kResNGReasonArea) { // NG Reason Text
                //NGの編集または消去機能の提供
                ResActionMenu *actionMenu = [[ResActionMenu alloc] init];
                actionMenu.forNGItem = YES;
                actionMenu.ngItem = resVm.res.ngItem;
                actionMenu.resVC = self;

                [actionMenu build];
                [actionMenu open];
            }
        } else if ([node isKindOfClass:[AnchorNode class]]) {
            AnchorNode *anchorNode = (AnchorNode *)node;
            NSMutableArray *mutableArray = [NSMutableArray array];
            for (NSInteger i = anchorNode.from; i <= anchorNode.to; i++) {
                Res *res = [self.th resAtNumber:i];
                if (res && [mutableArray containsObject:res] == NO) {
                    [mutableArray addObject:res];
                }
            }

            //アンカーポップアップ
            // resVm.resを中心としたポップアップ //自分自身は含まない
            [self popupWithRes:mutableArray withCell:cell withType:0];

        } else if ([node isKindOfClass:[LinkNode class]]) {
            //スレを新しく開くか外部ブラウザで開く
            LinkNode *linkNode = (LinkNode *)node;
            Th *th = [Th thFromUrl:[linkNode getUrl]];

            if (th) {
                th = [[ThManager sharedManager] registerTh:th];
                ResTransaction *man = [[ResTransaction alloc] init];
                man.th = th;
                if ([man startOpenThTransaction]) {
                }

            } else {
                [[ThManager sharedManager] saveThAsync:self.th];
                BaseModalNavigationVC *nav = (BaseModalNavigationVC *)self.navigationController;
                [nav openUrlInDefaultWay:[linkNode getUrl]];
            }
        } else if ([node isKindOfClass:[IDNode class]]) {
            //ID抽出でポップアップ
            IDNode *idNode = (IDNode *)node;
            [self popupWithID:idNode.idText withCell:cell highlightRes:nil];
        }
    } else { //Res全体をタップ
        // ポップアップ
        if (resVm.res.ngItem && (self.currentPopupEntry == nil || self.currentPopupEntry.ngOffMode == NO)) {
            [self popupWithNGRes:resVm.res withCell:cell];
        } else {
            [self popupWithRes:@[ resVm.res ] withCell:cell withType:4];
        }
    }
}

// Resロングタップした時の実装
- (void)onLongTap:(UITouch *)touch
{
    if (self.downCell) {
        if ([self.downCell isKindOfClass:[ResTableViewCell class]]) {
            ResTableViewCell *tableViewCell = (ResTableViewCell *)self.downCell;
            ResNodeBase *node = [tableViewCell.resView notifyLongTap:touch];

            //長押し動作
            ResVm *resVm = tableViewCell.resView.resVm;
            if (node) {

                if ([node isKindOfClass:[ThumbnailInfo class]]) {
                    ThumbnailInfo *info = (ThumbnailInfo *)node;

                    ResActionMenu *actionMenu = [[ResActionMenu alloc] init];
                    actionMenu.forThumbnail = YES;
                    actionMenu.thumbnailInfo = info;
                    actionMenu.res = resVm.res;
                    actionMenu.resVC = self;

                    [actionMenu build];
                    [actionMenu open];

                } else if ([node isKindOfClass:[NSNumber class]]) {
                    NSNumber *number = (NSNumber *)node;
                    NSInteger headerNum = [number integerValue];
                    if (headerNum == kResNumberArea) { // Res Number

                    } else if (headerNum == kResIDArea) { //NGID of res
                        ResActionMenu *actionMenu = [[ResActionMenu alloc] init];
                        actionMenu.forID = YES;
                        actionMenu.res = resVm.res;
                        actionMenu.resVC = self;

                        [actionMenu build];
                        [actionMenu open];
                    } else if (headerNum == kResNGReasonArea) { //NG Reason Text
                    }

                } else if ([node isKindOfClass:[LinkNode class]]) {
                    //スレを新しく開くか外部ブラウザで開く
                    LinkNode *linkNode = (LinkNode *)node;
                    ResActionMenu *actionMenu = [[ResActionMenu alloc] init];
                    actionMenu.forLink = YES;
                    actionMenu.linkUrl = [linkNode getUrl];
                    actionMenu.res = resVm.res;
                    actionMenu.resVC = self;

                    [actionMenu build];
                    [actionMenu open];
                }
            } else {
                ResActionMenu *actionMenu = [[ResActionMenu alloc] init];
                actionMenu.forAll = YES;

                actionMenu.res = resVm.res;
                actionMenu.resVC = self;

                [actionMenu build];
                [actionMenu open];
            }
        }
    } else if (self.downPopupEntry) {

    }
}

- (void)handleTouchEndedEvent:(UITouch *)touch
{
    if (self.canTap) {
        self.canTap = NO;
        if ([MySplitVC instance].isActionMenuOpen) {

        } else if (self.downCell && (self.currentPopupEntry == nil || self.currentPopupEntry == self.downPopupEntry)) {
            // セル有効タップ
            if ([self.downCell isKindOfClass:[ResTableViewCell class]]) {
                ResTableViewCell *cell = (ResTableViewCell *)self.downCell;
                //CGPoint pointInCell = [touch locationInView:cell];
                ResNodeBase *node = [cell.resView notifyTap:touch];
                [self onTapResNode:node cell:cell];
            }

        } else if (self.currentPopupEntry) {
            // 外タップ >> ポップアップ消去
            [self closeOnePopupEntry:self.downPopupEntry oneMode:NO];
        }
    }
}

- (void)closeOnePopupEntry:(PopupEntry *)stopPopupEntry oneMode:(BOOL)oneMode
{
    PopupEntry *targetPopupEntry = self.currentPopupEntry;

    while (targetPopupEntry) {
        if (targetPopupEntry == stopPopupEntry) {
            break;
        }

        [self closePopupEntry:targetPopupEntry];

        targetPopupEntry = targetPopupEntry.prev;
        self.currentPopupEntry = targetPopupEntry;

        if (oneMode) {
            break;
        }
    }

    if (targetPopupEntry) {
        [targetPopupEntry setShadowEnabled:YES];
        if (targetPopupEntry.shouldScrollEnabled) {
            targetPopupEntry.tableView.scrollEnabled = YES;
        }
        [targetPopupEntry.tableView setUserInteractionEnabled:YES];
    } else {

        self.tableView.scrollEnabled = YES;
        [self.tableView setUserInteractionEnabled:YES];
    }
}

- (void)closePopupEntry:(PopupEntry *)targetPopupEntry
{
    PopupEntry *closePopupEntry = targetPopupEntry;
    [UIView animateWithDuration:0.1
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          closePopupEntry.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.7f, 0.7f);
          closePopupEntry.view.alpha = 0.0;
        }
        completion:^(BOOL finished) {
          [closePopupEntry.view removeFromSuperview];
        }];
}

- (void)handleTouchMovedEvent:(UITouch *)touch
{
    if (self.canTap) {
        CGPoint p = [touch locationInView:self.view];

        CGFloat a = CGPointDistance(p, self.downPoint);
        if (a > 10) {
            self.canTap = NO;
            if (self.isEstablished && [self.downCell isKindOfClass:[ResTableViewCell class]]) {
                self.isEstablished = NO;
                [((ResTableViewCell *)self.downCell).resView notifyTapCancel:touch];
            }
        }
    }
}

CGFloat CGPointDistance(CGPoint p1, CGPoint p2)
{
    return sqrtf((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
}

- (void)handleTouchCanceledEvent:(UITouch *)touch
{
    if (self.canTap && self.downCell) {
        self.canTap = NO;
        if ([self.downCell isKindOfClass:[ResTableViewCell class]]) {
            [((ResTableViewCell *)self.downCell).resView notifyTapCancel:touch];
        }
    }
}

- (IBAction)backButtonAction:(id)sender
{
    if (self.currentPopupEntry) {
        [self closeAllPopup];
        return;
    }

    if (self.cannotBack) {
        return;
    }

    [[MyNavigationVC instance] popViewControllerAnimated:YES];
}


#pragma Search / Extract

//searchTapAction
- (IBAction)refreshTapAction:(id)sender
{
    if (self.currentPopupEntry) {
        [self closeAllPopup];
        return;
    }

    self.isSearchMode = YES;

    UIBarButtonItem *addNewButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelBarButton:)];

   UINavigationItem *navigationItem = [MyNavigationVC instance].tabletContentVC.navigationItem;
    if(navigationItem == nil) {
        navigationItem = self.navigationItem;
    }
    
    navigationItem.rightBarButtonItem = addNewButton;

    UISearchBar *searchBar = [[UISearchBar alloc] init];

    self.searchCountLabel.text = [NSString stringWithFormat:@"_ 件"];

    UIColor *tabBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
    UIColor *mainBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    UIColor *tabBorderColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    UIColor *normalColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    UIColor *tableSeparatorColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];

    self.searchCountLabel.textColor = normalColor;
    self.searchCountDescriptionLabel.textColor = normalColor;
    self.searchHistoryTableView.backgroundColor = mainBackgroundColor;
    self.searchHistoryTableView.separatorColor = tableSeparatorColor;

    //    self.view.backgroundColor = mainBackgroundColor;
    self.searchContainerView.backgroundColor = mainBackgroundColor;

    self.searchTopBorder.backgroundColor = tabBorderColor;
    self.topBorder.backgroundColor = tabBorderColor;
    self.bottomBorder2.backgroundColor = tabBorderColor;
    self.bottomBorder.backgroundColor = tabBorderColor;

    self.rightSeparator.backgroundColor = tabBorderColor;
    self.leftSeparator.backgroundColor = tabBorderColor;
    self.centerSeparator1.backgroundColor = tabBorderColor;
    self.centerSeparator2.backgroundColor = tabBorderColor;

    self.otherExtractButton.backgroundColor = tabBackgroundColor;
    self.popularExtractButton.backgroundColor = tabBackgroundColor;
    self.linkExtractButton.backgroundColor = tabBackgroundColor;
    self.imageExtractButton.backgroundColor = tabBackgroundColor;
    self.clearHistoryExtractButton.backgroundColor = tabBackgroundColor;
    self.closeExtractButton.backgroundColor = tabBackgroundColor;

    [self.otherExtractButton setEnabled:NO];

    [self.popularExtractButton addTarget:self action:@selector(popularClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageExtractButton addTarget:self action:@selector(imageClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.linkExtractButton addTarget:self action:@selector(linkClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeExtractButton addTarget:self action:@selector(closeClicked:) forControlEvents:UIControlEventTouchUpInside];

    searchBar.delegate = self;
    [searchBar becomeFirstResponder];

    navigationItem.titleView = searchBar;

    [Views customKeyboardOnSearchBar:searchBar withKeyboardAppearance:[[ThemeManager sharedManager] useBlackKeyboard] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceDefault];

    navigationItem.titleView.frame = CGRectMake(0, 0, 320, 44);

    self.searchContainerView.hidden = NO;
    self.searchContainerView.alpha = 0.f;

    [UIView animateWithDuration:0.2
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.searchContainerView.alpha = 1.;
        }
        completion:^(BOOL finished){
            // [self.searchContainerView setNeedsDisplay];
        }];

    [[MyNavigationVC instance] setNavigationBarHidden:NO animated:YES];
}

- (IBAction)popularClicked:(id)sender
{
    [self closeSearchMode:^{
      NSMutableArray *mutableArray = [NSMutableArray array];
      for (Res *res in self.th.responses) {
          if (res.refferedResSet && [res.refferedResSet count] > 2) {
              [mutableArray addObject:res];
          }
      }

      [self popupWithExtractResList:mutableArray];
    }];
}

- (void)popupWithExtractResList:(NSArray *)resList
{
    if ([resList count] > 0) {
        ResVmList *resVmList = [[ResVmList alloc] init];
        resVmList.th = self.th;

        [resVmList setTreeMode:NO];
        [resVmList addResList:resList];

        [self popupWithResVmList:resVmList withCell:nil withType:5];
    }
}

- (IBAction)imageClicked:(id)sender
{
    [self closeSearchMode:^{
      NSMutableArray *mutableArray = [NSMutableArray array];
      for (Res *res in self.th.responses) {
          [res checkHasImage];
          if (res.hasImage) {
              [mutableArray addObject:res];
          }
      }

      [self popupWithExtractResList:mutableArray];
    }];
}

- (IBAction)linkClicked:(id)sender
{
    [self closeSearchMode:^{
      NSMutableArray *mutableArray = [NSMutableArray array];
      for (Res *res in self.th.responses) {
          if ([res hasLink]) {
              [mutableArray addObject:res];
          }
      }

      [self popupWithExtractResList:mutableArray];
    }];
}

- (IBAction)closeClicked:(id)sender
{
    [self closeSearchMode:nil];
}

- (void)onCancelBarButton:(id)sender
{
    [self closeSearchMode:nil];
}

- (void)closeSearchMode:(void (^)(void))completionBlock
{
    if (self.isSearchMode == NO) return;

    self.isSearchMode = NO;

    [[MyNavigationVC instance] setNavigationBarHidden:YES animated:YES];

    UISearchBar *searchBar = (UISearchBar *)self.navigationItem.titleView;
    [searchBar resignFirstResponder];

    self.navigationItem.titleView = nil;

    [UIView animateWithDuration:0.27
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.searchContainerView.alpha = 0.;
        }
        completion:^(BOOL finished) {
          self.searchContainerView.hidden = YES;
          if (completionBlock) {
              completionBlock();
          }

        }];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //該当件数の計算を非同期で行いラベルに表示する。
    self.currentSearchTag++;
    NSInteger checkTag = self.currentSearchTag;

    self.searchCountLabel.text = [NSString stringWithFormat:@"_ 件"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSInteger hitCount = 0;
      NSString *searchText2 = [searchText uppercaseString];
      for (Res *res in self.th.responses) {
          if (checkTag != self.currentSearchTag) {
              return;
          }

          NSString *text = [[res naturalText] uppercaseString];
          if (text && [TextUtils ambiguitySearchText:text searchKey:searchText2]) {
              hitCount++;
          }
      }

      dispatch_async(dispatch_get_main_queue(), ^{
        if (checkTag != self.currentSearchTag) {
            return;
        }
        self.searchCountLabel.text = [NSString stringWithFormat:@"%zd 件", hitCount];
      });
    });
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self closeSearchMode:^{
    }];
}

//文字選択から呼ばれる
- (void)startSearchWithText:(NSString *)searchText
{
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (Res *res in self.th.responses) {
        NSString *text = [[res naturalText] uppercaseString];

        if (text && [TextUtils ambiguitySearchText:text searchKey:searchText]) {
            [mutableArray addObject:res];
        }
    }

    if ([mutableArray count] > 0) {
        ResVmList *resVmList = [[ResVmList alloc] init];
        resVmList.th = self.th;

        [resVmList setTreeMode:NO];
        [resVmList addResList:mutableArray];

        [self popupWithResVmList:resVmList withCell:nil withType:5];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSString *searchText = [searchBar.text uppercaseString];
    [self closeSearchMode:^{
      [self startSearchWithText:searchText];
    }];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
}

@end
