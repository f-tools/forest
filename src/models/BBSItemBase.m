
#import "BBSItemBase.h"
#import "BoardManager.h"
#import "Env.h"

@class Board;
@implementation BBSItemBase

@synthesize url = _url;
@synthesize host = _host;
@synthesize serverDir = _serverDir;
@synthesize boardKey = _boardKey;
@synthesize lastModified = _lastModified;

- (BOOL)is2ch
{
    return self.host != nil && self.boardKey != nil && [self.host hasSuffix:@".2ch.net"];
}

- (BOOL)isShitaraba
{
    return _host != nil && ([_host rangeOfString:@"jbbs.shitaraba.net"].location != NSNotFound || [_host rangeOfString:@"jbbs.livedoor.jp"].location != NSNotFound);
}

- (BOOL)isMachiBBS
{
    return _host != nil && [_host rangeOfString:@"machi.to"].location != NSNotFound;
}

- (BOOL)isPink
{
    return _host != nil && [_host hasSuffix:@"bbspink.com"];
}

- (BBSSubType)getBBSSubType
{
    return [self isShitaraba] ? BBSST_SHITARABA : ([self isMachiBBS] ? BBSST_MACHI : BBSST_2CH_COMP);
}

- (void)refreshBoardInfo
{
    Board *b = [[BoardManager sharedManager] boardForUniqueKey:[self boardUniqueKey]];

    if (b != nil) {
        self.host = b.host;
        self.url = b.url;

        self.boardKey = b.boardKey;
        self.lastModified = b.lastModified;
        self.serverDir = b.serverDir;
    }
}

- (NSString *)escape2:(NSString *)str
{
    return [self escape2:str includeSurrogate:YES];
}
- (NSString *)escape2:(NSString *)str includeSurrogate:(BOOL)surrogate
{

    __block NSMutableString *temp = [NSMutableString stringWithCapacity:[str length]];

    [str enumerateSubstringsInRange:NSMakeRange(0, [str length])
                            options:NSStringEnumerationByComposedCharacterSequences
                         usingBlock:
                             ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {

                               const unichar high = [substring characterAtIndex:0];
                               NSString *escapedUrlString = [self percentEscape:substring];

                               if (escapedUrlString != nil) {
                                   [temp appendString:escapedUrlString];
                               } else if (surrogate) {

                                   if ([substring length] == 2) {
                                       const unichar low = [substring characterAtIndex:1];
                                       [temp appendString:[self percentEscape:[NSString stringWithFormat:@"&#%d;&#%d;", high, low]]];
                                   } else {
                                       [temp appendString:[self percentEscape:[NSString stringWithFormat:@"&#%d;", high]]]; // U+2100-26FF
                                   }
                               }
                             }];

    return temp;
}


- (NSString *)percentEscape:(NSString *)str
{
    NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (CFStringRef)str,
        NULL,
        (CFStringRef) @"!*'();:@&=+$,/?%#[]<>",
        //                kCFStringEncodingUTF8 ));
        ([self boardEncoding] == NSJapaneseEUCStringEncoding ? kCFStringEncodingEUC_JP : kCFStringEncodingShiftJIS)));
    return escapedUrlString;
}

//newTh ? 新規スレッドモード: レス投稿モード
- (NSString *)createPostData:(BOOL)newTh name:(NSString *)name mail:(NSString *)mail text:(NSString *)text subjectOrKey:(NSString *)subjectOrKey
{
    NSUInteger interval = [[NSDate date] timeIntervalSince1970];
    if ([self isShitaraba]) {
        long epoc_time = interval;
        epoc_time -= 60 * 15;

        NSMutableString *buf = [[NSMutableString alloc] init]; //new StringBuilder();
        NSArray *components = [self.boardKey componentsSeparatedByString:@"/"];
        if ([components count] == 0)
            return nil;

        NSString *board_dir = [components objectAtIndex:0];
        NSString *board_id = [components objectAtIndex:1];
        [buf appendFormat:@"DIR=%@", [self percentEscape:board_dir]];
        [buf appendFormat:@"&BBS=%@", [self percentEscape:board_id]];
        if (newTh) {
            [buf appendFormat:@"&SUBJECT=%@", [self escape2:subjectOrKey]];
        } else {
            [buf appendFormat:@"&KEY=%@", subjectOrKey];
        }
        [buf appendFormat:@"&TIME=%lu", epoc_time];
        [buf appendFormat:@"&NAME=%@", [self escape2:name]];
        [buf appendFormat:@"&MAIL=%@", [self escape2:mail]];
        [buf appendFormat:@"&MESSAGE=%@", [self escape2:text]];
        [buf appendFormat:@"&submit=%@", newTh ? [self percentEscape:@"新規スレッド作成"] : @"%BD%F1%A4%AD%B9%FE%A4%E0"];

        return buf;

    } else if ([self isMachiBBS]) {
        long epoc_time = interval;
        epoc_time -= 60 * 15;

        NSMutableString *buf = [[NSMutableString alloc] init];

        [buf appendFormat:@"BBS=%@", [self percentEscape:self.boardKey]];
        if (newTh) {
            [buf appendFormat:@"&SUBJECT=%@", [self escape2:subjectOrKey includeSurrogate:NO]];
        } else {
            [buf appendFormat:@"&KEY=%@", subjectOrKey];
        }
        [buf appendFormat:@"&TIME=%lu", epoc_time];
        [buf appendFormat:@"&NAME=%@", [self escape2:name includeSurrogate:NO]];
        [buf appendFormat:@"&MAIL=%@", [self escape2:mail includeSurrogate:NO]];
        [buf appendFormat:@"&MESSAGE=%@", [self escape2:text includeSurrogate:NO]];
        [buf appendFormat:@"&submit=%@", newTh ? [self percentEscape:@"新規スレッド作成"] : @"%8F%91%82%AB%8D%9E%82%DE"];

        return buf;

    } else {
        long epoc_time = interval;
        epoc_time -= 60 * 15;

        NSMutableString *buf = [[NSMutableString alloc] init];

        [buf appendFormat:@"bbs=%@", [self percentEscape:self.boardKey]];
        if (newTh) {
            [buf appendFormat:@"&subject=%@", [self escape2:subjectOrKey]];
        } else {
            [buf appendFormat:@"&key=%@", subjectOrKey];
        }
        [buf appendFormat:@"&time=%lu", epoc_time];
        [buf appendFormat:@"&FROM=%@", [self escape2:name]];
        [buf appendFormat:@"&mail=%@", [self escape2:mail]];
        [buf appendFormat:@"&MESSAGE=%@", [self escape2:text]];
        [buf appendFormat:@"&submit=%@", newTh ? [self percentEscape:@"新規スレッド作成"] : @"%8F%91%82%AB%8D%9E%82%DE"];

        return buf;
    }
    return nil;
}

