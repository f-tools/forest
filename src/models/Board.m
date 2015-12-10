
#import "Board.h"

@implementation Board

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        _boardName = [decoder decodeObjectForKey:@"boardName"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.boardName forKey:@"boardName"];
}

- (id)init
{
    if (self = [super init]) {
    }

    return self;
}

//
// (Board*) boardFromUrl:(NSString*)url
//
// 板のURLから板オブジェクトを生成
// 生成できなかった場合はnilを返す
+ (Board *)boardFromUrl:(NSString *)url
{
    Board *bd = [[Board alloc] init];
    bd.url = url;

    NSURL *nsurl = [[NSURL alloc] initWithString:url];
    if (nsurl == nil) return nil;

    NSString *host = nsurl.host;
    NSArray *pathComponents = nsurl.pathComponents;

    if ([nsurl.host hasSuffix:@"jbbs.shitaraba.net"] || [nsurl.host hasSuffix:@"jbbs.livedoor.jp"]) {

        NSString *host = nsurl.host;
        bd.host = host;
        NSArray *pathComponents = nsurl.pathComponents;

        //したらばはカテゴリと番号が必要
        if ([pathComponents count] < 3) {
            return nil;
        }

        @try {
            bd.boardKey = [NSString stringWithFormat:@"%@/%@", [pathComponents objectAtIndex:1], [pathComponents objectAtIndex:2]];
        } @catch (NSException *e) {
            return nil;
        }
    } else {

        int count = (int)[pathComponents count];

        NSString *hostAppend = @"";
        BOOL hasServerDir = NO;

        int index = 0;
        NSString *boardKey = nil;
        for (NSString *component in pathComponents) {
            if (index == count - 1) { //last
                if (index != 0) {
                    boardKey = component;
                }
                break;
            } else {
                if (component == nil || [component isEqualToString:@"/"] || [component isEqualToString:@""]) {
                } else {
                    hostAppend = [NSString stringWithFormat:@"%@%@", hostAppend, [NSString stringWithFormat:@"/%@", component]];
                    hasServerDir = YES;
                }
            }
            index++;
        }

        if (boardKey == nil) {
            return nil;
        }
        bd.boardKey = boardKey;
        bd.serverDir = hasServerDir ? hostAppend : nil;
        bd.url = url;
        bd.host = host;
    }
    return bd;
}

- (NSString *)boardUrl
{
    if (self.host != nil && self.boardKey != nil) {
        NSString *hostArg = self.serverDir == nil ? self.host : [NSString stringWithFormat:@"%@%@", self.host, self.serverDir];
        return [NSString stringWithFormat:@"http://%@/%@/", hostArg, self.boardKey];
    }
    return self.url;
}


// スレ一覧のURLを返す
- (NSString *)subjectUrl
{
    if ([self isMachiBBS]) {
        return [NSString stringWithFormat:@"http://%@/bbs/offlaw.cgi/%@/", self.host, self.boardKey];
    }

    if (self.host != nil && self.boardKey != nil) {
        return [NSString stringWithFormat:@"http://%@/%@/subject.txt", self.host, self.boardKey];
    }

    return [NSString stringWithFormat:@"%@/subject.txt", self.url];
}

- (NSString *)officialTitle
{
    @try {
    } @catch (NSException *e) {
    }

    return nil;
}

- (NSString *)threadUrlWithId:(NSUInteger)longId
{
    if ([self isShitaraba]) {
        return [NSString stringWithFormat:@"http://%@/bbs/read.cgi/%@/%@/", self.host, self.boardKey, @(longId)];
    } else if ([self isMachiBBS]) {
        return [NSString stringWithFormat:@"http://%@/bbs/read.cgi/%@/%@/", self.host, self.boardKey, @(longId)];
    } else {
        return [NSString stringWithFormat:@"http://%@/test/read.cgi/%@/%@/", self.host, self.boardKey, @(longId)];
    }
}

@end
