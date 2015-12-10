//
//  RootViewController.h
//  Forest
//

#import <Foundation/Foundation.h>
#import "FavVC.h"
#import "ThListVC.h"
#import "BoardVC.h"
#import "HistoryVC.h"

#import "ResVC.h"
#import "ResTransaction.h"
#import "DynamicBaseVC.h"

@interface MainVC : UIViewController <UITabBarDelegate>


@property (nonatomic) FavVC *favVC;
@property (nonatomic) BoardVC *boardVC;
@property (nonatomic) HistoryVC *historyVC;

@property (nonatomic) UITabBarItem *favTabItem;
@property (nonatomic) UITabBarItem *boardTabItem;
@property (nonatomic) UITabBarItem *historyTabItem;
@property (nonatomic) UITabBarItem *moreTabItem;

@property (nonatomic) UITabBarItem *currentTabItem;

@property (strong, nonatomic) IBOutlet UIView *rootView;
@property (weak, nonatomic) IBOutlet UIView *mainContainerView;
@property (weak, nonatomic) IBOutlet UIView *lineOverTabbar;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *titleBarItem;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabbarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineTopBarHeightConstraint;

@property (nonatomic, copy) NSString *requestOpenThreadUrl;


+ (MainVC *)instance;

- (void)hideTabBar;
- (void)showTabBar;
- (void)updateNavigationBarButtons;
- (void)onBackFromModalView;
//- (BOOL)startOpenTh:(Th *)th;
- (void)showThListVC:(UIViewController *)thListVC;

- (void)setFavTabBarBadge:(NSString *)value;
@end
