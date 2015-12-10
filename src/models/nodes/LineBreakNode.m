

#include "LineBreakNode.h"

@implementation LineBreakNode

- (id)init {
    if ((self = [super init])) {
        count_ = 1;
    }
    return self;
}

- (void) incrementCount{
    count_++;// = count;
}

- (NSString *)getText {
    NSMutableString *car = [NSMutableString stringWithCapacity:20];
    [car setString:@""];
    int i;
    for (i = 0; i < count_; i++) {
        [car appendString:@"\n"];
    }
    return [car description];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[br]*%d" , count_];
    //return @"[br]";
}

@end
