//
//  MySplitVC.h
//  Forest
//

#import <UIKit/UIKit.h>

@class MyNavigationVC;
@class PostNaviVC;
@class ThListBaseVC;

@interface MySplitVC : UIViewController

@property (nonatomic) BOOL isTabletMode;

@property (nonatomic) MyNavigationVC *phoneMyNavigationVC;

@property (nonatomic) MyNavigationVC *leftMyNavigationVC;

@property (nonatomic) MyNavigationVC *rightMyNavigationVC;

@property (nonatomic) UIView *verticalTabBar;

+ (MySplitVC *)instance;

/*
 * サイド優先のMyNavVCを取得します
 */
+ (MyNavigationVC *)sideNavInstance;

- (PostNaviVC *)sharedCreatePostNaviVC;
- (PostNaviVC *)sharedPostNaviVC;

- (void)moveToConfig;

- (void)changeTabletMode:(BOOL)enabled;

- (MyNavigationVC *)resParentMyNavigationVC;

- (CGFloat)thListTableViewWidth:(ThListBaseVC *)thListVC;

@end
