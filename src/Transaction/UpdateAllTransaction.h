//
//  UpdateAllTransaction.h
//  Forest
//

#import "Transaction.h"

@interface UpdateAllTransaction : Transaction

@property (nonatomic) BOOL shouldRemoveObserver;
@property (nonatomic) NSMutableArray *pendingThreads;
@property (nonatomic) NSUInteger allCount;

- (BOOL) startTransaction ;
- (void) updateAll:(NSArray *)thList ;
@end
