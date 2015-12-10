#import <UIKit/UIKit.h>
#import "ThVm.h"
#import "ThListBaseVC.h"
#import "ActionMenuBase.h"

@interface TabContextMenu : ActionMenuBase

@property (nonatomic) UIViewController *targetViewController;

@property (nonatomic) BOOL isBoardContext;
@property (nonatomic) BOOL isFavContext;
@property (nonatomic) BOOL isHistoryContext;

@end
