#import "DatParser.h"

/**
 * 
 * Scannerの連続でテキストを解析していく。
 * 高速化のため正規表現の利用は最小限に抑える
 *
 **/

@implementation ScanContext
- (id)init
{
    if (self = [super init]) {
        self->referScanner = [[ReferScanner alloc] init];
        self->tagScanner = [[TagScanner alloc] init];
        self->idScanner = [[IDScanner alloc] init];
        self->urlScanner = [[URLScanner alloc] init];

        NSString *zSpace = @"　";
        NSUInteger length = [zSpace length];
        unichar chars2[length];
        [zSpace getCharacters:chars2 range:NSMakeRange(0, length)];
        self->firstOfSpace = chars2[0];
        self->secondOfSpace = chars2[1];
    }
    return self;
}
@end

@implementation DatParser

- (id)init
{
    if (self = [super init]) {
        self->_context = [[ScanContext alloc] init];
    }
    initCharRefMap();
    return self;
}

- (void)setBBSSubType:(BBSSubType)subType
{
    _subType = subType;

    // 2ch
    // [名前]<>[メール]<>[日付] [ID] [BE-ID]<>[本文]<>[スレッドタイトル]

    // まち
    // [レス番号]<>[名前]<>[メール]<>[日付] [ID] [BE-ID]<>[本文]<>[スレッドタイトル]

    // したらば
    // [レス番号]<>[名前]<>[メール]<>[日付]<>[本文]<>[スレッドタイトル]<>[ID]

    // トップレベルのスキャナーを順番通りにつなげる
    ResNumberScanner *resNumScanner = [[ResNumberScanner alloc] init];
    NameScanner *nameScanner = [[NameScanner alloc] init];
    MailScanner *mailScanner = [[MailScanner alloc] init];
    BodyScanner *bodyScanner = [[BodyScanner alloc] init];
    DateScanner *dateScanner = [[DateScanner alloc] init];
    TitleScanner *titleScanner = [[TitleScanner alloc] init];

    _context->firstScanner = (subType == BBSST_2CH_COMP) ? nameScanner : resNumScanner;

    resNumScanner->nextScanner = nameScanner;
    nameScanner->nextScanner = mailScanner;
    mailScanner->nextScanner = dateScanner;
    dateScanner->nextScanner = bodyScanner;
    bodyScanner->nextScanner = titleScanner;

    if (subType == BBSST_SHITARABA) {
        ShitarabaIDScanner *idScanner = [[ShitarabaIDScanner alloc] init];
        titleScanner->nextScanner = idScanner;
        idScanner->nextScanner = nil;
    } else {
        titleScanner->nextScanner = nil;
    }
}

- (NSArray *)parse:(NSString *)str
{
    return [self parse:str offset:0];
}

- (NSArray *)parse:(NSString *)str offset:(int)offset
{

    NSUInteger length = [str length] - offset;
    //unichar chars[length];
    unichar *chars = (unichar *)calloc(length, sizeof(unichar)); //[length];
    ScanContext *context = self->_context;
    context->res = [Res alloc];
    context->resList = [NSMutableArray array];

    [str getCharacters:chars range:NSMakeRange(offset, length)];

    context->chars = chars;
    context->charsLength = length;

    if (length == 0) {
        return context->resList;
    }

    [context->resList addObject:context->res];

    context->nextStartIndex = 0;
    // 走査開始
    for (;;) {
        [context->firstScanner run:context index:context->nextStartIndex];

        if (context->endOfText) break;
        if (context->charsLength <= context->nextStartIndex) break;

        if (context->endOfLine == NO) {
            NSUInteger length = context->charsLength;
            unichar *chars = context->chars;

            int i = context->nextStartIndex;
            for (; i <= length; i++) {
                unichar letter = chars[i];
                if (letter == 0xA) { // 改行
                    [self isEndOfLine:context index:i];
                    context->endOfLine = NO;
                    context->res = [Res alloc];
                    [context->resList addObject:context->res];

                    break;
                }
            }
        }
        context->endOfLine = NO;
    }

    free(chars);
    return context->resList;
}

@end

@implementation BaseScanner

//　継承クラスでオーバーライドする。
- (void)onTermGenerated:(ScanContext *)context text:(NSString *)text
{
}

//
// 汎用スキャン
//
// ・タグは取り除く。
// ・参照文字を変換する。
// ・<>の終了を検知する。
// ・改行で終了する。resListに有効なresを追加する。新しいResオブジェクトを生成する。
// ・テキストの最後に達したらでcontext->endOfText=TRUEをつけて終了する。
// ・適切な状況でnextScannerの run:context:indexを呼ぶ。
//
// 文字列が取得できたら onTermGenerated:context:string が呼ばれる
//
- (void)run:(ScanContext *)context index:(int)start
{
    int termBeginIndex = start;
    context->success = NO;

    BOOL shouldBreak = NO;

    NSUInteger length = context->charsLength;
    NSMutableString *term = [NSMutableString stringWithString:@""];
    unichar *chars = context->chars;
    for (int i = start; i <= length; i++) {

        if (i == length) {
            context->success = YES;
            shouldBreak = YES;
            context->endOfText = YES;
            context->endOfLine = YES;
        } else {
            unichar letter = chars[i];
            if (letter == '&') {
                [context->referScanner run:context index:i];
            } else if (letter == '<' && i + 1 < length) { // 次の文字がある場合のみ
                [self isDelimiter:context index:i];
                if (context->success) {
                    if (i + 2 < length) {
                    }
                    context->nextStartIndex = i + 2;
                    shouldBreak = YES;
                    ;
                } else {
                    [context->tagScanner run:context index:i];
                }

            } else if (letter == 0xA) { // 改行
                [self isEndOfLine:context index:i];
                shouldBreak = YES;
                ;
            }
        }

        if (context->success) {
            context->success = NO;

            // 以前の文字列を生成・追加
            if (i != termBeginIndex) {

                NSString *text = [self substringOfCharacters:chars start:termBeginIndex end:i];
                [term appendString:text];
            }
            if (context->genNodes != nil) {
                for (int n = 0; n < [context->genNodes count]; n++) {
                    ResNodeBase *node = [context->genNodes objectAtIndex:n];
                    [term appendString:[node getText]];
                }
                context->genNodes = nil;
            }

            if (shouldBreak) {
                break;
            }

            i = context->nextStartIndex - 1; // i++されるため
            termBeginIndex = context->nextStartIndex;
        }
    }

    [self onTermGenerated:context text:term];
    term = nil;

    context->success = NO;

    if (!context->endOfText && self->nextScanner != nil) {
        [self->nextScanner run:context index:context->nextStartIndex];
    } else if (context->endOfLine) {
        if (context->endOfText == NO) {
            context->res = [Res alloc];
            [context->resList addObject:context->res];
            //[context->firstScanner run:context index:context->nextStartIndex];
        }
    }
}

