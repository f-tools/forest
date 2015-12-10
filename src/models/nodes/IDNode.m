#include "IDNode.h"

@implementation IDNode

- (id)initWithString:(NSString *)id_ {
    if ((self = [super init])) {
        _idText = id_;
    }
    return self;
}
- (id)initWithString:(NSString *)id_ withSuffix:(NSString*)suffix {
    if ((self = [super init])) {
        _idText = id_;
        _suffix = suffix;
    }
    return self;
    
}


- (NSString *)getText {
    return [NSString stringWithFormat:@"ID:%@", self.idText];
}
- (NSString *)description {
    return [NSString stringWithFormat:@"ID:%@", self.idText];
}

@end
