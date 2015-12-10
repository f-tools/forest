//
//  Views.h
//  Forest
//

#import <Foundation/Foundation.h>

@interface Views : NSObject

+ (void)makeHSeparator:(UIView *)view;
+ (void)makeSeparator:(UIView *)view;
+ (void)makeVSeparator:(UIView *)view;
+ (void)customKeyboardOnSearchBar:(UISearchBar *)searchBar withKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance;

+ (void)_constraintParentFit:(UIView *)view withParentView:(UIView *)superView;
+ (NSLayoutConstraint*) findConstraint:(UIView*)view forAttribute:(NSLayoutAttribute)attr;

@end