- (NSString *)translateReference:(unichar *)chars length:(NSUInteger)length
{
    initCharRefMap();
    ScanContext *context = [[ScanContext alloc] init];
    context->chars = chars;
    context->charsLength = length;
    int termBeginIndex = 0;

    NSMutableString *mutable = [[NSMutableString alloc] init];
    for (int i = 0; i <= length; i++) {

        if (i == length) {
            context->success = YES;
        } else {
            unichar letter = chars[i];
            if (letter == '&') {
                [self runRefNext:context index:i + 1];
            }
        }

        if (context->success) {
            context->success = NO;
            if (i != termBeginIndex) {
                NSString *text = [self substringOfCharacters:chars start:termBeginIndex end:i];
                if (text)
                    [mutable appendString:text];
            }
            if (context->genNodes != nil) {
                for (int n = 0; n < [context->genNodes count]; n++) {
                    ResNodeBase *node = [context->genNodes objectAtIndex:n];
                    [mutable appendString:[node getText]];
                }
                context->genNodes = nil;
            }
            termBeginIndex = context->nextStartIndex;
        }
    }

    return mutable;
}

// &#320234;
- (void)runRefNext:(ScanContext *)context index:(int)rightOfRef
{

    unichar left = context->chars[rightOfRef];
    int start = rightOfRef - 1;
    if (left == '#') {
        unichar letter2 = context->chars[start + 2];
        if (letter2 == 'x') { //16進数
            int indexOfPeriod = [self indexOf:context unichar:(unichar)';' index:start + 3];
            if (indexOfPeriod != -1 && indexOfPeriod != start + 3) {

                NSString *pString = [self substringOfCharacters:context->chars start:start + 3 end:indexOfPeriod];
                NSScanner *pScanner = [NSScanner scannerWithString:pString];

                unsigned int iValue;
                [pScanner scanHexInt:&iValue];
            }

        } else { //10進数
            for (int i = 0; i < 7; i++) {
                if ([self isDigit:context->chars[start + 2 + i]] == NO) {
                    if (i < 2) break;

                    //;, #&3642,それ以外を検出
                    NSString *vStr = [self substringOfCharacters:context->chars + start + 2 length:i];
                    int value = [vStr intValue];

                    NSString *text = [[NSString alloc] initWithCharacters:(unichar *)&value length:1];

                    if ([self startsWith:context index:start + 2 + i string:@";&#65039;"]) {
                        context->nextStartIndex = start + 2 + i + 9;
                        ////                                        text =  [[NSString alloc] initWithCharacters:&value length:2];
                        //                                        char cs[2];
                        //                                        cs[0] = value;
                        //                                        cs[1] = 65038;

                        unichar cs[2];
                        //                                        cs[0] = 65038;
                        cs[0] = value;
                        cs[1] = 65039;

                        text = [NSString stringWithCharacters:cs length:2];
                        //  myLog(@"c = %@", text);
                        // aawfw
                        //    text = [NSString stringWithUTF8String:<#(const char *)#>:@"%C%C", (unichar)value, 65038];
                        //                                        text = string;
                    } else

                        if ([self startsWith:context index:start + 2 + i string:@";&#65038;"]) {
                        context->nextStartIndex = start + 2 + i + 9;
                        ////                                        text =  [[NSString alloc] initWithCharacters:&value length:2];
                        //                                        char cs[2];
                        //                                        cs[0] = value;
                        //                                        cs[1] = 65038;

                        unichar cs[2];
                        //                                        cs[0] = 65038;
                        cs[0] = value;
                        cs[1] = 65038;

                        text = [NSString stringWithCharacters:cs length:2];
                        //   myLog(@"c = %@", text);
                        //    text = [NSString stringWithUTF8String:<#(const char *)#>:@"%C%C", (unichar)value, 65038];
                        //                                        text = string;
                    } else if (context->chars[start + 2 + i] == ';') {
                        context->nextStartIndex = start + 2 + i + 1;
                    } else if ([self startsWith:context index:start + 2 + i string:@"&#3642"]) {
                        context->nextStartIndex = start + 2 + i + 6;
                    } else {
                        context->nextStartIndex = start + 2 + i;
                    }

                    //  myLog(@"(unichar)value = %d" , value);
                    //  [[NSString alloc] initWithCharacters:&value length:1];
                    //     NSString* text = [NSString stringWithFormat:@"%C", (unichar)value];

                    /*
                                    if (value == 9899) {
                                            text = @"●";
                                    } else if (value == 9898) {
                                        text = @"○";
                                    }*/

                    //   myLog(@"esText = {%@}", text);

                    TextNode *textNode = [[TextNode alloc] initWithNSString:text];
                    context->genNodes = [NSArray arrayWithObjects:textNode, nil];
                    context->success = YES;
                    return;
                }
            }
        }
    } else { //文字参照
        int indexOfPeriod = [self indexOf:context unichar:';' index:start + 1];
        if (indexOfPeriod != -1 && indexOfPeriod != start + 1) {
            NSString *term = [self substringOfCharacters:context->chars + start + 1
                                                  length:indexOfPeriod - (start + 1)];
            NSNumber *storedNumber = [charRefMap objectForKey:term];

            if (storedNumber != nil) {
                unichar ch = (unichar)[storedNumber intValue];
                NSString *text = [[NSString alloc] initWithCharacters:&ch length:1];
                //                                NSString* text = @"?";//[NSString stringWithFormat:@"%C", (unichar)[storedNumber intValue]];

                TextNode *textNode = [[TextNode alloc] initWithNSString:text];
                context->genNodes = [NSArray arrayWithObjects:textNode, nil];
                context->nextStartIndex = indexOfPeriod + 1;
                context->success = YES;
                return;
            }
        }
    }
}

- (BOOL)isDelimiter:(ScanContext *)context index:(int)start
{
    if (start == context->charsLength - 1) {
        context->success = YES;
        context->endOfText = YES;
        return NO;
    }

    unichar next = context->chars[start + 1];
    if (next == '>') {
        context->success = YES;
        context->nextStartIndex = start + 2;
        return YES;
    }
    return NO;
}

- (BOOL)isEndOfLine:(ScanContext *)context index:(int)start
{
    context->success = YES;
    context->endOfLine = YES;
    if (context->charsLength - 1 == start) {
        context->endOfText = YES;
    }
    context->nextStartIndex = start + 1;
    return YES;
}

