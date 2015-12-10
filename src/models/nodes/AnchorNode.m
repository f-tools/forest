

#include "AnchorNode.h"

@implementation AnchorNode

@synthesize isClosed = _isClosed;
@synthesize from = _from;
@synthesize to = _to;

- (id)init {
    return [super init];
}
- (id)initWithNumber:(int)number {
    if ((self = [super init])) {
        //_text_ = repText;
        _from = number;
        _to = number;
    }
    return self;
}

- (id)initWithNSString:(NSString *)repText
             andTarget:(NSString *)target {
    if ((self = [super init])) {
        _text_ = repText;
        _from = _to = [self parseIntWithNSString:target];
    }
    return self;
}

- (void) setClosedValue:(int)number {
    _to = number;
    self.isClosed = YES;
}
- (NSString *)getText {
    if (self.isClosed) {
        return [NSString stringWithFormat:@">>%@-%@", @(self.from), @(self.to)];
        
    } else {
        return [NSString stringWithFormat:@">>%@", @(self.from)];
    }
}
- (NSString *)description {
    return [self getText];
}

- (int)parseIntWithNSString:(NSString *)str {
    @try {
        return [str intValue];
    }
    @catch (NSException *e) {
        return 0;
    }
    return 1;
}


@end
