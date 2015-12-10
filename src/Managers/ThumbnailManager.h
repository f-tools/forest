#import <Foundation/Foundation.h>
#import "Board.h"
#import "BoardManager.h"
#import "Th.h"
#import "Category.h"
#import "ResVm.h"

@interface ThumbnailManager : NSObject {
}

+ (ThumbnailManager *)sharedManager;
- (void)addRequests:(NSArray *)thumbnailInfoList;
@end
