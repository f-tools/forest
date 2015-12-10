#import "NextThreadSearcher.h"

@interface PointAndEntry : NSObject {
    int _point;
    Th *_th;
}

@property (nonatomic) int point;
@property (nonatomic) Th *th;

- (id)initWithPoint:(int)point withTh:(Th *)target;

@end
@implementation PointAndEntry
@synthesize point = _point;
@synthesize th = _th;
- (id)initWithPoint:(int)point withTh:(Th *)target
{
    if (self = [super init]) {
        self.point = point;
        self.th = target;
    }
    return self;
}

- (NSComparisonResult)compareNo:(PointAndEntry *)pe
{
    if (self.point > pe.point) {
        return NSOrderedAscending;
    } else if (self.point < pe.point) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}
@end

/**
 * 次スレ候補検索
 */
@implementation NextThreadSearcher

- (NSArray *)getNextThreads:(Th *)source entries:(NSArray *)entries
{
    NSString *title = source.title;
    int titleLen = (int)[title length];

    NSMutableArray *foundEntries = [[NSMutableArray alloc] init];

    for (Th *target in entries) {
        if (target == source || target.count >= 1000)
            continue;

        int point = 0;
        NSString *targetTitle = target.title;

        int targetLen = (int)targetTitle.length;
        int d = 2;
        int max = -2 * d + targetLen + titleLen;
        for (int a = d - targetLen; a < max; a++) {
            point += [self point:title targetTitle:targetTitle a:-a];
        }

        if (point > 15) {

            PointAndEntry *pe = [[PointAndEntry alloc] initWithPoint:point withTh:target];
            [foundEntries addObject:pe];
        }
    }

    NSArray *sortedEntries = [foundEntries sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      PointAndEntry *p1 = obj1;
      PointAndEntry *p2 = obj2;

      return p2.point - p1.point;
    }];


    NSMutableArray *results = [[NSMutableArray alloc] init];

    int i = 0;
    for (PointAndEntry *e in sortedEntries) {
        [results addObject:e.th];
        if (i++ > 10)
            break;
    }

    return results;
}

- (int)point:(NSString *)title targetTitle:(NSString *)targetTitle a:(int)a
{

    int len = 0;
    int sum = 0;
    int titleLen = (int)title.length;
    int targetLen = (int)targetTitle.length;
    for (int i = 0; i < titleLen; i++) {
        int t = i + a;

        if (0 <= t && t < targetLen) {
            unichar ch = [title characterAtIndex:i];
            if (ch == [targetTitle characterAtIndex:t]) {
                len++;
            } else {
                if (len > 3) {
                    sum += len * len;
                }
                len = 0;
            }
        }
    }
    if (len > 3)
        sum += 5 * len; // ヒットした長さx2点
    return sum;
}
@end
