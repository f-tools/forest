
#import <Foundation/Foundation.h>
#import "ResNodeBase.h"

@interface TextNode : ResNodeBase {
@public
    NSString *_text_;
}

- (id)init;
- (id)initWithNSString:(NSString *)value;
- (NSString *)getText;
- (NSString*) description;
- (void) appendText: (NSString*) text;
@end
