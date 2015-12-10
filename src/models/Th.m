

#include "Th.h"
#include "BoardManager.h"

@implementation Th

@synthesize lastReadTime = _lastReadTime;

- (id)init
{
    if (self = [super init]) {
        _responses = [[NSMutableArray alloc] init];
        _resListById = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        _responses = [[NSMutableArray alloc] init];
        _resListById = [[NSMutableDictionary alloc] init];

        NSSet *myResSet = [decoder decodeObjectForKey:@"myResNumSet"];
        if (myResSet) {
            _myResNumSet = [NSMutableSet setWithSet:myResSet];
        }

        NSNumber *numberNumber = [decoder decodeObjectForKey:@"number"];
        if (numberNumber) {
            _number = [numberNumber integerValue];
        }
        _title = [decoder decodeObjectForKey:@"title"];

        // _key = [decoder decodeObjectForKey:@"key"];
        NSNumber *keyNumber = [decoder decodeObjectForKey:@"key"];
        if (keyNumber) {
            _key = [keyNumber longLongValue];
        }

        NSNumber *datSizeNumber = [decoder decodeObjectForKey:@"datSize"];
        if (datSizeNumber) {
            _datSize = [datSizeNumber longLongValue];
        }

        NSNumber *readNumber = [decoder decodeObjectForKey:@"read"];
        if (readNumber) {
            _read = [readNumber integerValue];
        }

        NSNumber *readingNumber = [decoder decodeObjectForKey:@"reading"];
        if (readingNumber) {
            _reading = [readingNumber integerValue];
        }

        NSNumber *reachedLastReadingNumber = [decoder decodeObjectForKey:@"reachedLastReading"];
        if (reachedLastReadingNumber) {
            _reachedLastReading = [reachedLastReadingNumber integerValue];
        }

        NSNumber *localCountNumber = [decoder decodeObjectForKey:@"localCount"];
        if (localCountNumber) {
            _localCount = [localCountNumber integerValue];
        }

        NSNumber *lastReadTime = [decoder decodeObjectForKey:@"lastReadTime"];
        if (lastReadTime) {
            _lastReadTime = [lastReadTime longLongValue];
        }

        NSNumber *countNumber = [decoder decodeObjectForKey:@"count"];
        if (countNumber) {
            _count = [countNumber integerValue];
        }

        NSNumber *isDownNumber = [decoder decodeObjectForKey:@"isDown"];
        if (isDownNumber) {
            _isDown = [isDownNumber boolValue];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithInteger:self.number] forKey:@"number"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:[NSNumber numberWithUnsignedLongLong:self.key] forKey:@"key"];
    [encoder encodeObject:[NSNumber numberWithUnsignedLongLong:self.datSize] forKey:@"datSize"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.localCount] forKey:@"localCount"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.count] forKey:@"count"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isDown] forKey:@"isDown"];
    [encoder encodeObject:[NSNumber numberWithUnsignedLongLong: self.lastReadTime] forKey:@"lastReadTime"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.read] forKey:@"read"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.reading] forKey:@"reading"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.reachedLastReading] forKey:@"reachedLastReading"];

    [encoder encodeObject:self.myResNumSet forKey:@"myResNumSet"];

    [super encodeWithCoder:encoder];
}

+ (Th *)thWithUrl:(NSString *)url
{
    return [Th thFromUrl:url];
}
+ (Th *)thFromUrl:(NSString *)url
{
    Th *newTh;

    if (url == nil) return nil;

    NSURL *nsurl = [[NSURL alloc] initWithString:url];

    if ([nsurl.host hasSuffix:@"jbbs.shitaraba.net"] || [nsurl.host hasSuffix:@"jbbs.livedoor.jp"]) {

        Th *th = [[Th alloc] init];
        NSString *host = nsurl.host;
        th.host = host;
        NSArray *pathComponents = nsurl.pathComponents;
        NSUInteger componentsCount = [pathComponents count];

        @try {
            th.key = [[pathComponents objectAtIndex:5] longLongValue];
            th.boardKey = [NSString stringWithFormat:@"%@/%@", [pathComponents objectAtIndex:3], [pathComponents objectAtIndex:4]];

            if (6 < componentsCount) {
                th.tempHighlightResNumber = [[pathComponents objectAtIndex:6] integerValue];
            }

        } @catch (NSException *e) {
        }
        newTh = th;
    } else {
        newTh = [Th thWithNSUrl:nsurl];
        if (newTh == nil) {
            return nil;
        }
    }

    newTh.url = url;
    return newTh;
}