- (NSString *)substringOfCharacters:(unichar *)chars length:(NSUInteger)length
{
    return [NSString stringWithCharacters:chars length:length];
}
- (NSString *)substringOfCharacters:(unichar *)chars start:(int)start end:(int)end
{
    return [NSString stringWithCharacters:chars + start length:end - start];
}

//
// indexOf
//
- (int)indexOf:(ScanContext *)context unichar:(unichar)uchar index:(int)index
{
    return [self indexOf:context->chars length:context->charsLength unichar:uchar index:index];
}

//
// indexOf
//
- (int)indexOf:(unichar *)chars length:(NSUInteger)length unichar:(unichar)uchar index:(int)index
{
    for (int i = index; i < length; i++) {
        if (chars[i] == uchar) {
            return i;
        } else if (chars[i] == '<' || chars[i] == 0xA) {
            return -1;
        }
    }
    return -1;
}

- (BOOL)startsWith:(ScanContext *)context index:(int)index string:(NSString *)string
{
    return [self startsWith:context->chars length:context->charsLength index:index string:string];
}

- (BOOL)startsWith:(unichar *)chars length:(NSUInteger)length index:(int)index string:(NSString *)string
{
    if (string == nil) return NO;

    NSUInteger strLength = [string length];
    if (strLength == 0) return NO;

    // 文字数が足りてないのでOUT
    if (index + strLength > length) {
        return NO;
    }

    for (int j = 0; j < strLength; j++) {
        if (chars[index + j] != [string characterAtIndex:j]) {
            return NO;
        }
    }
    return YES;
}

- (int)indexOf:(ScanContext *)context string:(NSString *)string index:(int)index
{
    return [self indexOf:context->chars length:context->charsLength string:string index:index];
}

- (int)indexOf:(unichar *)chars
        length:(NSUInteger)length
        string:(NSString *)string
         index:(int)index
{
    NSUInteger strLength = [string length];

    unichar buffer[strLength];
    [string getCharacters:buffer range:NSMakeRange(0, strLength)];

    for (int i = index; i < length; i++) {
        unichar letter = chars[i];
        if (letter == 0xA) {
            return -1;
        }

        if (i + strLength > length) {
            break;
        }
        BOOL ok = YES;
        for (int j = 0; j < strLength; j++) {
            if (chars[i + j] != [string characterAtIndex:j]) {
                ok = NO;
                break;
            }
        }
        if (ok) {
            return i; // 全一致
        } else {
        }
    }
    return -1;
}

- (int)lastIndexOf:(unichar *)chars length:(NSUInteger)length unichar:(unichar)unichar beginIndex:(int)beginIndex endIndex:(int)endIndex
{
    if (endIndex < length == false || beginIndex < 0) return -1;

    for (int i = endIndex; i >= beginIndex; i--) {
        if (chars[i] == unichar) {
            return i;
        }
    }
    return -1;
}

- (BOOL)isDigit:(unichar)letter
{
    if (letter == '0' || letter == '1' || letter == '2' || letter == '3' || letter == '4' || letter == '5' || letter == '6' || letter == '7' || letter == '8' || letter == '9') {
        return YES;
    }
    return NO;
}
@end

//
// NameScanner
//
// 名前
//
@implementation NameScanner

- (void)onTermGenerated:(ScanContext *)context text:(NSString *)text
{
    context->res.name = text;
}
@end

//
// MailScanner
//
// メール
//
@implementation MailScanner

- (void)onTermGenerated:(ScanContext *)context text:(NSString *)text
{
    context->res.mail = text;
}
@end

//
// IDScanner
//
// したらばはIDだけの項目がある
//
@implementation ShitarabaIDScanner

- (void)onTermGenerated:(ScanContext *)context text:(NSString *)text
{
    context->res.ID = text;
}
@end

//
// ThreadTitleScanner
//
// スレッドタイトル
//
@implementation TitleScanner

- (void)onTermGenerated:(ScanContext *)context text:(NSString *)text
{
    context->res.threadTitle = text;
}
@end

//
// ResNumberScanner
//
// したらばとまちBBSだけのレス番号
//
@implementation ResNumberScanner

- (void)onTermGenerated:(ScanContext *)context text:(NSString *)text
{
    context->res.number = [text intValue];
}
@end

@implementation DateScanner

// DateScanner
- (void)run:(ScanContext *)context index:(int)start
{
    int termBeginIndex = start;
    int spaceCount = 0;

    NSUInteger length = context->charsLength;
    unichar *chars = context->chars;
    BOOL inBEID = NO, inBERank = NO, inBEPoint = NO;
    int beStartPos = 0;

    for (int i = start; i <= length; i++) {
        BOOL shouldSplit = NO;
        BOOL shouldEnd = NO;

        if (i == length) {
            shouldEnd = shouldSplit = context->endOfText = context->endOfLine = YES;
        } else {
            unichar letter = chars[i];
            if (letter == '<') { // 次の文字がある場合のみ
                [self isDelimiter:context index:i];
                if (context->success) {
                    context->nextStartIndex = i + 2;
                } else {
                    context->nextStartIndex = i + 1;
                }

                shouldSplit = YES;
                spaceCount++;
                shouldEnd = YES;
            } else if (letter == 0xA) {
                shouldSplit = YES;
                context->nextStartIndex = i + 1;
                shouldEnd = YES;
                spaceCount++;
            } else if (letter == ' ') {
                spaceCount++;
                shouldSplit = YES;
                context->nextStartIndex = i + 1;
            } else {
                // BE:ログインＩＤ-ランク(Beポイント)
                // 例：BE:999999999-DIA(20000)
                if (inBEID) {
                    if (letter == '-') {
                        NSString *beId = [self substringOfCharacters:context->chars + beStartPos
                                                              length:i - beStartPos];
                        context->res.BEID = beId;
                        beStartPos = i + 1;
                        inBERank = YES;
                        inBEID = NO;
                    }

                } else if (inBERank) {
                    if (letter == '(') {
                        NSString *beRank = [self substringOfCharacters:context->chars + beStartPos
                                                                length:i - beStartPos];
                        inBERank = NO;
                        inBEPoint = YES;
                        beStartPos = i + 1;
                        context->res.BERank = beRank;
                    }

                } else if (inBEPoint) {
                    if (letter == ')') {
                        NSString *bePoint = [self substringOfCharacters:context->chars + beStartPos
                                                                 length:i - beStartPos];
                        inBEPoint = NO;
                        context->res.BEPoint = [bePoint intValue];
                    }
                } else if (spaceCount >= 2 && [self startsWith:context index:i string:@"BE:"]) {
                    beStartPos = i + 3;
                    i += 2;
                    inBEID = YES;
                }
            }
        }

        if (shouldSplit) {
            shouldSplit = NO;
            NSString *term = [self substringOfCharacters:context->chars + termBeginIndex length:i - termBeginIndex];
            if (spaceCount == 0 && shouldEnd) {
                context->res.dateStr = term;
            } else {
                if (spaceCount == 1) {
                    context->res.dateStr = term;
                } else if (spaceCount == 2) {
                    context->res.timeStr = term;
                } else if (spaceCount == 3) {
                    BOOL startsWithID = [self startsWith:context index:termBeginIndex string:@"ID:"];
                    if (startsWithID) {
                        NSString *idStr = [self substringOfCharacters:context->chars + termBeginIndex + 3
                                                               length:i - (termBeginIndex + 3)];
                        context->res.ID = idStr;

                    } else {

                        BOOL startsWithHasshin = [self startsWith:context index:termBeginIndex string:@"発信元:"];
                        if (startsWithHasshin) {
                            NSString *idStr = [self substringOfCharacters:context->chars + termBeginIndex + 4
                                                                   length:i - (termBeginIndex + 4)];
                            context->res.ID = idStr;
                        }
                    }
                } else if (spaceCount == 4) {

                } else {
                    shouldEnd = YES;
                }
            }

            if (context->endOfLine) {
                return;
            }

            term = nil;
            if (shouldEnd) {
                context->success = YES;
                context->nextStartIndex = i;
                if (self->nextScanner != nil) {
                    [self->nextScanner run:context index:i + 2];
                }
                return;
            }

            termBeginIndex = context->nextStartIndex;
        }
    }
}
@end

