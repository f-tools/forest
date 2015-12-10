#import "Env.h"
#import "ThumbnailManager.h"
#import "ResVm.h"
#import <SDWebImage/SDWebImageManager.h>

@interface ThumbnailManager ()

@property (nonatomic) NSMutableArray *queue;
@property (nonatomic) NSUInteger currentThreadCount;

@end

static ThumbnailManager *_sharedThumbnailManager;

//
// サムネイル管理
//
@implementation ThumbnailManager

- (id)init
{
    if (self = [super init]) {
        _queue = [NSMutableArray array];
    }
    return self;
}

+ (ThumbnailManager *)sharedManager
{
    @synchronized(self)
    {
        if (!_sharedThumbnailManager) {
            _sharedThumbnailManager = [[self alloc] init];
        }
    }
    return _sharedThumbnailManager;
}

- (void)addRequests:(NSArray *)thumbnailInfoList
{
    @synchronized(self.queue)
    {
        // Last In, First Out
        // 追加時には向きをそろえるため、逆順にする。
        // 保持数リミットを超えたときには最初に追加したものから削除
        for (NSInteger i = [thumbnailInfoList count] - 1; i >= 0; i--) {
            ThumbnailInfo *info = [thumbnailInfoList objectAtIndex:i];
            [self.queue addObject:info];
        }

        NSUInteger queueCount = [self.queue count];
        NSUInteger limit = 60;
        if (queueCount > limit) {
            NSMutableArray *removingObjects = [NSMutableArray array];
            for (NSInteger i = 0; i < queueCount - limit; i++) {
                ThumbnailInfo *info = [self.queue objectAtIndex:i];
                info.completion = nil;
                info.progress = nil;

                [removingObjects addObject:info];
            }

            [self.queue removeObjectsInArray:removingObjects];
        }

        for (int i = 0; i < 3;i++) {
            [self _tryStartDownload];
        }
    }

}

- (void)_tryStartDownload
{
    if (self.currentThreadCount > 3) {
        return;
    }

    self.currentThreadCount++;
    [self _startDownload];
}

- (void)_startDownload
{

    @synchronized(self.queue)
    {
        if ([self.queue count] == 0) {
            self.currentThreadCount--;
            return;
        }
        ThumbnailInfo *info = [self.queue lastObject];
        if (!info) {
            self.currentThreadCount--;
            return;
        }

        [self.queue removeLastObject];

        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager downloadImageWithURL:[NSURL URLWithString:info.url]
            options:SDWebImageRetryFailed
            progress:^(NSInteger receivedSize, NSInteger expectedSize) {
              if (info.progress) {
                  info.progress(info, receivedSize, expectedSize);
              }
            }
            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
              if (info.completion) {
                  info.completion(info, image, error, cacheType, finished, imageURL);
              }
              info.completion = nil;
              info.progress = nil;

              [self _startDownload];
            }];
    }
}

@end
