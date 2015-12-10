//
//  TransactionNavigationVC.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "Transaction.h"
#import "Th.h"
#import "MainVC.h"
#import "DynamicBaseVC.h"
#import "ActionMenuBase.h"
#import "PostNaviVC.h"

@interface TransactionNavigationVC : BaseModalNavigationVC <TransactionDelegate, UINavigationControllerDelegate>

@property (nonatomic) BOOL canBack;
@property (nonatomic) NSMutableArray *transactions;

- (BOOL)startTransaction:(Transaction *)transaction;
- (void)closeTransaction:(Transaction *)transaction;

- (BOOL)canNavigate;
- (BOOL)canNavigate:(Transaction *)exceptTransaction;
@end
