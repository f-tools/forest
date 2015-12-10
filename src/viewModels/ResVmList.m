#import "ResVmList.h"
#import "ResVm.h"
#import "../models/nodes/ResNodeBase.h"
#import "../models/nodes/AnchorNode.h"
#import <SDWebImage/SDWebImageManager.h>

// ツリー対応
@interface ResVmList ()

@end

@implementation ResVmList

- (id)init
{
    if (self = [super init]) {
        _serializedResVmArray = [NSMutableArray array];
        _resVmMap = [NSMutableDictionary dictionary];
        _baseResVmMapForNew = [NSMutableDictionary dictionary];
        _treeResVmArray = [NSMutableArray array];
        _readMarkRow = -1;
        _treeMode = YES;
    }

    return self;
}

- (void)dealloc
{
    myLog(@"■delloc ResVmList %@", self.th.title);
    [self removeAllObjects];
}

- (void)removeAllObjects
{
    self.lastResNumber = 0; // このクラスの中で把握している最後のレス番号
    self.readMarkRow = -1;  // ここまで読んだマークの行インデックス

    if (self.serializedResVmArray) {
        [self.serializedResVmArray removeAllObjects];
    }

    if (self.resVmMap) {
        [self.resVmMap removeAllObjects];
    }

    if (self.baseResVmMapForNew) {
        [self.baseResVmMapForNew removeAllObjects];
    }

    if (self.treeResVmArray) {
        [self.treeResVmArray removeAllObjects];
    }
}

- (ResVm *)resVmAtIndex:(NSInteger)row
{

    NSInteger ind;
    if (self.readMarkRow != -1 && row == self.readMarkRow) {
        return nil;
    } else if (self.readMarkRow > -1 && row > self.readMarkRow) {
        ind = row - 1;
    } else {
        ind = row;
    }

    if (0 <= ind && ind < [self.serializedResVmArray count]) {
        return [self.serializedResVmArray objectAtIndex:ind];
    }

    myLog(@"Assert Error: index is out of range in serializedResVmArray");
    return nil;
}

- (NSInteger)endRow
{
    return [self count];
}

- (NSUInteger)count
{
    return [self.serializedResVmArray count] + (self.readMarkRow != -1 ? 1 : 0);
}

// 外部からここまで読んだ番号を変える場合に呼ばれる
// この後、addResListをよばれることを想定?
// さらに、reloadDataが呼ばれることも想定
- (void)changeReadMarkNumber:(NSInteger)num
{

    myLog(@"changeReadMarkNumber count = %lu", [self.serializedResVmArray count]);

    self.lastReadNumber = num;
    self.readMarkRow = -1;

    [self.baseResVmMapForNew removeAllObjects];
}

- (ResVm *)genResVmWithRes:(Res *)res
{
    ResVm *resVm = [[ResVm alloc] init];
    resVm.th = self.th;
    resVm.res = res;
    resVm.width = self.width;
    resVm.resVmList = self;

    if (res.number == self.highlightResNumber) {
        resVm.highlight = YES;
    }

    return resVm;
}

- (Res *)getResWithNumber:(NSInteger)number
{
    NSInteger ind = number - 1;
    Res *refRes = ind < [self.originalResArray count] ? [self.originalResArray objectAtIndex:ind] : nil;
    return refRes;
}

//一番下のセルの下線を引くかどうか
- (void)setBottomCellNoBottomLine:(BOOL)enabled
{

    NSUInteger count = [self.serializedResVmArray count];
    if (count > 0) {
        ResVm *last = [self.serializedResVmArray objectAtIndex:count - 1];
        last.noBottomLine = enabled;
    }
}

//レス全体タップ用
- (void)popupTree:(NSMutableArray *)resList targetResList:(NSArray *)targetResList
{
    self.originalResArray = resList;

    for (Res *targetRes in targetResList) {
        Res *refRes = targetRes;

        ResVm *descentResVm = [self belowResVmArray:refRes];

        for (ResNodeBase *node in refRes.bodyNodes) {
            if ([node isKindOfClass:[AnchorNode class]]) {
                AnchorNode *anchorNode = (AnchorNode *)node;
                for (NSInteger i = anchorNode.from; i <= anchorNode.to; i++) {
                    Res *res = [self getResWithNumber:i];
                    if (res) {
                        if (descentResVm) {
                            [self aboveResVmArray:descentResVm targetRes:res];
                            descentResVm = nil;
                        } else {
                            ResVm *resVm = [self genResVmWithRes:refRes];
                            resVm.res = refRes;

                            [self aboveResVmArray:resVm targetRes:res];
                        }
                    }
                }
            }
        }

        if ([self.treeResVmArray count] == 0) {
            [self.treeResVmArray addObject:descentResVm];
        }
    }

    @synchronized(self)
    {
        [self.serializedResVmArray removeAllObjects];
        [self serialize];
    }
}

