#import <Foundation/Foundation.h>
#include "Th.h"

@interface NextThreadSearcher : NSObject

- (NSArray *)getNextThreads:(Th *)source entries:(NSArray *)entries;

@end
