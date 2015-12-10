
#import <Foundation/Foundation.h>
#import "Th.h"

@interface UpdateResult : NSObject

@end

@interface ThUpdater : NSObject

@property (nonatomic) Th *th;
@property (nonatomic) NSInteger tryCount;
@property (nonatomic) NSInteger startResNumber;
@property (nonatomic) BOOL forceReload;
@property (nonatomic) BOOL useReadCGI;
@property (nonatomic) BOOL isItestMode;

@property (nonatomic, copy) NSString *accessUrl;
@property (nonatomic) NSMutableData *receivedData;
@property (copy, nonatomic) void (^completionBlock)(UpdateResult *);
@property (nonatomic) NSHTTPURLResponse *response;
@property (nonatomic) CGFloat progress;

- (id)initWithTh:(Th *)th;

- (UpdateResult *)update;
- (UpdateResult *)update:(void (^)(UpdateResult *))completionBlock;

@end
