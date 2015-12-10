#import "GestureManager.h"
#import "TopWindow.h"
#import "Env.h"

@interface GestureEntry : NSObject 

@property (nonatomic, copy) NSArray *directions;

@property (copy, nonatomic) void (^completionBlock)();
@property (copy, nonatomic) NSString * (^nameGetter)();
@property (copy, nonatomic) BOOL (^isEnabled)();

@end
