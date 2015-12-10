#import <Foundation/Foundation.h>

@interface TextUtils : NSObject {
}

+ (NSString *)decodeString:(NSData *)data encoding:(NSStringEncoding)encoding substitution:(NSString *)subs;
+ (BOOL)ambiguitySearchText:(NSString *)text searchKey:(NSString *)searchKey;
+ (NSString *)replaceAmbiguityString:(NSString *)text;

+ (NSString *)encodeBase64:(NSString *)text;
+ (NSString *)encodeBase64Data:(NSData *)data;
+ (NSData *)decodeBase64:(NSString *)str;

@end
