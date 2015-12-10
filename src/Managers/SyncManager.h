#import <Foundation/Foundation.h>
#import "Board.h"
#import "Th.h"

@interface SyncManager : NSObject <NSXMLParserDelegate> {
}

@property BOOL isSynchronizing;

+ (SyncManager *)sharedManager;

- (BOOL)canSync;
- (void)trySync:(void (^)(BOOL success))completionBlock;
- (void)startAutoSyncIfEnabled;
- (void)startAutoSync;
- (void)stopAutoSync;

@end