- (BOOL)is2chDotNet
{
    return [self.host hasPrefix:@".2ch.net"];
}

- (NSInteger)unreadCount
{
    NSInteger uc = self.count - self.read;
    return uc > 0 ? uc : 0;
}

/**
 * スレが立ってから今の間に１日あたり何レス書き込まれたか 60 * 60 * 24 = 86400
 */
- (float)calcSpeed
{
    NSUInteger interval = [[NSDate date] timeIntervalSince1970];
    unsigned long long span = (interval) - (self.key);
    float speed = (self.count * (86400)) / (CGFloat)(span);

    // speed = Math.round(speed * 10) / 10f;// 小数第一位までとする
    if (speed < 0)
        speed = 0;
    self.speed = speed;

    return speed;
}

//勢いを計算していないと思われる場合のみ
//勢いによる並び替えをするときに使われる
- (void)calcSpeedIfNot
{
    if (self.speed == 0) {
        [self calcSpeed];
    }
}

- (BOOL)isOver1000
{
    if ([self is2ch]) {
        //        NSString* datPath = [self datFilePath:NO];
        //        NSFileManager* fm = [NSFileManager defaultManager];
        //
        //        NSDictionary *attributes = [fm attributesOfItemAtPath:datPath error:NULL];
        //        unsigned long long fileSize = [attributes fileSize];
        //
        //myLog(@"th dataSize = %lld", fileSize);
        //self.th.datSize = fileSize;
        return self.count > 1000 || self.datSize > 512000;
    }

    return self.count > 1000;
    //    return NO;
}

- (NSString *)datFilePath
{
    return [self datFilePath:YES];
}