// Top ResVm Arrayを返す
- (void)aboveResVmArray:(ResVm *)childResVm targetRes:(Res *)res
{
    ResVm *resVm = [self genResVmWithRes:res];
    [resVm addChild:childResVm];

    Res *targetAboveRes = nil;

    for (ResNodeBase *node in res.bodyNodes) {
        if ([node isKindOfClass:[AnchorNode class]]) {
            AnchorNode *anchorNode = (AnchorNode *)node;
            for (NSInteger i = anchorNode.from; i <= anchorNode.to; i++) {
                if (res.number > i) {
                    Res *res = [self getResWithNumber:i];
                    if (res && targetAboveRes == nil) {
                        targetAboveRes = res; //ひとつ見つかったら終わり
                        break;
                    }
                }
            }
        }
        if (targetAboveRes) break;
    }

    if (targetAboveRes) {
        [self aboveResVmArray:resVm targetRes:targetAboveRes];
    } else {
        [self.treeResVmArray addObject:resVm];
    }
}

- (ResVm *)belowResVmArray:(Res *)res
{
    ResVm *resVm = [self genResVmWithRes:res];

    if (res.refferedResSet) {
        for (NSNumber *number in res.refferedResSet) {
            NSInteger resNumber = [number integerValue];
            Res *childRes = [self getResWithNumber:resNumber];
            if (childRes) {
                [resVm addChild:[self belowResVmArray:childRes]];
            }
        }
    }

    return resVm;
}

- (void)addResList:(NSArray *)resList
{
    self.originalResArray = resList;
    [self reconstruct];
}

- (void)reconstruct
{
    if (self.treeMode == NO) {
        BOOL isReadkMarkInserted = self.lastReadNumber == [self.originalResArray count] || self.readMarkRow != -1 || self.lastReadNumber <= 1;

        for (Res *res in self.originalResArray) {
            if (self.lastResNumber >= res.number) {
                continue; //これいる？
            }
            ResVm *resVm = [self genResVmWithRes:res];
            resVm.originResNumber = res.number;

            self.lastResNumber = res.number;

            if (isReadkMarkInserted == NO && res.number > self.lastReadNumber) {
                self.readMarkRow = [self.serializedResVmArray count];
                isReadkMarkInserted = YES;
            }

            [self.serializedResVmArray addObject:resVm];
        }
        if (isReadkMarkInserted == NO) {
            NSUInteger count = [self.serializedResVmArray count];
            if (count > 0) {
                ResVm *lastVm = [self.serializedResVmArray objectAtIndex:count - 1];
                if (lastVm) {
                    self.readMarkRow = [self.serializedResVmArray count];
                }
            }
        }

        return;
    }

    for (Res *res in self.originalResArray) {
        if (self.lastResNumber >= res.number) {
            continue; //これいる？
        }
        self.lastResNumber = res.number;

        ResVm *resVm = [self genResVmWithRes:res];

        BOOL insertedIntoTopLevel = NO;

        id anchorClass = [AnchorNode class];
        BOOL isInserted = NO;
        BOOL isNewRes = self.lastReadNumber < res.number;

        for (ResNodeBase *node in res.bodyNodes) {
            if ([node isKindOfClass:anchorClass]) {
                AnchorNode *anchorNode = (AnchorNode *)node;
                for (NSInteger i = anchorNode.from; i <= anchorNode.to; i++) {
                    if (i >= res.number) continue;

                    if (i != 1) {
                        NSArray *list = [self.resVmMap objectForKey:[NSNumber numberWithInteger:i]];
                        if (list) {
                            for (ResVm *refResVm in list) {
                                BOOL isTargetNew = self.lastReadNumber < i;

                                if (isTargetNew == isNewRes) {
                                    resVm.originResNumber = refResVm.originResNumber;
                                    [refResVm addChild:resVm];

                                    isInserted = YES;
                                    break;
                                }
                            }
                        }
                    }
                    if (isInserted) break;

                    //すでに基板既読レスがある場合には、その子どもとして挿入
                    if (isNewRes) {
                        ResVm *refResVm = [self.baseResVmMapForNew objectForKey:[NSNumber numberWithInteger:i]];
                        if (refResVm) {
                            [refResVm addChild:(resVm)];
                            resVm.originResNumber = refResVm.originResNumber;
                            isInserted = YES;
                        }
                        break;
                    }
                }

                if (isInserted) break;
            }

            if (isInserted) break;
        }

        if (isInserted == NO) {
            if (isNewRes) {
                for (ResNodeBase *node in res.bodyNodes) {
                    if ([node isKindOfClass:anchorClass]) {
                        AnchorNode *anchorNode = (AnchorNode *)node;
                        for (NSInteger i = anchorNode.from; i <= anchorNode.to; i++) {
                            if (i >= res.number) continue;

                            //基板既読レスを生成して、その子どもとして挿入し、終了
                            Res *refRes = i - 1 < [self.originalResArray count] ? [self.originalResArray objectAtIndex:i - 1] : nil;
                            if (refRes && refRes.number != 1) {
                                ResVm *copy = [self genResVmWithRes:refRes];
                                [self addResVmToMap:copy];
                                copy.originResNumber = resVm.res.number;
                                resVm.originResNumber = copy.originResNumber;
                                copy.isReadBody = YES;
                                [copy addChild:(resVm)];
                                isInserted = YES;

                                [self.treeResVmArray addObject:copy];
                                [self.baseResVmMapForNew setObject:copy
                                                            forKey:[NSNumber numberWithInteger:i]];

                                break;
                            }
                        }
                    }

                    if (isInserted) break;
                }
            }
        }

        if (isInserted == NO) {
            resVm.originResNumber = resVm.res.number;
            [self.treeResVmArray addObject:resVm];
        }
//        else if (resVm.res.number == self.th.localCount) {
//
//            //ツリーの最後は最後のレスを表示する。
//            ResVm *lastTopLevelResVm = [self genResVmWithRes:res];
//            lastTopLevelResVm.originResNumber = res.number;
//            [self.treeResVmArray addObject:lastTopLevelResVm];
//            //[self addResVmToMap:lastTopLevelResVm];
//        }

        [self addResVmToMap:resVm];
    }

    @synchronized(self)
    {
        [self.serializedResVmArray removeAllObjects];
        [self serialize];
    }
}

