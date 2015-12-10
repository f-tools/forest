//
//  BaseModalNavigationController.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "Transaction.h"
#import "Th.h"
#import "ThVm.h"
#import "DynamicBaseVC.h"
#import "ActionMenuBase.h"

@interface BaseModalNavigationVC : UINavigationController


// subclassでオーバーライドすべきテーマ変更メソッド
// @virtual
- (void)themeChanged:(NSNotification *)center;

@end



@interface UIViewController (BaseModalNavigationVC)

@property (nonatomic) BOOL isActionMenuOpen;

@property (nonatomic) ActionMenuBase *actionMenu;


- (void)openActionMenuForTh:(ThVm *)thVm open:(BOOL)open;

- (BOOL)openActionMenu:(ActionMenuBase *)actionMenu;

- (void)closeActionMenu:(UIView *)modalView complete:(void (^)(void))completionBlock;

- (void)setActionMenuBackgroundColor:(UIColor *)color;

- (void)openUrlInDefaultWay:(NSString *)url;

@end