- (NSString *)datFilePath:(BOOL)create
{
    NSString *boardFolderPath = [self getBoardFolderPath:create];
    NSString *datPath = [boardFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%llu.dat", self.key]];
    return datPath;
}

- (NSString *)infoFilePath
{
    return [self infoFilePath:YES];
}

- (NSString *)infoFilePath:(BOOL)create
{
    NSString *boardFolderPath = [self getBoardFolderPath:create];
    NSString *infoPath = [boardFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.info", (unsigned long)self.key]];
    return infoPath;
}

- (BOOL)hasInfoFile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *infoPath = [self infoFilePath:NO];
    return [fm fileExistsAtPath:infoPath];
}

- (Res *)resAtNumber:(NSInteger)number
{
    if (self.responses) {
        if (number - 1 < [self.responses count]) {
            Res *res = [self.responses objectAtIndex:number - 1];
            return res;
        }
    }
    return nil;
}

+ (id)thWithNSUrl:(NSURL *)url
{

    NSString *host = url.host;

    BOOL isMachi = [host hasSuffix:@"machi.to"];
    Th *th = [[Th alloc] init];
    th.host = host;

    // 例えば板URLがhttp://maguro.com/subdir/test/read.cgi/board/123414214244
    // hostとは別にserverDir: subdirを保持する
    // 形式も考慮し、最後の一つのみを板のキーとして判定する。
    NSString *hostAppend = @"";
    BOOL hasServerDir = NO;
    int testIndex = 0;
    NSString *startString = isMachi ? @"bbs" : @"test";
    BOOL foundStart = NO;

    NSUInteger count = url.pathComponents.count;

    for (NSString *component in url.pathComponents) {
        if ([component isEqualToString:startString]) {
            foundStart = YES;
            break;
        }

        testIndex++;
        if (component == nil || [component isEqualToString:@"/"] || [component isEqualToString:@""]) continue;

        hostAppend = [NSString stringWithFormat:@"%@%@", hostAppend, [NSString stringWithFormat:@"/%@", component]];

        hasServerDir = YES;
    }

    if (foundStart == NO) {
        return nil;
    }

    if (hasServerDir) {
        th.serverDir = hostAppend;
    }

    if (count > testIndex + 3) {
        NSString *boardKey = [url.pathComponents objectAtIndex:testIndex + 2];
        NSString *key = [url.pathComponents objectAtIndex:testIndex + 3];
        th.key = [key longLongValue];
        th.boardKey = boardKey;

        NSUInteger count = [url.pathComponents count];
        if (testIndex + 4 < count) {
            th.tempHighlightResNumber = [[url.pathComponents objectAtIndex:testIndex + 4] integerValue];
            if (th.tempHighlightResNumber > 0) {
                th.reading = th.tempHighlightResNumber;
            }
        }
    } else {
        return nil;
    }

    return th;
}

- (NSString *)description
{
    return _title;
}

- (NSString *)datUrl
{
    if ([self isShitaraba]) {
        return [NSString stringWithFormat:@"http://jbbs.shitaraba.net/bbs/rawmode.cgi/%@/%llu/%lu-", self.boardKey, self.key, (long)(self.localCount + 1)];
    } else if ([self isMachiBBS]) {
        return [NSString stringWithFormat:@"http://%@/bbs/offlaw.cgi/%@/%llu/%lu-", self.host, self.boardKey, self.key, (long)(self.localCount + 1)];
    } else {
        NSString *hostArg = self.serverDir == nil ? self.host : [NSString stringWithFormat:@"%@%@", self.host, self.serverDir];
        return [NSString stringWithFormat:@"http://%@/%@/dat/%llu.dat", hostArg, self.boardKey, self.key];
    }
}

- (NSString *)threadUniqueKey
{
    return [NSString stringWithFormat:@"%@<>%lu", self.boardUniqueKey, (unsigned long)self.key];
}

- (NSString *)threadUrl
{
    if ([self isShitaraba]) {
        return [NSString stringWithFormat:@"http://%@/bbs/read.cgi/%@/%llu/", self.host, self.boardKey, self.key];
    } else if ([self isMachiBBS]) {
        return [NSString stringWithFormat:@"http://%@/bbs/read.cgi/%@/%llu/", self.host, self.boardKey, self.key];
    } else {
        if (self.boardKey != nil) {
            NSString *hostArg = self.serverDir == nil ? self.host : [NSString stringWithFormat:@"%@%@", self.host, self.serverDir];
            return [NSString stringWithFormat:@"http://%@/test/read.cgi/%@/%llu/", hostArg, self.boardKey, self.key];
        }
        return self.url;
    }
}

- (NSComparisonResult)compareNumber:(Th *)th
{
    if (self.number < th.number) {
        return NSOrderedAscending;
    } else if (self.number > th.number) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSComparisonResult)compareSpeed:(Th *)th
{
    [self calcSpeedIfNot];
    [th calcSpeedIfNot];

    if (self.count >= 1000 && th.count < 1000)
        return NSOrderedDescending;
    else if (th.count >= 1000 && self.count < 1000) {
        return NSOrderedAscending;
    } else if (self.speed > th.speed) {
        return NSOrderedAscending;
    } else if (self.speed < th.speed) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSComparisonResult)compareCount:(Th *)th
{
    if (self.count > th.count) {
        return NSOrderedAscending;
    } else if (self.count < th.count) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSComparisonResult)comparelastReadTime:(Th *)th
{
    if (self.lastReadTime > th.lastReadTime) {
        return NSOrderedAscending;
    } else if (self.lastReadTime < th.lastReadTime) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSComparisonResult)compareCreated:(Th *)th
{
    if (self.key > th.key) {
        return NSOrderedAscending;
    } else if (self.key < th.key) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (BOOL)canAppendDatFileWithInt:(NSInteger)responseCode
{
    if ([self isShitaraba]) {
        return YES;

    } else if ([self isMachiBBS]) {
        return YES;

    } else {
        return responseCode != 200;
    }
}


@end
