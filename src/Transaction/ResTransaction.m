//
//  ResTransactionManager.m
//  Forest
//

#import "ResTransaction.h"
#import "MyNavigationVC.h"
#import "HistoryVC.h"
#import "Th+ParseAdditions.h"
#import "ThUpdater.h"
#import "ResVC.h"
#import "AppDelegate.h"

@interface ResTransaction () {
}
@property (nonatomic) BOOL shouldRemoveObserver;
@end

@implementation ResTransaction

- (id)init
{
    if (self = [super init]) {
        self.isNavigationTransaction = YES;
    }
    return self;
}

- (void)addHistory
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      [NSThread sleepForTimeInterval:1];
      [[HistoryVC sharedInstance] addHistory:self.th];
    });
}

- (BOOL)startOpenThTransaction
{
    Th *th = self.th;

    self.title = self.th.title == nil ? [self.th threadUrl] : [self.th.title stringByAppendingString:@" をロード中・・・"];
    BOOL success = [[MyNavigationVC instance] startTransaction:self];

    if (success) {
        self.th.lastReadTime = [[NSDate date] timeIntervalSince1970];

        if (th.localCount > 0 && self.isPushDisabled == NO &&
            th.reading <= th.localCount && th.localCount == th.count && th.localCount > th.read) {

            th.lastReadTime = [[NSDate date] timeIntervalSince1970];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              [th loadResponsesFromLocalFile];
              dispatch_sync(dispatch_get_main_queue(), ^{
                if (self.isPushDisabled == NO) {
                    [[MyNavigationVC instance] pushResViewControllerWithTh:th withTransaction:self];
                } else {
                    [[MyNavigationVC instance] closeTransaction:self];
                }

                [self addHistory];
              });
            });

        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                           ^{

                             dispatch_sync(dispatch_get_main_queue(),
                                           ^{
                                             [self updateWithThread:self.th];
                                             //[self addHistory];
                                           });
                           });
        }
    } 

    return success;
}


- (void)dealloc
{
    @try {
        [self.updater removeObserver:self forKeyPath:@"progress"];
    } @catch (id anException) {

    }

    @try {
        [self.th removeObserver:self forKeyPath:@"isUpdating"];
    } @catch (id anException) {
    }
}

- (void)updateWithThread:(Th *)th
{
    self.updater = [[ThUpdater alloc] initWithTh:th];

    self.th = th;
    [self.updater addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:nil];
    [th addObserver:self forKeyPath:@"isUpdating" options:NSKeyValueObservingOptionNew context:nil];
    self.shouldRemoveObserver = YES;

    //[th clearResponses];
    [th loadResponsesFromLocalFile];

    [self.updater update:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (self.isCanceled) return;

    // 変化した値がなにかを判別

    if ([keyPath isEqual:@"progress"]) {
        CGFloat progressValue = 0.05 + (self.updater.progress == 1 ? 0.95 : self.updater.progress / 1.0526315);
        [self changeProgress:progressValue];
    } else if ([keyPath isEqual:@"isUpdating"]) {

        Th *th = object;
        if (self.th != th) return;

        if (th.isUpdating == YES) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self changeProgress:0.05];
            });

        } else if (th.isUpdating == NO) {

            [th removeObserver:self forKeyPath:@"isUpdating"];

            dispatch_async(dispatch_get_main_queue(), ^{
              [UIView animateWithDuration:0.1
                  delay:0.1
                  options:0
                  animations:^{
                    [self changeProgress:1];

                  }
                  completion:^(BOOL finished) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                      dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.isPushDisabled == NO) {
                            [[MyNavigationVC instance] pushResViewControllerWithTh:th withTransaction:self];
                        } else {
                            [[MyNavigationVC instance] closeTransaction:self];
                        }

                        [self addHistory];
                      });
                    });

                  }];

            });
        }
    }
}

@end
