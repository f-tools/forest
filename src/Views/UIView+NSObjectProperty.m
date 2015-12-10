#import "UIView+NSObjectProperty.h"
#import <objc/runtime.h>

@implementation UIView (NSObjectProperty)

- (id)object
{
    return objc_getAssociatedObject(self, @selector(setObject:));
}

- (void)setObject:(id)value
{
    objc_setAssociatedObject(self, _cmd, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
