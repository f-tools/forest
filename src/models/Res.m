
#import "Res.h"
#import "nodes/LinkNode.h"
#import "nodes/TextNode.h"
#import "LineBreakNode.h"


@implementation Res

- (id)init
{
    if (self = [super init]) {
        _name = @"";
        _text = @"";
    }
    return self;
}

- (void) dealloc {
  // myLog(@"res delloc %d", self.number);
}

- (NSString *)allText
{
    NSMutableString *text = [NSMutableString string];
    [text appendFormat:@"%d", self.number];
    [text appendFormat:@" %@", self.name];
    if (self.mail) [text appendFormat:@" %@", self.mail];
    if (self.dateStr) [text appendFormat:@" %@", self.dateStr];
    if (self.timeStr) [text appendFormat:@" %@", self.timeStr];
    if (self.ID) [text appendFormat:@" ID:%@", self.ID];

    [text appendString:@"\n"];
    [text appendString:[self naturalText]];

    return text;
}

- (NSString *)naturalText
{
    if (self.bodyNodes == nil) return nil;

    NSMutableString *mutableStr = [[NSMutableString alloc] init];
    for (ResNodeBase *node in self.bodyNodes) {
        if ([node isKindOfClass:[LineBreakNode class]]) {
            [mutableStr appendString:[node getText]];
        } else {
            NSString *trimmed = [[node getText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [mutableStr appendString:trimmed];
        }
    }
    return mutableStr;
}

- (NSString *)naturalTextForCheckMyRes
{
    if (self.bodyNodes == nil) return nil;

    NSMutableString *mutableStr = [[NSMutableString alloc] init];
    BOOL first = YES;
    for (ResNodeBase *node in self.bodyNodes) {
        if (first) {
            if ([node isKindOfClass:[LinkNode class]]) {
                LinkNode *linkNode = (LinkNode *)node;
                if ([[linkNode getText] hasPrefix:@"sssp://"]) {
                    continue;
                }
            }
            first = NO;
        }
        if ([node isKindOfClass:[LineBreakNode class]]) {
            [mutableStr appendString:[node getText]];
        } else {
            NSString *trimmed = [[node getText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [mutableStr appendString:trimmed];
        }
    }
    NSString *result = [mutableStr stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];

    return result;
}

- (BOOL)hasLink
{
    for (ResNodeBase *node in self.bodyNodes) {
        if ([node isKindOfClass:[LinkNode class]]) {
            return YES;
        }
    }
    return NO;
}

- (void)checkHasImage
{
    if (self.hasImageChecked) {
        return;
    }
    self.hasImageChecked = YES;

    for (ResNodeBase *node in self.bodyNodes) {
        if ([node isKindOfClass:[LinkNode class]]) {
            LinkNode *linkNode = (LinkNode *)node;
            if ([linkNode isImageLink]) {
                self.hasImage = YES;
                break;
            }
        }
    }
}

- (BOOL)checkIsAA
{
    return self.isAA;
}

- (long long int)basicBEId
{
    @try {
        long long int i = [self.BEID intValue];
        if (i == 0) {
            return 0;
        }
        i = ((long long int)(i / 100) + ((long long int)(i / 10) % 10) - (i % 10) - 5) / (((long long int)(i / 10) % 10) * (i % 10) * 3);
        return i;
    }
    @catch (NSException *e) {
    }
    return 0;
}

- (NSString *)description
{
    return _date;
}

@end
