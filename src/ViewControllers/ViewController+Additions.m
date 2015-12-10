//
//  ViewController+Additions.m
//  Forest
//

#import "ViewController+Additions.h"

@implementation UIViewController (ViewAdditions)

- (BOOL)isViewVisible
{
    return [self isViewLoaded] && self.view.window && !self.view.hidden;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