@implementation BodyScanner

- (id)init
{
    if (self = [super init]) {
    }

    return self;
}

- (int)isBr:(NSString *)str startIndex:(int)start context:(ScanContext *)context
{
    return 32;
}

// BodyScanner
- (void)run:(ScanContext *)context index:(int)start
{
    int termBeginIndex = start;
    NSMutableArray *nodeList = [NSMutableArray array];
    context->success = NO;
    ResNodeBase *previousNode = nil;

    BOOL shouldBreak = NO;
    context->nextOfTag = YES;
    //  myLog(@"runbody");

    NSUInteger length = context->charsLength;
    unichar *chars = context->chars;
    int aaCount = 0;

    int i = start;
    for (; i <= length; i++) {

        if (i == length) {
            context->success = shouldBreak = context->endOfLine = context->endOfText = YES;
        } else {
            unichar letter = chars[i];
            if (letter == '&' || letter == '>') {
                [context->referScanner run:context index:i];
            } else if (letter == 'I') {
                [context->idScanner parseIdNode:context index:i];
            } else if (letter == 's' || letter == 'h' || letter == 't') {
                [context->urlScanner run:context index:i];
            } else if (letter == '<' && i + 1 < length) { // 次の文字がある場合のみ
                [self isDelimiter:context index:i];
                if (context->success) {
                    context->nextStartIndex = i + 2;
                    shouldBreak = YES;
                    ;
                } else {
                    [context->tagScanner run:context index:i];
                }

            } else if (letter == 0xA) { // 改行

                [self isEndOfLine:context index:i];
                shouldBreak = YES;
                ;

            } else if (context->nextOfTag && letter == ' ' && i == termBeginIndex) {
                termBeginIndex++; //先頭のスペースを削除
                //末尾のスペースは処理していない。切り取らなくてもいい気が。
                context->nextOfTag = NO;
            } else if (letter == context->firstOfSpace) {
                if (length > i + 1 && chars[i + 1] == ' ') {
                    aaCount++;
                }
            }
        }

        if (context->success) {
            context->success = NO;
            // 以前の文字列を生成・追加
            if (i != termBeginIndex) {
                NSString *text = [self substringOfCharacters:chars start:termBeginIndex end:i];
                //if ([text isEqualToString:@"  "] ||[text isEqualToString:@" "] ) {
                //myLog(@"[%@]", text);
                //                                } else {
                if ([previousNode isKindOfClass:[TextNode class]]) {
                    TextNode *prevText = (TextNode *)previousNode;

                    [prevText appendText:text];

                } else {
                    TextNode *textNode = [[TextNode alloc] initWithNSString:text];
                    [nodeList addObject:textNode];
                    previousNode = textNode;
                    // myLog(@"her = %@", text);
                }
                //                              }
            }
            if (context->genNodes != nil) {
                for (int n = 0; n < [context->genNodes count]; n++) {
                    ResNodeBase *node = [context->genNodes objectAtIndex:n];
                    // LineBreakNodeの再利用
                    if ([node isKindOfClass:LineBreakNode.class] && [previousNode isKindOfClass:LineBreakNode.class]) {
                        node = previousNode;
                        [(LineBreakNode *)node incrementCount];
                    } else if ([node isKindOfClass:[TextNode class]] && [previousNode isKindOfClass:[TextNode class]]) {
                        TextNode *prevText = (TextNode *)previousNode;
                        //               myLog(@"append %@ with %@", [prevText getText],[(TextNode*)node getText]);
                        [prevText appendText:[(TextNode *)node getText]];
                        node = previousNode;

                    } else {
                        [nodeList addObject:node];
                    }
                    previousNode = node;
                }
                context->genNodes = nil;
            }

            if (context->endOfLine) return;

            if (shouldBreak) {
                break;
            }

            i = context->nextStartIndex - 1; // i++されるため
            termBeginIndex = context->nextStartIndex;
        }
    }
    context->success = NO;
    context->res.bodyNodes = nodeList;

    if (aaCount > 3) {
        context->res.isAA = YES;
    }

    if (context->endOfText) {
        return;
    } else if (context->endOfLine) {
        context->endOfLine = NO;
        if (context->endOfText == NO) {
            context->res = [Res alloc];
            [context->resList addObject:context->res];
        }
    } else if (self->nextScanner != nil) {
        [self->nextScanner run:context index:context->nextStartIndex];
    }
}
@end

@implementation NodeScannerBase

@end

