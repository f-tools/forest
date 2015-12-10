#import "ThUpdater.h"
#import "Env.h"
#import "TextUtils.h"
#import "DatParser.h"
#import "NGManager.h"

#import "Th+ParseAdditions.h"

@implementation Th (ParseAdditions)

// レスを追加する。

// スレッドセーフじゃない。
// ローカルファイルを読み込むときも、ネットワークから読み込むときも
// 外部からスレッドを管理し、同時にこのメソッドを呼ばないようにする。
// res.numberが適切に設定されていることが前提。
- (void)addRes:(Res *)res
{

    //被参照レスをMutableSetなrefferedResListへ追加する。
    NSUInteger count = [self.responses count];

    NSUInteger limit = 0;

    //タイトルの更新
    if (res.number == 1 && res.threadTitle != nil) {
        self.title = res.threadTitle;
    }

    if (res.isMine == NO) {
        if ([self.myResNumSet member:[NSNumber numberWithInteger:res.number]]) {
            res.isMine = YES;
        } else {
            if ([Env getAutoMarkEnabled]) {
                BOOL isMyRes = [self checkMyRes:res];
                if (isMyRes) {
                    res.isMine = YES;
                    if (self.myResNumSet == nil) {
                        self.myResNumSet = [NSMutableSet set];
                    }
                    [self.myResNumSet addObject:[NSNumber numberWithInteger:res.number]];
                }
            }
        }
    }

    for (ResNodeBase *node in res.bodyNodes) {
        if ([node isKindOfClass:[AnchorNode class]]) {
            AnchorNode *anchorNode = (AnchorNode *)node;
            for (NSInteger i = anchorNode.from; i <= anchorNode.to; i++) {
                NSInteger targetIndex = i - 1;
                if (targetIndex < count == NO) {
                    continue;
                }

                Res *targetRes = [self.responses objectAtIndex:targetIndex];
                if (targetRes && limit++ < 7) {
                    if (targetRes.isMine) {
                        res.resToMe = YES;
                    }
                    if (targetRes.refferedResSet == nil) {
                        targetRes.refferedResSet = [NSMutableSet set];
                    }
                    NSNumber *n = [NSNumber numberWithInteger:res.number];
                    if ([targetRes.refferedResSet member:n] == nil) {
                        [targetRes.refferedResSet addObject:n];
                    }
                }
            }
        }
    }

    @synchronized(self.responses)
    {
        if (self.shouldResAdded) {

            //同IDのレスをTh.resListByIdへ追加する
            if (res.ID && [res.ID length] > 4) {
                NSMutableArray *resListForID = [self.resListById objectForKey:res.ID];
                NSNumber *num = [NSNumber numberWithInteger:res.number];
                if (resListForID) {
                    if (![resListForID containsObject:num]) {
                        res.idOrder = [resListForID count];
                        [resListForID addObject:num];
                    }
                } else {
                    resListForID = [[NSMutableArray alloc] init];
                    [resListForID addObject:num];
                    res.idOrder = 0;
                    [self.resListById setObject:resListForID forKey:res.ID];
                }
            }

            NSUInteger insertIndex = res.number - 1;
            if (insertIndex == count) {
                [self.responses addObject:res];

                return;
            }

            if (res.number > 0) {
                if (count <= insertIndex) {
                    for (NSInteger i = count; i <= insertIndex; i++) {
                        Res *dummyRes = [[Res alloc] init];
                        dummyRes.isDummy = YES;
                        dummyRes.number = (int)(i + 1);
                        [self.responses insertObject:dummyRes atIndex:i];
                    }
                }

                [self.responses replaceObjectAtIndex:insertIndex withObject:res];
                //[self.responses insertObject:res atIndex:insertIndex];
            }
        }
    }
}

- (BOOL)checkMyRes:(Res *)res
{
    if (self.lastPostText) {
        NSArray *lines = [[res naturalTextForCheckMyRes] componentsSeparatedByString:@"\n"];
        NSArray *lines2 = [[self.lastPostText stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]] componentsSeparatedByString:@"\n"];

        if (lines == nil || lines2 == nil || [lines count] != [lines2 count]) {
            return NO;
        }

        NSInteger index = 0;
        for (NSString *line in lines) {
            if (![line isEqualToString:[lines2 objectAtIndex:index++]]) {
                return NO;
            }
        }
        self.lastPostText = nil;
        return YES;
    }
    return NO;
}

