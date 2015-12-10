
#import <Foundation/Foundation.h>

@interface UIView (NSObjectProperty)

@property (nonatomic) id object;

- (void)onTabSelected:(UITabBarItem *)tabItem tapTwice:(BOOL)tapTwice;

@end
