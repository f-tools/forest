//#import <Foundation/Foundation.h>
#import "ViewController+Additions.h"

extern CGFloat screenScale;
extern CGFloat thinLineWidth;

@interface Env : NSObject {
}

+ (NSString *)documentPath;
+ (NSString *)userAgent;
+ (BOOL)isMine;

+ (NSString *)logRootPath;
+ (NSString *)themeFolderPath;

+ (void)saveLastThread:(NSString *)thUrl;
+ (NSString *)getLastThread;

+ (void)setTreeEnabled:(BOOL)enabled;
+ (BOOL)getTreeEnabled;
+ (BOOL)getAnchorPopupTree;
+ (void)setAnchorPopupTree:(BOOL)value;

+ (void)changeConvertScript:(NSString *)script;
+ (NSString *)getConvertScript:(BOOL)onlyIfChanges;

+ (NSInteger)getOrientation;
+ (void)setOrientation:(NSInteger)orientation;

+ (CGFloat)getStatusBarHeight;

+ (CGSize)fixSize:(CGSize)size;
+ (void)setAutoMarkEnabled:(BOOL)enabled;
+ (BOOL)getAutoMarkEnabled;
+ (NSString *)appVersion;
+ (NSString *)iosVersion;
+ (BOOL)hasInVersionFile;

// 0: preserve state
// 1: always tree
// 2: always res order
+ (void)setTreeModeConfig:(NSInteger)index;

+ (void)setThreadTitleSize:(NSInteger)size;
+ (CGFloat)getThreadTitleSize;
+ (NSInteger)getThreadTitleSizeIncrement;

+ (void)setThreadMetaSize:(NSInteger)size;
+ (CGFloat)getThreadMetaSize;
+ (NSInteger)getThreadMetaSizeIncrement;

+ (void)setResBodySize:(NSInteger)size;
+ (CGFloat)getResBodySize;
+ (NSInteger)getResBodySizeIncrement;

+ (void)setResHeaderSize:(NSInteger)size;
+ (CGFloat)getResHeaderSize;
+ (NSInteger)getResHeaderSizeIncrement;

+ (NSInteger)getTreeModeConfig;
+ (NSInteger)getThumbnailMode;
+ (NSInteger)getThumbnailSizeType;
+ (void)setThumbnailSizeType:(NSInteger)index;
+ (void)setThumbnailMode:(NSInteger)index;

+ (void)initVariables;

+ (void)setEncryptedString:(NSString *)str forKey:(NSString *)key;

+ (NSString *)getEncryptedStringForKey:(NSString *)key withDefault:(NSString *)defaultString;
+ (void)setConfObject:(NSObject *)obj forKey:(NSString *)key;
+ (void)setConfString:(NSString *)str forKey:(NSString *)key;
+ (void)setConfArray:(NSArray *)array forKey:(NSString *)key;
+ (void)setConfDictionary:(NSDictionary *)dictionary forKey:(NSString *)key;
+ (void)setConfData:(NSData *)data forKey:(NSString *)key;
+ (void)setConfURL:(NSURL *)value forKey:(NSString *)key;
+ (void)setConfInteger:(NSInteger)value forKey:(NSString *)key;
+ (void)setConfFloat:(float)value forKey:(NSString *)key;
+ (void)setConfDouble:(double)value forKey:(NSString *)key;
+ (void)setConfBOOL:(BOOL)value forKey:(NSString *)key;

+ (id)getConfObjectForKey:(NSString *)key withDefault:(NSObject *)defaultObject;
+ (NSString *)getConfStringForKey:(NSString *)key withDefault:(NSString *)defaultString;
+ (NSArray *)getConfArrayForKey:(NSString *)key withDefault:(NSArray *)defaultValue;
+ (NSDictionary *)getConfDictionaryForKey:(NSString *)key withDefault:(NSArray *)defaultValue;
+ (NSData *)getConfDataForKey:(NSString *)key withDefault:(NSData *)defaultValue;
+ (NSURL *)getConfURLForKey:(NSString *)key withDefault:(NSURL *)defaultValue;
+ (NSInteger)getConfIntegerForKey:(NSString *)key withDefault:(NSInteger)defaultValue;
+ (float)getConfFloatForKey:(NSString *)key withDefault:(float)defaultValue;
+ (double)getConfDoubleForKey:(NSString *)key withDefault:(double)defaultValue;
+ (BOOL)getConfBOOLForKey:(NSString *)key withDefault:(BOOL)defaultValue;

@end
