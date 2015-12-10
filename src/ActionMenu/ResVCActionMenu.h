//
//  ResVCActionMenu.h
//  Forest
//

#import "ActionMenuBase.h"
#import "ResVC.h"

@interface ResVCActionMenu : ActionMenuBase

@property (nonatomic) ResVC *resVC;

@property (nonatomic) BOOL forTool; // 他ツール表示

@end
