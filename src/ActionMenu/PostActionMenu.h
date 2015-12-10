#import <UIKit/UIKit.h>
#import "ThVm.h"
#import "ThListBaseVC.h"
#import "ActionMenuBase.h"

@class BaseModalNavigationVC;

@interface PostActionMenu : ActionMenuBase

@property (nonatomic) UIViewController *targetViewController;

@property (nonatomic) BOOL isBoardContext;
@property (nonatomic) BOOL isFavContext;
@property (nonatomic) BOOL isHistoryContext;
@property (nonatomic) UINavigationController *navigationController;

@property (copy, nonatomic) void (^onAddedText)(NSString *text);
@property (copy, nonatomic) void (^onDeleteRequest)(void);
@end