- (NSString *)getBoardFolderPath:(BOOL)create
{
    NSString *boardDir = nil;
    NSString *logRoot = [Env logRootPath];
    if (logRoot == nil) {
        return nil;
    }
    //
    // .2ch.net
    // .machi.to
    // .bbspink.com
    // external.com
    // jbbs.shitaraba.net
    //

    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *hostFolderName = self.host;
    if ([self is2ch]) {
        hostFolderName = @".2ch.net";
    } else if ([self isMachiBBS]) {
        hostFolderName = @".machi.to";
    } else if ([self isPink]) {
        hostFolderName = @".bbspink.com";
    }

    NSString *hostDir = [logRoot stringByAppendingPathComponent:hostFolderName];
    if (create && [fm fileExistsAtPath:hostDir] != YES) {
        NSError *theError = nil;
        if (![fm createDirectoryAtPath:hostDir
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&theError]) {
            // エラーを処理する。
            return nil;
        }
    }

    boardDir = [hostDir stringByAppendingPathComponent:self.boardKey];

    if (create && [fm fileExistsAtPath:boardDir] != YES) {
        NSError *theError = nil;
        if (![fm createDirectoryAtPath:boardDir
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&theError]) {
            // エラーを処理する。
            return nil;
        }
    }

    return boardDir;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _host = [decoder decodeObjectForKey:@"host"];
        _url = [decoder decodeObjectForKey:@"url"];
        // _boardName = [decoder decodeObjectForKey:@"boardName"];
        _boardKey = [decoder decodeObjectForKey:@"boardKey"];
        _lastModified = [decoder decodeObjectForKey:@"lastModified"];
        _serverDir = [decoder decodeObjectForKey:@"serverDir"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.host forKey:@"host"];

    [encoder encodeObject:self.boardKey forKey:@"boardKey"];
    [encoder encodeObject:self.lastModified forKey:@"lastModified"];
    [encoder encodeObject:self.serverDir forKey:@"serverDir"];
}

// ホスト情報を含めた板の一意の文字列
- (NSString *)boardUniqueKey
{
    return [NSString stringWithFormat:@"%@_D_%@", [self is2ch] ? @".2ch.net" : self.host, self.boardKey];
}

- (NSStringEncoding)boardEncoding
{
    return [self isShitaraba] ? NSJapaneseEUCStringEncoding : NSShiftJISStringEncoding;
}

+ (NSStringEncoding)boardEncodingWithBBSSubType:(BBSSubType)subType
{
    return subType == BBSST_SHITARABA ? NSJapaneseEUCStringEncoding : NSShiftJISStringEncoding;
}

- (int)getPostResult:(NSString *)returnedBody
{
    if (returnedBody == nil) return POST_RESULT_FAIL;

    if ([self isShitaraba]) {
        NSRange match = [returnedBody rangeOfString:@"書きこみました"];
        return match.location == NSNotFound ? POST_RESULT_FAIL : POST_RESULT_SUCCESS;
    } else if ([self isMachiBBS]) {
        NSRange match = [returnedBody rangeOfString:@"ＥＲＲＯＲ"];
        return match.location == NSNotFound ? POST_RESULT_SUCCESS : POST_RESULT_FAIL;
    } else {
        if ([returnedBody rangeOfString:@"書きこみました"].location != NSNotFound ||
            [returnedBody rangeOfString:@"終わりました"].location != NSNotFound) {
            return POST_RESULT_SUCCESS;
        }

        if ([returnedBody rangeOfString:@"忍法帖を作成します"].location != NSNotFound ||
            [returnedBody rangeOfString:@"書き込み確認"].location != NSNotFound) {
            return POST_RESULT_CONFIRM;
        }

        return POST_RESULT_FAIL;
    }
    return 3;
}

- (NSString *)getPostUrl
{
    if ([self isShitaraba]) {
        return @"http://jbbs.shitaraba.net/bbs/write.cgi/";
    } else if ([self isMachiBBS]) {
        return [NSString stringWithFormat:@"http://%@/bbs/write.cgi", self.host];
    } else {
        NSString *hostArg = self.serverDir == nil ? self.host : [NSString stringWithFormat:@"%@%@", self.host, self.serverDir];
        return [NSString stringWithFormat:@"http://%@/test/bbs.cgi", hostArg];
    }
    return nil;
}

@end
