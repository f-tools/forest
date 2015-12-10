#import "ThreadListParser.h"
#import "BBSItemBase.h"
#import "Th.h"
#import "TextUtils.h"

@implementation ThreadListParser

- (void)setBBSSubType:(BBSSubType)subType
{
    _subType = subType;
    _delimeter = (subType == BBSST_SHITARABA) ? @"," : @"<>";
    _delimeterLength = (int)[_delimeter length];
}

- (NSArray *)parse:(NSData *)data
{ //83928

    initCharRefMap();
    NSString *text = [TextUtils decodeString:data encoding:[BBSItemBase boardEncodingWithBBSSubType:_subType] substitution:@"?"];
    // したらば
    // http://jbbs.shitaraba.net/[カテゴリ]/[掲示板番号]/subject.txt
    // [スレッド番号].cgi,[スレッドタイトル](レス数)

    // Matchi
    // http://[SERVER]/bbs/offlaw.cgi/[BBS]/
    // スレ順位<>キー番号<>サブジェクト(レス数)[改行]
    NSUInteger length = [text length];
    unichar *chars = (unichar *)calloc(length, sizeof(unichar));
    [text getCharacters:chars range:NSMakeRange(0, length)];
    text = nil;
    data = nil;

    NSMutableArray *thList = [[NSMutableArray alloc] init];

    BOOL inKey = _subType != BBSST_MACHI;
    BOOL inTitle = NO;
    //    BOOL inCount = NO;
    BOOL inOrder = _subType == BBSST_MACHI;
    NSInteger titleStartIndex = 0;
    NSInteger titleEndIndex = 0;
    NSInteger countStartIndex = 0;
    NSInteger number = 1;

    Th *th = [[Th alloc] init];
    th.number = number++;

    NSMutableSet *thSet = [NSMutableSet set];

    int termBegin = 0;
    for (int i = 0; i < length; i++) {
        unichar letter = chars[i];
        if (inOrder) {
            if (![self isDigit:letter]) {
                inOrder = NO;
                NSString *order = [self substringOfCharacters:chars + termBegin length:i - termBegin];
                th.number = [order integerValue];
                order = nil;
                int indexOfDel = [self indexOf:chars length:length string:@"<>" index:i];
                if (indexOfDel != -1) {
                    i = indexOfDel + 1;
                    termBegin = i + 1;
                }
                inKey = YES;
            }

        } else if (inKey) {
            if (![self isDigit:letter]) {
                inKey = NO;
                NSString *key = [self substringOfCharacters:chars + termBegin length:i - termBegin];
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];

                NSNumber *num = [formatter numberFromString:key];

                th.key = [num unsignedLongLongValue];

                key = nil;
                NSString *del = _delimeter;
                int delimeterLength = _delimeterLength;
                int indexOfDel = [self indexOf:chars length:length string:del index:i];
                if (indexOfDel != -1) {
                    termBegin = indexOfDel + delimeterLength;
                    i = termBegin - 1;
                    titleStartIndex = termBegin;
                }
                inTitle = YES;
            }
        } else if (inTitle) {
            if (letter == '(') {
                titleEndIndex = i;
                countStartIndex = i + 1;
            } else if (letter == ')') {

                BOOL canTakeCount = NO;
                if (i + 1 == length) {
                    canTakeCount = YES;
                } else {
                    unichar nextChar = chars[i + 1];
                    if (nextChar == 0xA) {
                        canTakeCount = YES;
                    }
                }

                if (canTakeCount) {
                    th.title = [self translateReference:chars + titleStartIndex length:titleEndIndex - titleStartIndex];
                    inTitle = NO;
                    termBegin = i + 1;

                    NSString *countStr = [self substringOfCharacters:chars + countStartIndex length:i - countStartIndex];
                    th.count = [countStr integerValue];
                    countStr = nil;

                    if (![thSet member:[th threadUniqueKey]]) {
                        [thSet addObject:[th threadUniqueKey]];
                        [thList addObject:th];
                    }

                    th = [[Th alloc] init];
                    th.number = number++;
                    termBegin = i + 1;
                }
            }
        }

        if (letter == 0xA) {
            inKey = _subType != BBSST_MACHI;
            inOrder = _subType == BBSST_MACHI;
            termBegin = i + 1;
        }
    }

    free(chars);
    return thList;
}

@end