@implementation AnchorScannerBase
// 複数のアンカーを検出するためのcontinueメソッド
- (void)runContinueWithAnchor:(ScanContext *)context
                continueIndex:(int)continueIndex
                   anchorNode:(AnchorNode *)anchorNode //すでに出来たアンカーノード
{
    if (continueIndex < context->charsLength == NO) {
        context->success = NO;
        return;
    }
    // >>125, 123, 512のような続きを発見する
    unichar next = context->chars[continueIndex];
    unichar next2 = continueIndex + 1 < context->charsLength ? context->chars[continueIndex + 1] : 0;

    if (next == '-') {
        if (anchorNode.isClosed) {
            context->success = NO;
            return;
        }

        int num = [self runNumber:context index:continueIndex + 1];
        if (context->success) {
            [anchorNode setClosedValue:num];
        } else {
            context->success = NO;
            return;
        }
    } else {
        if (next == ',') {
            NSMutableArray *newNodes = [[NSMutableArray alloc] initWithArray:context->genNodes];
            TextNode *dividerText;
            int num = [self runNumber:context index:continueIndex + (next2 == ' ' ? 2 : 1)];

            if (context->success) {
                dividerText = [[TextNode alloc] initWithNSString:(next2 == ' ' ? @", " : @",")];
                [newNodes addObject:dividerText];

                anchorNode = [[AnchorNode alloc] initWithNumber:num];
                [newNodes addObject:anchorNode];
                context->genNodes = newNodes;
            } else {
                context->success = NO;
                return;
            }
        } else {
            context->success = NO;
            return;
        }
    }

    [self runContinueWithAnchor:context
                  continueIndex:context->nextStartIndex
                     anchorNode:anchorNode // すでに出来たアンカーノード
    ];
    context->success = YES;
}

// アンカーの数値だけを検出
- (int)runNumber:(ScanContext *)context index:(int)startIndex
{
    int count = 0;
    int i = startIndex;
    for (; i < context->charsLength; i++) {
        BOOL digi = [self isDigit:context->chars[i]];
        if (!digi || count > 5 || (i == startIndex && context->chars[i] == '0')) {
            break;
        }
        count++;
    }
    if (i != startIndex) {
        context->success = YES;
        context->nextStartIndex = startIndex + count;
        NSString *trim = [self substringOfCharacters:context->chars + startIndex length:count];
        return [trim intValue];
    }
    context->success = NO;
    return -1;
}

@end

// '<'ではじまるNodeを解析する
@implementation TagScanner

- (int)getEndNumber:(unichar *)chars start:(int)start end:(int)end
{
    int numberStart = -1;
    int numberEnd = -1;
    BOOL keepNumber = NO;
    for (int i = start; i <= end; i++) {
        unichar letter = chars[i];
        if ([self isDigit:letter]) {
            if (keepNumber == NO) {
                numberStart = numberEnd = i;
            } else {
                numberEnd = i;
            }
            keepNumber = YES;
        } else {
            keepNumber = NO;
            numberStart = -1;
        }
    }

    if (numberStart != -1) {
        return [[self substringOfCharacters:chars + numberStart length:numberEnd - numberStart + 1] intValue];
    }

    return -1;
}

// TagScanner
- (void)run:(ScanContext *)context index:(int)start
{
    // startの位置は '<'が来ていると想定
    context->nextOfTag = YES;
    int i = start + 1;
    unichar *chars = context->chars;
    unichar next = chars[i];
    NSUInteger length = context->charsLength;
    if (next == 'b' || next == 'B') { // <br>
        if (3 <= length - i && (chars[i + 1] == 'r' || chars[i + 1] == 'R') && chars[i + 2] == '>') {
            context->success = YES;
            context->nextStartIndex = i + 3;

            LineBreakNode *brNode = [[LineBreakNode alloc] init];

            context->genNodes = [NSArray arrayWithObjects:brNode, nil];
            return;
            //return brNode;
        }
    } else if (next == 'f') { // <font color=gold>awejpfop</font>
        int fontColor = [self indexOf:context string:@"font color=" index:i];
        if (fontColor == i) {
            int indexOfGT = [self indexOf:context unichar:'>' index:i + 7];
            if (indexOfGT != -1 && indexOfGT - i < 36) {
                NSString *text = [self substringOfCharacters:context->chars start:(i + 11)end:indexOfGT];
                context->res.nameColor = text;
                context->success = YES;
                context->nextStartIndex = indexOfGT + 1;
                return;
            }
        }

    } else {
        // 対象例: <a href=\"\" target=\"_blank\">&gt;&gt;234</a>
        int indexOfAHref = [self indexOf:context string:@"a href=" index:i];
        if (indexOfAHref == i) {
            int indexOfGT = [self indexOf:context string:@">&gt;&gt;" index:i + 7];
            if (indexOfGT != -1) {
                int indexOfEndA = [self indexOf:context string:@"</a>" index:indexOfGT + 1];
                if (indexOfEndA != -1) {
                    int num = [self getEndNumber:chars start:indexOfGT + 1 end:indexOfEndA];
                    if (num != -1) {
                        AnchorNode *anchorNode = [[AnchorNode alloc] initWithNumber:num];
                        context->genNodes = [NSArray arrayWithObjects:anchorNode, nil];

                        // return anchorNode;
                        [self runContinueWithAnchor:context
                                      continueIndex:indexOfEndA + 4
                                         anchorNode:anchorNode // すでに出来たアンカーノード
                        ];

                        if (context->success) {
                        } else {
                            context->nextStartIndex = indexOfEndA + 4;
                            context->success = YES;
                        }
                        return;
                    }
                }
            }
        }
    }

    // ヒットしなかったので次の'>'までインデックスを飛ばす
    int indexOfGT = [self indexOf:context unichar:'>' index:i];
    if (indexOfGT != -1) {
        context->success = YES;
        context->nextStartIndex = indexOfGT + 1;
        context->genNodes = nil;
        return;
    }

    context->success = NO;
}

@end

// &から始まる文字参照と&gt;&gt;, ＞＞, >,＞ではじまるアンカーを解析する
@implementation ReferScanner

//ReferScanner
- (void)run:(ScanContext *)context index:(int)start
{
    int num;
    AnchorNode *anchorNode = nil;
    NSArray *prefixes = [NSArray arrayWithObjects:@"&gt;&gt;", @"&gt;", @"＞", nil]; //　＞ ＞＞

    for (int i = 0; i < [prefixes count]; i++) {
        NSString *prefix = [prefixes objectAtIndex:i];
        if ([self startsWith:context index:start string:prefix]) {
            num = [self runNumber:context index:start + (int)[prefix length]];
            if (context->success) {
                anchorNode = [[AnchorNode alloc] initWithNumber:num];
            }
        }
    }

    if (anchorNode != nil) {
        context->genNodes = [NSArray arrayWithObjects:anchorNode, nil];
        [self runContinueWithAnchor:context
                      continueIndex:context->nextStartIndex
                         anchorNode:anchorNode //すでに出来たアンカーノード
        ];
        context->success = YES;
        return;
    }

    //TODO:文字参照１

    //private static final String RE_NCR = "&((([0-9a-z]+);)|(#([0-9]+)(&#3642|;)?)|#x([\\da-fA-F]+);)";
    // &amp3;  (([0-9a-z]+);)
    // &#0323&#3642 (#([0-9]+)(&#3642|;)?)
    // &#0323;
    // &#0323
    // &#x0a0f; #x([\\da-fA-F]+);

    context->success = NO;

    [self runRefNext:context index:start + 1];
}
@end

