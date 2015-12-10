
#include "LinkNode.h"

@interface LinkNode ()

@property(nonatomic, readwrite) BOOL isImageLink;

@end

@implementation LinkNode

- (BOOL)isImageLink {
    //options:(NSAnchoredSearch | NSCaseInsensitiveSearch | NSBackwardsSearch)
    if (_isImageChecked == NO) {
        NSArray* extList = @[@".jpeg", @".jpg", @".jpeg", @".JPEG",@".JPG",
                             @".png", @".PNG",  @".bmp", @".BMP"];

        for(NSString* str in extList) {
            NSRange searchResult = [_realUrl rangeOfString:str ];

            if (searchResult.location != NSNotFound) {
                _isImageLink = YES;
                break;
            }
        }
        if (_isImageLink) {
            if ([_realUrl hasSuffix:@".html"] || [_realUrl hasSuffix:@".htm"]) {
                _isImageLink = NO;
            }
            if ([_realUrl hasPrefix:@"sssp://"]) {
                _isImageLink = NO;
            }
        }
        _isImageChecked = YES;
    }
    return _isImageLink;
}

- (id)initWithUrl:(NSString *)hrefAttr {
    if (self = [super init]) {
        _isImageChecked = NO;
        if ([hrefAttr hasPrefix:@"ttp"]) {
            _accessUrl = [NSString stringWithFormat:@"h%@", hrefAttr];
            _realUrl = hrefAttr;
        }
        else {
            _realUrl = _accessUrl = hrefAttr;
        }
    }
    return self;
}

- (id)initWithUrl:(NSString *)realUrl
    withAccessUrl:(NSString *)accessUrl {
    if (self = [super init]) {
        _isImageChecked = NO;
        _realUrl = realUrl;
        _accessUrl = accessUrl;
    }
    return self;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"[[%@,%@]]", _realUrl, _accessUrl];
}


- (NSString *)getText {
    return _realUrl;
}

- (NSString *)getUrl {
    return _accessUrl;
}


@end
