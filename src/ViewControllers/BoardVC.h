//
//  BoardViewController.h
//  Forest
//

#import "BaseModalNavigationVC.h"
#import "Board.h"

@class BoardVC;

@class BoardRightViewController;
@class BoardLeftViewController;

@interface BoardSelectNavigationController : BaseModalNavigationVC


@property (nonatomic) BoardVC *boardVC;

@end

@interface BoardVC : UIViewController

@property (nonatomic) BoardLeftViewController *leftViewController;
@property (nonatomic) BoardRightViewController *rightViewController;

@property (weak, nonatomic) IBOutlet UIView *leftTableContainer;
@property (weak, nonatomic) IBOutlet UIView *rightTableContainer;

@property (nonatomic) BOOL selectBoardMode;

@property (copy, nonatomic) void (^completionBlock)(Board *board);

- (void)reloadTable;

@end
