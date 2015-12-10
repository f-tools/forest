//  UpdateAllTransaction.m

#import "UpdateAllTransaction.h"
#import "MyNavigationVC.h"
#import "ThUpdater.h"
#import "MySplitVC.h"

@implementation UpdateAllTransaction

- (id)init
{
    if (self = [super init]) {
        _pendingThreads = [NSMutableArray array];
        self.title = @"お気に入りを巡回中・・・";
    }
    return self;
}

- (void)didCancel:(Transaction *)transaction
{
}


- (BOOL)startTransaction
{
    BOOL success = [[MySplitVC  sideNavInstance] startTransaction:self];
    if (success) {
    }

    return success;
}

// ThreadAllUpdater
- (void)updateAll:(NSArray *)thList
{
    for (Th *th in thList) {
        if (th.isDown) continue;
        if (th.isUpdating) {
            continue;
        }

        [self.pendingThreads addObject:th];
    }
    self.allCount = [thList count];

    [self _updateTh];
}

- (void)_updateTh
{
    if (self.isCanceled) return;

    if ([self.pendingThreads count] == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [[MySplitVC  sideNavInstance] closeTransaction:self];
        });
        return;
    }

    Th *th = [self.pendingThreads objectAtIndex:0];
    [self.pendingThreads removeObjectAtIndex:0];

    NSUInteger count = [self.pendingThreads count];
    CGFloat progressValue = (count == 0) ? 1 : (self.allCount - count) / ((CGFloat)self.allCount);
    dispatch_async(dispatch_get_main_queue(), ^{
      [self changeProgress:progressValue];
    });

    __weak typeof(self) weakSelf = self;
    ThUpdater *updater = [[ThUpdater alloc] initWithTh:th];
    [updater update:^(UpdateResult *result) {
      [weakSelf _updateTh];
    }];
}


- (void)dealloc
{
}

@end
