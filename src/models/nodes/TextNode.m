
#import "TextNode.h"

@implementation TextNode

- (id)init {
    return [super init];
}
- (id)initWithNSString:(NSString *)value {
    if (self = [super init]) {
        _text_ = value;
    }
    return self;
}

//- (void) dealloc {
// myLog(@"dealloc textNOode");

//}

- (NSString *)getText {
    return _text_;
}
- (NSString*) description {
    return _text_;
}

- (void) appendText: (NSString*) text {
    _text_ = [_text_ stringByAppendingString:text];
    //    [NSString stringWithFormat:@"%@%@", _text_, text];//
}

@end