- (BOOL)getTreeMode
{
    return _treeMode;
}

- (void)rebuild
{
    [self removeAllObjects];
    [self reconstruct];
}

- (void)addResVmToMap:(ResVm *)resVm
{
    NSNumber *number = [NSNumber numberWithInteger:resVm.res.number];
    NSMutableArray *list = [self.resVmMap objectForKey:number];
    if (list) {
        [list addObject:resVm];
    } else {
        list = [NSMutableArray array];
        [list addObject:resVm];
        [self.resVmMap setObject:list forKey:number];
    }
}

/**
 * ツリー表示時
 **/
- (NSInteger)rowAtOriginResNumber:(NSInteger)originResNumber
{
    @synchronized(self)
    {
        NSUInteger count = [self.serializedResVmArray count];
        for (NSInteger i = 0; i < count; i++) {
            ResVm *resVm = [self.serializedResVmArray objectAtIndex:i];
            if (resVm.originResNumber >= originResNumber) {
                return [self rowAtSerializedArrayIndex:i];
            }
        }
        return [self rowAtSerializedArrayIndex:count - 1];
    }
}

- (NSInteger)rowAtSerializedArrayIndex:(NSInteger)index
{
    
    if (self.readMarkRow != -1 && index > self.readMarkRow) {
        return index + 1;
    } else {
        return index;
    }
}

- (void)serialize
{
    BOOL isReadkMarkInserted = self.lastReadNumber == self.lastResNumber || self.readMarkRow != -1 || self.lastReadNumber <= 1;

    for (ResVm *resVm in self.treeResVmArray) {
        if (isReadkMarkInserted == NO && resVm.originResNumber > self.lastReadNumber) {
            //ここまで読んだマークを超えてたらその時点をreadMarkRowにする
            self.readMarkRow = [self.serializedResVmArray count];
            isReadkMarkInserted = YES;
        }

        [self.serializedResVmArray addObject:resVm];
        if (resVm.childs) {
            [self addChildsToSerializedArray:resVm.childs depth:1];
        }
    }

    if (isReadkMarkInserted == NO) {
        NSUInteger count = [self.treeResVmArray count];
        if (count > 0) {
            ResVm *lastVm = [self.treeResVmArray objectAtIndex:count - 1];
            if (lastVm) {
                if (lastVm.originResNumber <= self.lastReadNumber) {
                    self.readMarkRow = [self.serializedResVmArray count];
                }
            }
        }
    }

    //下線のための、下ResVmのDepth取得＆設定
    ResVm *prevResVm = nil;
    for (ResVm *resVm in self.serializedResVmArray) {
        if (prevResVm) {
            prevResVm.belowDepth = resVm.depth;
            prevResVm.nextResVm = resVm;
        }

        prevResVm = resVm;
    }
}

- (void)addChildsToSerializedArray:(NSArray *)childs depth:(int)depth
{
    for (ResVm *child in childs) {
        child.depth = depth;
        [self.serializedResVmArray addObject:child];
        if (child.childs) {
            [self addChildsToSerializedArray:child.childs depth:depth + 1];
        }
    }
}

- (void)makeNoTree
{
}

- (void)notifyResArrayAdded
{
}

@end
