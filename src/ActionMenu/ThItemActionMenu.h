//
//  ThItemActionMenuView.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "ThVm.h"
#import "ActionMenuBase.h"

@interface ThItemActionMenu : ActionMenuBase

@property (nonatomic) ThVm *thVm;
@property (nonatomic) BOOL canEdit;
@property (nonatomic) ThListBaseVC *thListBaseVC;
@property (nonatomic) NSIndexPath *indexPath;

@property (nonatomic) BOOL forCopy;

@end
