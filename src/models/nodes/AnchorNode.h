
#import <Foundation/Foundation.h>
#import "ResNodeBase.h"

@interface AnchorNode : ResNodeBase {
    BOOL _isClosed; // 123-125 すでに'-'が使われたかどうか
    
    NSInteger _from;
    NSInteger _to;
    NSString *_text_;
    
}

@property(nonatomic) BOOL isClosed;
@property(nonatomic) NSInteger to;
@property(nonatomic) NSInteger from;

- (NSString *)getText;
- (id)init;
- (void) setClosedValue:(int)number;
- (id)initWithNumber:(int)number;
- (id)initWithNSString:(NSString *)repText
             andTarget:(NSString *)target;

- (NSString *)description;
- (int)parseIntWithNSString:(NSString *)str;
@end
