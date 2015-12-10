
#import <Foundation/Foundation.h>
#import "BBSItemBase.h"

//
// 板
//
@interface Board : BBSItemBase 


@property (nonatomic, copy) NSString *boardName;

+ (Board *)boardFromUrl:(NSString *)url;

- (id)init;

- (NSString *)subjectUrl;
- (NSString *)officialTitle;
- (NSString *)threadUrlWithId:(NSUInteger)longId;
- (NSString *)boardUrl;

@end