// ID:ではじまるNodeを解析する
@implementation IDScanner : NodeScannerBase

- (BOOL)isIdChar:(unichar)c
{
    if ('A' <= c && c <= 'z')
        return YES;

    if ([self isDigit:c])
        return YES;

    if (c == '/' || c == '+' || c == '!')
        return YES;

    return NO;
}

// 走査しAnchorNodeかnilを返す
// ID:yUGBWbHR0
- (void)parseIdNode:(ScanContext *)context index:(int)i
{
    if (context->charsLength > i + 2 == NO) {
        return;
    }

    unichar *chars = context->chars;

    if (chars[i + 1] == 'D' && chars[i + 2] == ':') {
        // i+3
        // i+4
        // i+5
        // i+6
        // i+7
        // i+8
        // i+9
        // i+10
        int startId = i + 3;
        if (context->charsLength >= startId + 8) { // 8文字分あり
            for (int m = startId; m < startId + 8; m++) {
                unichar ch = chars[m];
                if ([self isIdChar:ch] == NO) {
                    context->success = NO;
                    return;
                }
            }

            IDNode *idNode = nil;
            if (context->charsLength > startId + 8 && [self isIdChar:chars[startId + 8]]) { //末尾あり
                idNode = [[IDNode alloc] initWithString:[self substringOfCharacters:context->chars + startId length:9]];
                context->nextStartIndex = startId + 9;
            } else {
                idNode = [[IDNode alloc] initWithString:[self substringOfCharacters:context->chars + startId length:8]];
                context->nextStartIndex = startId + 8;
            }
            context->success = YES;
            context->genNodes = [[NSArray alloc] initWithObjects:idNode, nil];
            return;
        }

        context->success = NO;
    }
}
@end

// ID:ではじまるNodeを解析する
@implementation URLScanner : NodeScannerBase

// 走査しLinkNodeかnilを返す
- (void)run:(ScanContext *)context index:(int)start
{
    NSString *realScheme = nil;
    NSString *accessScheme = nil;
    int lettersStart = 0;
    unichar *chars = context->chars;
    NSUInteger length = context->charsLength;

    BOOL ok = NO;
    NSArray *schemes = [NSArray arrayWithObjects:@"http://", @"https://", @"ttp://", @"ttps://", @"sssp://", nil];
    for (int i = 0; i < [schemes count]; i++) {
        NSString *scheme = [schemes objectAtIndex:i];
        if ([self startsWith:context index:start string:scheme]) {
            realScheme = [schemes objectAtIndex:i];
            int accessSchemeIndex = (i == 2) ? 0 : (i == 3 ? 1 : i);
            accessScheme = (NSString *)[schemes objectAtIndex:accessSchemeIndex];
            lettersStart = start + (int)[scheme length];

            ok = YES;
            break;
        }
    }

    if (ok == NO) {
        context->success = NO;
        return;
    }

    int n = lettersStart;
    for (; n < length; n++) {
        unichar t = chars[n];
        if (('A' <= t && t <= 'z') || ('0' <= t && t <= '9') || t == '_' || t == '.' || t == '(' || t == ')' || t == '$' || t == '*' || t == '!' || t == '-' || t == ':' || t == '#' || t == ',' || t == '?' || t == '=' || t == '&' || t == ';' || t == '%' || t == '~' || t == '+' || t == '/') {
            continue;
        } else {
            break;
        }
    }
    if (n == lettersStart) {
        context->success = NO;
        return;
    } //一文字もない場合は失敗

    context->success = YES;
    context->nextStartIndex = n;
    NSString *url = [self substringOfCharacters:chars + start length:n - start];
    NSString *accessUrl = [accessScheme stringByAppendingString:[self substringOfCharacters:chars + lettersStart length:n - lettersStart]];

    LinkNode *linkNode = [[LinkNode alloc] initWithUrl:url
                                         withAccessUrl:accessUrl];

    context->genNodes = [NSArray arrayWithObjects:linkNode, nil];

}
@end

