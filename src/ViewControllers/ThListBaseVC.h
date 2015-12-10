//
//  ThListBaseViewController.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "DynamicBaseVC.h"
#import "ThVm.h"

@class ThVm;
@protocol ThVmDelegate;

@class Th;
@class ThItemActionMenu;

@interface ThListBaseVC : DynamicBaseVC <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) BOOL hasSections;
@property (nonatomic) BOOL isTabInMain;

- (void)onThVmPropertyChanged:(ThVm *)thVm name:(NSString *)propertyName;

- (ThVm *)genThVm:(Th *)th;

@end
