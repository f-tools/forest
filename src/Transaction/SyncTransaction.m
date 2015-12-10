//
//  SyncTransaction.m
//  Forest
//

#import "SyncTransaction.h"
#import "MyNavigationVC.h"
#import "ThUpdater.h"
#import "SyncManager.h"

@implementation SyncTransaction


- (id)init
{
    if (self = [super init]) {
        self.title = @"Sync2ch同期中・・・";
    }
    return self;
}

- (BOOL)startTransaction
{
    if ([[SyncManager sharedManager] canSync] == NO) {
        return NO;
    }

    BOOL success = [[MyNavigationVC instance] startTransaction:self];
    if (success) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{
                         [[SyncManager sharedManager] trySync:^(BOOL success) {
                           [self changeTitle:success ? @"同期に成功しました" : @"同期に失敗しました"];
                           if (success) {
                               [self changeProgress:1];
                           }
                           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                             [NSThread sleepForTimeInterval:0.5];

                             dispatch_async(dispatch_get_main_queue(),
                                            ^{
                                              [[MyNavigationVC instance] closeTransaction:self];
                                            });
                           });

                         }];
                       });
    }

    return success;
}


- (void)dealloc
{
}

@end
