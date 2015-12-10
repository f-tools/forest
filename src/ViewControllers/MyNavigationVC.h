//
//  MyNavigationViewController.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "Transaction.h"
#import "Th.h"
#import "MainVC.h"
#import "DynamicBaseVC.h"
#import "ActionMenuBase.h"
#import "PostNaviVC.h"
#import "TransactionNavigationVC.h"

@interface MyNavigationVC : TransactionNavigationVC

/* 
PhoneMode: MainVCの次右のDynaic
TabletMode: 一番最初のDynamic 
 */
@property (nonatomic) DynamicBaseVC *firstDynamicVC;

@property (nonatomic) UIViewController *tabletContentVC;

+ (MyNavigationVC *)instance;

- (void)popMyViewController;
- (void)pushResViewControllerWithTh:(Th *)th;
- (void)pushResViewControllerWithTh:(Th *)th withTransaction:(Transaction *)exceptTransaction;
- (void)pushMyViewController:(DynamicBaseVC *)nextViewController;
- (void)pushMyViewController:(DynamicBaseVC *)nextViewController withTransaction:(Transaction *)transaction;
- (void)pushNexViewController;

- (BOOL)containsResVCForTh:(Th*)th;

@end

@interface TabletContentNavigationVC : TransactionNavigationVC

/* 
PhoneMode: MainVCの次右のDynaic
TabletMode: 一番最初のDynamic 

一方topViewControllerは現在のVCを指しているのでこれを用いる
 */
@property (nonatomic) DynamicBaseVC *firstDynamicVC;

+ (TabletContentNavigationVC *)instance;

- (void)popMyViewController;
- (void)pushResViewControllerWithTh:(Th *)th;
- (void)pushResViewControllerWithTh:(Th *)th withTransaction:(Transaction *)exceptTransaction;
- (void)pushMyViewController:(DynamicBaseVC *)nextViewController;
- (void)pushMyViewController:(DynamicBaseVC *)nextViewController withTransaction:(Transaction *)transaction;
- (void)pushNexViewController;

- (BOOL)containsResVCForTh:(Th*)th;

@end
