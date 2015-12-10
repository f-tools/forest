

#import <Foundation/Foundation.h>
#include "ResNodeBase.h"

@interface LinkNode : ResNodeBase {
    BOOL _isImageChecked;
}

@property(nonatomic, copy) NSString* accessUrl;
@property(nonatomic, copy) NSString* realUrl;
@property(nonatomic, readonly) BOOL isImageLink;


- (id)initWithUrl:(NSString *)hrefAttr;

// 投稿されたURLと実際にアクセスする(補完された)URLを別で指定する。
- (id)initWithUrl:(NSString *)realUrl
    withAccessUrl:(NSString *)accessUrl;

- (NSString*) description;

- (NSString *)getText;

- (NSString *)getUrl;
@end
