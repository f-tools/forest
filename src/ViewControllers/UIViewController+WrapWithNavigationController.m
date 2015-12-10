#import "UIViewController+WrapWithNavigationController.h"
#import "BaseModalNavigationVC.h"
#import <objc/runtime.h>

@implementation UIViewController (WrapWithNavigationController)

- (UINavigationController *)wrapWithNavigationController
{
    BaseModalNavigationVC *navCon = [[BaseModalNavigationVC alloc] init];

    [navCon pushViewController:self animated:NO];
  //  self.shouldDismiss = YES;

    return navCon;
}


@end
