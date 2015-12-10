
#import <UIKit/UIKit.h>
#import "ActionMenuBase.h"
#import "BoardVC.h"

@interface BoardActionMenu : ActionMenuBase

@property (nonatomic) Board *board;
@property (nonatomic) BoardVC *boardVC;
@property (nonatomic) BOOL hideFavBoard;

@end
