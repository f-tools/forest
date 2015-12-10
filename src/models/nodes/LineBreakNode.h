
#import <Foundation/Foundation.h>
#include "ResNodeBase.h"

@interface LineBreakNode : ResNodeBase {
@public
    int count_;
}

- (NSString *)getText;
- (id)init;
- (void)incrementCount;

@end
