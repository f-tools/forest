//
//  SyncTransaction.h
//  Forest
//

#import "Transaction.h"

@interface SyncTransaction : Transaction

@property (nonatomic) BOOL shouldRemoveObserver;
@property (nonatomic) NSMutableArray *pendingThreads;
@property (nonatomic) NSUInteger allCount;

- (BOOL) startTransaction;
@end
