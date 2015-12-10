//
//  ResTransactionManager.h
//  Forest
//

#import <Foundation/Foundation.h>
#import "Th.h"
#import "Transaction.h"
#import "ResVC.h"

@class ThUpdater;

@interface ResTransaction : Transaction

@property (nonatomic) Th *th;
@property (nonatomic) BOOL isPushDisabled;

@property (nonatomic) ThUpdater *updater;
@property (nonatomic) ResVC *resViewController;

- (BOOL) startOpenThTransaction;

@end