// 手動で自分の書き込みを変えた時の処理
- (void)updateMyResInfo:(Res *)res isMine:(BOOL)isMine
{
    res.isMine = isMine;

    if (isMine) {
        [self.myResNumSet addObject:[NSNumber numberWithInteger:res.number]];
    } else {
        [self.myResNumSet removeObject:[NSNumber numberWithInteger:res.number]];
    }

    // 後方更新
    for (NSNumber *fromNumber in res.refferedResSet) {
        Res *fromRes = [self.responses objectAtIndex:[fromNumber integerValue] - 1];
        ;
        if (fromRes) {
            fromRes.resToMe = res.isMine;
        }
    }
}

- (void)checkNG:(Res *)res
{
    @synchronized(self.responses)
    {
        res.ngItem = [self.resNGInspector inspectRes:res];
        res.ngChecked = YES;

        if (res.ngItem == nil) {
            for (ResNodeBase *node in res.bodyNodes) {
                if ([node isKindOfClass:[AnchorNode class]]) {
                    AnchorNode *anchorNode = (AnchorNode *)node;
                    if (anchorNode.to - anchorNode.from > 10 || anchorNode.to < anchorNode.from) {
                        continue;
                    }

                    for (NSInteger i = anchorNode.from; i <= anchorNode.to; i++) {
                        NSInteger targetIndex = i - 1;
                        if (targetIndex < [self.responses count] == NO) {
                            continue;
                        }

                        Res *targetRes = [self.responses objectAtIndex:targetIndex];

                        if (targetRes && targetRes != res) {
                            if (targetRes.ngChecked == NO) {
                                [self checkNG:targetRes];
                            }

                            if (targetRes.ngItem && targetRes.ngItem.chain) {
                                //連鎖成功
                                // 一つでもNGだったら自分もNGにしてbreak;
                                res.ngItem = targetRes.ngItem;
                                res.ngChecked = YES;
                                break;
                            }
                        }
                    }
                    if (res.ngItem)
                        break;
                }
            }

            // 被参照カウントの修正(減少の可能性あり)
            if (res.refferedResSet && [res.refferedResSet count] > 0) {
                for (NSNumber *refResNumber in [res.refferedResSet allObjects]) {
                    if ([refResNumber integerValue] - 1 < [self.responses count]) {
                        Res *targetRes = [self.responses objectAtIndex:[refResNumber integerValue] - 1];
                        if (targetRes == nil) {
                            continue;
                        }

                        if (targetRes.ngChecked == NO) {
                            [self checkNG:targetRes];
                            targetRes.ngChecked = YES;
                        }

                        if (targetRes.ngItem) {
                            [res.refferedResSet removeObject:refResNumber];
                        } else {
                            if (![res.refferedResSet member:refResNumber]) {
                                [res.refferedResSet addObject:refResNumber];
                            }
                        }
                    }
                }
            }
        }
    }
}

- (void)clearResponses
{
    @synchronized(self.responses)
    {
        self.shouldResAdded = NO;
        if (self.responses) {
            [self.responses removeAllObjects];
        } else {
            self.responses = [NSMutableArray array];
        }
        [self.resListById removeAllObjects];
    }
}

- (BOOL)existsDatFile
{
    NSString *datFilePath = [self datFilePath:NO];
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:datFilePath];
}

- (NSString *)strFromFilepath:(NSString *)datFilePath
{
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:datFilePath];
    NSData *databuffer = [file readDataToEndOfFile];
    [file closeFile];

    NSString *str = [TextUtils decodeString:databuffer encoding:[self boardEncoding] substitution:@"?"];
    databuffer = nil;

    return str;
}

- (void)loadResponsesFromLocalFile
{
    @synchronized(self.responses)
    {
        @synchronized(self)
        {
            if (self.shouldResAdded) {
                return;
            }
            self.shouldResAdded = YES;
        }

        //[self clearResponses];

        if ([self existsDatFile] == NO) return;

        NSString *datFilePath = [self datFilePath:NO];

        DatParser *datParser = [[DatParser alloc] init];

        [datParser setBBSSubType:[self getBBSSubType]];

        NSString *str = [self strFromFilepath:datFilePath];

        NSArray *resList = [datParser parse:str offset:0];

        BOOL hasNumber = [self isShitaraba] || [self isMachiBBS];
        int setResNumber = 1; //self.localCount;
        int maxResNumber = 0;
        for (Res *res in resList) {

            if (hasNumber == NO) {
                res.number = setResNumber++;
            }
            if (maxResNumber < res.number) {
                maxResNumber = res.number;
            }
            [self addRes:res];
        }

        self.localCount = maxResNumber;
        if (maxResNumber > self.count) {
            self.count = maxResNumber;
        }
    }
}
@end
