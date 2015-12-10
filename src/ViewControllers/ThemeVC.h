//
//  ThemeManageVC.h
//  Forest
//

#import <UIKit/UIKit.h>

@interface ThemeVC : UIViewController <UITableViewDataSource, UITableViewDelegate, UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UITabBar *tabBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableViewContainer;

@property (weak, nonatomic) IBOutlet UITabBarItem *localTabBarItem;
@property (weak, nonatomic) IBOutlet UITabBarItem *downloadTabBarItem;
@property (weak, nonatomic) IBOutlet UITabBarItem *uploadTabBarItem;
@property (weak, nonatomic) IBOutlet UIView *tabBorder;

@end
