//
//  Views.m
//  Forest
//

#import "Views.h"

@implementation Views

+ (void)makeSeparator:(UIView *)view
{
    for (NSLayoutConstraint *constraint in view.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeHeight ||
            constraint.firstAttribute == NSLayoutAttributeWidth) {
            constraint.constant = thinLineWidth;
        }
    }
}

+ (void)makeHSeparator:(UIView *)view
{
    for (NSLayoutConstraint *constraint in view.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeHeight) {
            constraint.constant = thinLineWidth;
        }
    }
}
+ (void)makeVSeparator:(UIView *)view
{
    for (NSLayoutConstraint *constraint in view.constraints) {
        if (
            constraint.firstAttribute == NSLayoutAttributeWidth) {
            constraint.constant = thinLineWidth;
        }
    }
}

+ (void)customKeyboardOnSearchBar:(UISearchBar *)searchBar withKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance
{

    for (UIView *subView in searchBar.subviews) {
        if ([subView conformsToProtocol:@protocol(UITextInputTraits)]) {
            [(UITextField *)subView setKeyboardAppearance:keyboardAppearance];
            //[(UITextField *)subView setReturnKeyType:UIReturnKeyDone];
        } else {
            for (UIView *subSubView in [subView subviews]) {
                if ([subSubView conformsToProtocol:@protocol(UITextInputTraits)]) {
                    //      [(UITextField *)subSubView setReturnKeyType:UIReturnKeyDone];
                    [(UITextField *)subSubView setKeyboardAppearance:keyboardAppearance];
                }
            }
        }
    }

    for (UIView *subView in searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            [(UITextField *)subView setKeyboardAppearance:keyboardAppearance];
        }
    }
}

+ (NSLayoutConstraint*) findConstraint:(UIView*)view forAttribute:(NSLayoutAttribute)attr
{
    for (NSLayoutConstraint* ct in view.constraints) {
        if (ct.firstAttribute == attr) {
            return ct;
        }
    }
    
    return nil;
}


+ (void)_constraintParentFit:(UIView *)view withParentView:(UIView *)superView
{
    
    UIView *view1 = view;
    view1.translatesAutoresizingMaskIntoConstraints = NO;
    //superView.translatesAutoresizingMaskIntoConstraints = NO;
    UIEdgeInsets padding = UIEdgeInsetsMake(0, 0, 0, 0);
    
    [superView addConstraints:@[
                                [NSLayoutConstraint constraintWithItem:view1
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:superView
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1.0
                                                              constant:padding.top],
                                
                                [NSLayoutConstraint constraintWithItem:view1
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:superView
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1.0
                                                              constant:padding.left],
                                
                                [NSLayoutConstraint constraintWithItem:view1
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:superView
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0
                                                              constant:-padding.bottom],
                                
                                [NSLayoutConstraint constraintWithItem:view1
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:superView
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                              constant:-padding.right],
                                ]];
}

@end