void initCharRefMap()
{
    if (charRefMap != nil) return;
    charRefMap = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:34], @"quot",
                                   [NSNumber numberWithInt:38], @"amp",
                                   [NSNumber numberWithInt:60], @"lt",
                                   [NSNumber numberWithInt:62], @"gt",
                                   [NSNumber numberWithInt:160], @"nbsp",
                                   [NSNumber numberWithInt:161], @"iexcl",
                                   [NSNumber numberWithInt:162], @"cent",
                                   [NSNumber numberWithInt:163], @"pound",
                                   [NSNumber numberWithInt:164], @"curren",
                                   [NSNumber numberWithInt:165], @"yen",
                                   [NSNumber numberWithInt:166], @"brvbar",
                                   [NSNumber numberWithInt:167], @"sect",
                                   [NSNumber numberWithInt:168], @"uml",
                                   [NSNumber numberWithInt:169], @"copy",
                                   [NSNumber numberWithInt:170], @"ordf",
                                   [NSNumber numberWithInt:171], @"laquo",
                                   [NSNumber numberWithInt:172], @"not",
                                   [NSNumber numberWithInt:173], @"shy",
                                   [NSNumber numberWithInt:174], @"reg",
                                   [NSNumber numberWithInt:175], @"macr",
                                   [NSNumber numberWithInt:176], @"deg",
                                   [NSNumber numberWithInt:177], @"plusmn",
                                   [NSNumber numberWithInt:178], @"sup2",
                                   [NSNumber numberWithInt:179], @"sup3",
                                   [NSNumber numberWithInt:180], @"acute",
                                   [NSNumber numberWithInt:181], @"micro",
                                   [NSNumber numberWithInt:182], @"para",
                                   [NSNumber numberWithInt:183], @"middot",
                                   [NSNumber numberWithInt:184], @"cedil",
                                   [NSNumber numberWithInt:185], @"sup1",
                                   [NSNumber numberWithInt:186], @"ordm",
                                   [NSNumber numberWithInt:187], @"raquo",
                                   [NSNumber numberWithInt:188], @"frac14",
                                   [NSNumber numberWithInt:189], @"frac12",
                                   [NSNumber numberWithInt:190], @"frac34",
                                   [NSNumber numberWithInt:191], @"iquest",
                                   [NSNumber numberWithInt:192], @"Agrave",
                                   [NSNumber numberWithInt:193], @"Aacute",
                                   [NSNumber numberWithInt:194], @"Acirc",
                                   [NSNumber numberWithInt:195], @"Atilde",
                                   [NSNumber numberWithInt:196], @"Auml",
                                   [NSNumber numberWithInt:197], @"Aring",
                                   [NSNumber numberWithInt:198], @"AElig",
                                   [NSNumber numberWithInt:199], @"Ccedil",
                                   [NSNumber numberWithInt:200], @"Egrave",
                                   [NSNumber numberWithInt:201], @"Eacute",
                                   [NSNumber numberWithInt:202], @"Ecirc",
                                   [NSNumber numberWithInt:203], @"Euml",
                                   [NSNumber numberWithInt:204], @"Igrave",
                                   [NSNumber numberWithInt:205], @"Iacute",
                                   [NSNumber numberWithInt:206], @"Icirc",
                                   [NSNumber numberWithInt:207], @"Iuml",
                                   [NSNumber numberWithInt:208], @"ETH",
                                   [NSNumber numberWithInt:209], @"Ntilde",
                                   [NSNumber numberWithInt:210], @"Ograve",
                                   [NSNumber numberWithInt:211], @"Oacute",
                                   [NSNumber numberWithInt:212], @"Ocirc",
                                   [NSNumber numberWithInt:213], @"Otilde",
                                   [NSNumber numberWithInt:214], @"Ouml",
                                   [NSNumber numberWithInt:215], @"times",
                                   [NSNumber numberWithInt:216], @"Oslash",
                                   [NSNumber numberWithInt:217], @"Ugrave",
                                   [NSNumber numberWithInt:218], @"Uacute",
                                   [NSNumber numberWithInt:219], @"Ucirc",
                                   [NSNumber numberWithInt:220], @"Uuml",
                                   [NSNumber numberWithInt:221], @"Yacute",
                                   [NSNumber numberWithInt:222], @"THORN",
                                   [NSNumber numberWithInt:223], @"szlig",
                                   [NSNumber numberWithInt:224], @"agrave",
                                   [NSNumber numberWithInt:225], @"aacute",
                                   [NSNumber numberWithInt:226], @"acirc",
                                   [NSNumber numberWithInt:227], @"atilde",
                                   [NSNumber numberWithInt:228], @"auml",
                                   [NSNumber numberWithInt:229], @"aring",
                                   [NSNumber numberWithInt:230], @"aelig",
                                   [NSNumber numberWithInt:231], @"ccedil",
                                   [NSNumber numberWithInt:232], @"egrave",
                                   [NSNumber numberWithInt:233], @"eacute",
                                   [NSNumber numberWithInt:234], @"ecirc",
                                   [NSNumber numberWithInt:235], @"euml",
                                   [NSNumber numberWithInt:236], @"igrave",
                                   [NSNumber numberWithInt:237], @"iacute",
                                   [NSNumber numberWithInt:238], @"icirc",
                                   [NSNumber numberWithInt:239], @"iuml",
                                   [NSNumber numberWithInt:240], @"eth",
                                   [NSNumber numberWithInt:241], @"ntilde",
                                   [NSNumber numberWithInt:242], @"ograve",
                                   [NSNumber numberWithInt:243], @"oacute",
                                   [NSNumber numberWithInt:244], @"ocirc",
                                   [NSNumber numberWithInt:245], @"otilde",
                                   [NSNumber numberWithInt:246], @"ouml",
                                   [NSNumber numberWithInt:247], @"divide",
                                   [NSNumber numberWithInt:248], @"oslash",
                                   [NSNumber numberWithInt:249], @"ugrave",
                                   [NSNumber numberWithInt:250], @"uacute",
                                   [NSNumber numberWithInt:251], @"ucirc",
                                   [NSNumber numberWithInt:252], @"uuml",
                                   [NSNumber numberWithInt:253], @"yacute",
                                   [NSNumber numberWithInt:254], @"thorn",
                                   [NSNumber numberWithInt:255], @"yuml",
                                   [NSNumber numberWithInt:402], @"fnof",
                                   [NSNumber numberWithInt:913], @"Alpha",
                                   [NSNumber numberWithInt:914], @"Beta",
                                   [NSNumber numberWithInt:915], @"Gamma",
                                   [NSNumber numberWithInt:916], @"Delta",
                                   [NSNumber numberWithInt:917], @"Epsilon",
                                   [NSNumber numberWithInt:918], @"Zeta",
                                   [NSNumber numberWithInt:919], @"Eta",
                                   [NSNumber numberWithInt:920], @"Theta",
                                   [NSNumber numberWithInt:921], @"Iota",
                                   [NSNumber numberWithInt:922], @"Kappa",
                                   [NSNumber numberWithInt:923], @"Lambda",
                                   [NSNumber numberWithInt:924], @"Mu",
                                   [NSNumber numberWithInt:925], @"Nu",
                                   [NSNumber numberWithInt:926], @"Xi",
                                   [NSNumber numberWithInt:927], @"Omicron",
                                   [NSNumber numberWithInt:928], @"Pi",
                                   [NSNumber numberWithInt:929], @"Rho",
                                   [NSNumber numberWithInt:931], @"Sigma",
                                   [NSNumber numberWithInt:932], @"Tau",
                                   [NSNumber numberWithInt:933], @"Upsilon",
                                   [NSNumber numberWithInt:934], @"Phi",
                                   [NSNumber numberWithInt:935], @"Chi",
                                   [NSNumber numberWithInt:936], @"Psi",
                                   [NSNumber numberWithInt:937], @"Omega",
                                   [NSNumber numberWithInt:945], @"alpha",
                                   [NSNumber numberWithInt:946], @"beta",
                                   [NSNumber numberWithInt:947], @"gamma",
                                   [NSNumber numberWithInt:948], @"delta",
                                   [NSNumber numberWithInt:949], @"epsilon",
                                   [NSNumber numberWithInt:950], @"zeta",
                                   [NSNumber numberWithInt:951], @"eta",
                                   [NSNumber numberWithInt:952], @"theta",
                                   [NSNumber numberWithInt:953], @"iota",
                                   [NSNumber numberWithInt:954], @"kappa",
                                   [NSNumber numberWithInt:955], @"lambda",
                                   [NSNumber numberWithInt:956], @"mu",
                                   [NSNumber numberWithInt:957], @"nu",
                                   [NSNumber numberWithInt:958], @"xi",
                                   [NSNumber numberWithInt:959], @"omicron",
                                   [NSNumber numberWithInt:960], @"pi",
                                   [NSNumber numberWithInt:961], @"rho",
                                   [NSNumber numberWithInt:962], @"sigmaf",
                                   [NSNumber numberWithInt:963], @"sigma",
                                   [NSNumber numberWithInt:964], @"tau",
                                   [NSNumber numberWithInt:965], @"upsilon",
                                   [NSNumber numberWithInt:966], @"phi",
                                   [NSNumber numberWithInt:967], @"chi",
                                   [NSNumber numberWithInt:968], @"psi",
                                   [NSNumber numberWithInt:969], @"omega",
                                   [NSNumber numberWithInt:977], @"thetasym",
                                   [NSNumber numberWithInt:978], @"upsih",
                                   [NSNumber numberWithInt:982], @"piv",
                                   [NSNumber numberWithInt:8226], @"bull",
                                   [NSNumber numberWithInt:8230], @"hellip",
                                   [NSNumber numberWithInt:8242], @"prime",
                                   [NSNumber numberWithInt:8243], @"Prime",
                                   [NSNumber numberWithInt:8254], @"oline",
                                   [NSNumber numberWithInt:8260], @"frasl",
                                   [NSNumber numberWithInt:8472], @"weierp",
                                   [NSNumber numberWithInt:8465], @"image",
                                   [NSNumber numberWithInt:8476], @"real",
                                   [NSNumber numberWithInt:8482], @"trade",
                                   [NSNumber numberWithInt:8501], @"alefsym",
                                   [NSNumber numberWithInt:8592], @"larr",
                                   [NSNumber numberWithInt:8593], @"uarr",
                                   [NSNumber numberWithInt:8594], @"rarr",
                                   [NSNumber numberWithInt:8595], @"darr",
                                   [NSNumber numberWithInt:8596], @"harr",
                                   [NSNumber numberWithInt:8629], @"crarr",
                                   [NSNumber numberWithInt:8656], @"lArr",
                                   [NSNumber numberWithInt:8657], @"uArr",
                                   [NSNumber numberWithInt:8658], @"rArr",
                                   [NSNumber numberWithInt:8659], @"dArr",
                                   [NSNumber numberWithInt:8660], @"hArr",
                                   [NSNumber numberWithInt:8704], @"forall",
                                   [NSNumber numberWithInt:8706], @"part",
                                   [NSNumber numberWithInt:8707], @"exist",
                                   [NSNumber numberWithInt:8709], @"empty",
                                   [NSNumber numberWithInt:8711], @"nabla",
                                   [NSNumber numberWithInt:8712], @"isin",
                                   [NSNumber numberWithInt:8713], @"notin",
                                   [NSNumber numberWithInt:8715], @"ni",
                                   [NSNumber numberWithInt:8719], @"prod",
                                   [NSNumber numberWithInt:8721], @"sum",
                                   [NSNumber numberWithInt:8722], @"minus",
                                   [NSNumber numberWithInt:8727], @"lowast",
                                   [NSNumber numberWithInt:8730], @"radic",
                                   [NSNumber numberWithInt:8733], @"prop",
                                   [NSNumber numberWithInt:8734], @"infin",
                                   [NSNumber numberWithInt:8736], @"ang",
                                   [NSNumber numberWithInt:8743], @"and",
                                   [NSNumber numberWithInt:8744], @"or",
                                   [NSNumber numberWithInt:8745], @"cap",
                                   [NSNumber numberWithInt:8746], @"cup",
                                   [NSNumber numberWithInt:8747], @"int",
                                   [NSNumber numberWithInt:8756], @"there4",
                                   [NSNumber numberWithInt:8764], @"sim",
                                   [NSNumber numberWithInt:8773], @"cong",
                                   [NSNumber numberWithInt:8776], @"asymp",
                                   [NSNumber numberWithInt:8800], @"ne",
                                   [NSNumber numberWithInt:8801], @"equiv",
                                   [NSNumber numberWithInt:8804], @"le",
                                   [NSNumber numberWithInt:8805], @"ge",
                                   [NSNumber numberWithInt:8834], @"sub",
                                   [NSNumber numberWithInt:8835], @"sup",
                                   [NSNumber numberWithInt:8836], @"nsub",
                                   [NSNumber numberWithInt:8838], @"sube",
                                   [NSNumber numberWithInt:8839], @"supe",
                                   [NSNumber numberWithInt:8853], @"oplus",
                                   [NSNumber numberWithInt:8855], @"otimes",
                                   [NSNumber numberWithInt:8869], @"perp",
                                   [NSNumber numberWithInt:8901], @"sdot",
                                   [NSNumber numberWithInt:8968], @"lceil",
                                   [NSNumber numberWithInt:8969], @"rceil",
                                   [NSNumber numberWithInt:8970], @"lfloor",
                                   [NSNumber numberWithInt:8971], @"rfloor",
                                   [NSNumber numberWithInt:9001], @"lang",
                                   [NSNumber numberWithInt:9002], @"rang",
                                   [NSNumber numberWithInt:9674], @"loz",
                                   [NSNumber numberWithInt:9824], @"spades",
                                   [NSNumber numberWithInt:9827], @"clubs",
                                   [NSNumber numberWithInt:9829], @"hearts",
                                   [NSNumber numberWithInt:9830], @"diams",
                                   [NSNumber numberWithInt:338], @"OElig",
                                   [NSNumber numberWithInt:339], @"oelig",
                                   [NSNumber numberWithInt:352], @"Scaron",
                                   [NSNumber numberWithInt:353], @"scaron",
                                   [NSNumber numberWithInt:376], @"Yuml",
                                   [NSNumber numberWithInt:710], @"circ",
                                   [NSNumber numberWithInt:732], @"tilde",
                                   [NSNumber numberWithInt:8194], @"ensp",
                                   [NSNumber numberWithInt:8195], @"emsp",
                                   [NSNumber numberWithInt:8201], @"thinsp",
                                   [NSNumber numberWithInt:8204], @"zwnj",
                                   [NSNumber numberWithInt:8205], @"zwj",
                                   [NSNumber numberWithInt:8206], @"lrm",
                                   [NSNumber numberWithInt:8207], @"rlm",
                                   [NSNumber numberWithInt:8211], @"ndash",
                                   [NSNumber numberWithInt:8212], @"mdash",
                                   [NSNumber numberWithInt:8216], @"lsquo",
                                   [NSNumber numberWithInt:8217], @"rsquo",
                                   [NSNumber numberWithInt:8218], @"sbquo",
                                   [NSNumber numberWithInt:8220], @"ldquo",
                                   [NSNumber numberWithInt:8221], @"rdquo",
                                   [NSNumber numberWithInt:8222], @"bdquo",
                                   [NSNumber numberWithInt:8224], @"dagger",
                                   [NSNumber numberWithInt:8225], @"Dagger",
                                   [NSNumber numberWithInt:8240], @"permil",
                                   [NSNumber numberWithInt:8249], @"lsaquo",
                                   [NSNumber numberWithInt:8250], @"rsaquo",
                                   [NSNumber numberWithInt:8364], @"euro",
                                   nil];
}
