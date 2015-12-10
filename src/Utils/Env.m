#import "Env.h"
#import "ThemeManager.h"
#import "SyncCrypt.h"

static BOOL _treeEnabled;
static BOOL _treeEnabledLoaded;
static BOOL _autoMarkEnabled;
static NSInteger _treeModeConfig;
static BOOL _anchorPopupTreeEnabled;

static CGFloat _threadTitleSize;
static NSInteger _threadTitleSizeIncrement;
static CGFloat _threadMetaSize;
static NSInteger _threadMetaSizeIncrement;
static CGFloat _resHeaderSize;
static NSInteger _resHeaderSizeIncrement;
static CGFloat _resBodySize;
static NSInteger _resBodySizeIncrement;

static NSInteger _thumbnailSizeType;
static NSInteger _thumbnailMode;

static BOOL _convertScriptChanged;
static NSString *_convertScript;

static NSInteger _orientation;
static BOOL _orientationInitialized;

static BOOL _mine;
static NSMutableDictionary *_confDictionary; // key -> NSNumber

CGFloat screenScale;
CGFloat thinLineWidth;

static NSInteger _userAgentIndex;
static BOOL _userAgentIndexDetermined;

@interface Env ()

@end

@implementation Env

+ (NSString *)userAgent
{
    NSArray *userAgents = @[
        @"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36",
        @"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:36.0) Gecko/20100101 Firefox/36.0",
        @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/600.3.18 (KHTML, like Gecko) Version/8.0.3 Safari/600.3.18",
        @"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36	Chrome 41.0",
        @"Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36	Chrome 40.0",
        @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36",
        @"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36",
        @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:36.0) Gecko/20100101 Firefox/36.0",
        @"Mozilla/5.0 (Windows NT 6.3; WOW64; rv:36.0) Gecko/20100101 Firefox/36.0",
        @"Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36",
        @"Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko",
        @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.76 Safari/537.36",
        @"Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0"
    ];

    if (_userAgentIndexDetermined == NO) {
        _userAgentIndexDetermined = YES;
        _userAgentIndex = arc4random() % [userAgents count];
    }

    return [userAgents objectAtIndex:_userAgentIndex];
    // @"Monazilla/1.00 (Forest)";
}

+ (BOOL)isMine
{
    return _mine;
}

+ (void)saveLastThread:(NSString *)thUrl
{
    [Env setConfString:thUrl forKey:@"lastThread"];
}

+ (NSString *)getLastThread
{
    return [Env getConfStringForKey:@"lastThread" withDefault:nil];
}

+ (BOOL)_isMine
{

    NSUUID *vendorUUID = [UIDevice currentDevice].identifierForVendor;
    //NSLog(@"uuid = %@", vendorUUID.UUIDString);
    //NSUUID *vendorUUID = [UIDevice currentDevice].identifierForVendor;
    //B7679A16-C53A-4581-9090-BAE40724E42E
    BOOL isMine = [@"72683DC0-940E-4421-A0E0-07E4EB5BFEDE" isEqualToString:vendorUUID.UUIDString];

    return isMine;
}

+ (void)initVariables
{
    screenScale = [[UIScreen mainScreen] scale];
    thinLineWidth = 1 / screenScale;

    NSString *localpath = [[NSBundle mainBundle] pathForResource:@"external_script" ofType:@"js"];
    NSString *localjsCode = [NSString stringWithContentsOfFile:localpath encoding:NSUTF8StringEncoding error:nil];
    _convertScript = [Env getConfStringForKey:@"convertScript3" withDefault:localjsCode];
    _convertScriptChanged = YES;

    _anchorPopupTreeEnabled = [Env getConfBOOLForKey:@"anchorPopupTreeEnabled" withDefault:NO];
    _autoMarkEnabled = [Env getConfBOOLForKey:@"autoMarkEnabled" withDefault:YES];
    _treeModeConfig = [Env getConfIntegerForKey:@"treeModeConfig" withDefault:0];

    //thumbnailMode
    _thumbnailMode = [Env getConfIntegerForKey:@"thumbnailMode" withDefault:1];
    _thumbnailSizeType = [Env getConfIntegerForKey:@"thumbnailSizeType" withDefault:1];

    [Env setConfInteger:0 forKey:@"sizeVersion"];

    _threadTitleSizeIncrement = [Env getConfIntegerForKey:@"threadTitleSize" withDefault:0];
    [self setThreadTitleSize:_threadTitleSizeIncrement];
    _threadMetaSizeIncrement = [Env getConfIntegerForKey:@"threadMetaSize" withDefault:0];
    [self setThreadMetaSize:_threadMetaSizeIncrement];
    _resBodySizeIncrement = [Env getConfIntegerForKey:@"resBodySize" withDefault:0];
    [self setResBodySize:_resBodySizeIncrement];
    _resHeaderSizeIncrement = [Env getConfIntegerForKey:@"resHeaderSize" withDefault:0];
    [self setResHeaderSize:_resHeaderSizeIncrement];

    _mine = [self _isMine];
    [Env appVersion];
}

// Document Root Folder
+ (NSString *)documentPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    if (path != nil) {
        NSFileManager *fm = [NSFileManager defaultManager];
        path = [path stringByAppendingPathComponent:@"Forest"];
        if ([fm fileExistsAtPath:path] == NO) {
            NSError *theError = nil;
            if (![fm createDirectoryAtPath:path
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&theError]) {
                // エラーを処理する。
            }
        }
    }

    return path;
}

+ (void)changeConvertScript:(NSString *)script
{

    _convertScriptChanged = YES;
    _convertScript = script;
    [Env setConfString:script forKey:@"convertScript3"];
}

+ (NSString *)getConvertScript:(BOOL)onlyIfChanges
{

    if (onlyIfChanges) {
        if (_convertScriptChanged) {
            _convertScriptChanged = NO;
            return _convertScript;
        } else {
            return nil;
        }
    } else {
        return _convertScript;
    }
}

+ (NSString *)iosVersion
{
    return [[UIDevice currentDevice] systemVersion];
    //  NSArray  *aOsVersions = [[[UIDevice currentDevice]systemVersion] componentsSeparatedByString:@"."];
    // NSInteger iOsVersionMajor  = [[aOsVersions objectAtIndex:0] intValue];

    //    return iOsVersionMajor;
}


// Cydiaアプリではin_versionファイルを設置しておく
+ (BOOL)hasInVersionFile
{
    NSString *appFolderPath = [[NSBundle mainBundle] resourcePath];
    NSString *versionFilePath = [appFolderPath stringByAppendingPathComponent:@"in_version"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:versionFilePath];
}

// in_version
+ (NSString *)appVersion
{
    NSString *appFolderPath = [[NSBundle mainBundle] resourcePath];
    NSString *versionFilePath = [appFolderPath stringByAppendingPathComponent:@"in_version"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:versionFilePath] == NO) {
        return @"1.0";
    }

    NSData *data = [fileManager contentsAtPath:versionFilePath];
    if (data) {
        NSString *str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    return @"1.0";
}


+ (NSString *)themeFolderPath
{
    // 作成するディレクトリのパスを作成
    NSString *themePath = [[self documentPath] stringByAppendingPathComponent:@"theme/"];

    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:themePath] == NO) {
        NSError *theError = nil;
        if (![fm createDirectoryAtPath:themePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&theError]) {
            // エラーを処理する。
        }
    }

    return themePath;
}

+ (NSString *)logRootPath
{
    // 作成するディレクトリのパスを作成
    NSString *logPath = [[self documentPath] stringByAppendingPathComponent:@"log/"];

    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:logPath] == NO) {
        NSError *theError = nil;
        if (![fm createDirectoryAtPath:logPath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&theError]) {
            // エラーを処理する。
        }
    }

    return logPath;
}

+ (void)setAnchorPopupTree:(BOOL)value
{
    if (_anchorPopupTreeEnabled != value) {
        [Env setConfBOOL:value forKey:@"anchorPopupTreeEnabled"];
        _anchorPopupTreeEnabled = value;
    }
}

+ (BOOL)getAnchorPopupTree
{
    return _anchorPopupTreeEnabled;
}

+ (void)setAutoMarkEnabled:(BOOL)enabled
{
    if (_autoMarkEnabled != enabled) {
        [Env setConfBOOL:enabled forKey:@"autoMarkEnabled"];
        _autoMarkEnabled = enabled;
    }
}

+ (NSInteger)getOrientation
{
    if (_orientationInitialized == NO) {
        _orientationInitialized = YES;
        _orientation = [Env getConfIntegerForKey:@"orientation" withDefault:UIInterfaceOrientationMaskAllButUpsideDown];
    }
    return _orientation;
}

+ (void)setOrientation:(NSInteger)orientation
{
    if (orientation != _orientation) {
        [Env setConfInteger:orientation forKey:@"orientation"];
        _orientation = orientation;
    }
}

+ (CGFloat)getStatusBarHeight
{
    return [UIApplication sharedApplication].statusBarHidden ? 0 : (
                                                                       [UIApplication sharedApplication].statusBarFrame.size.height > 100 ? [UIApplication sharedApplication].statusBarFrame.size.width : [UIApplication sharedApplication].statusBarFrame.size.height);
}

+ (CGSize)fixSize:(CGSize)size
{
    NSString *ver = [[UIDevice currentDevice] systemVersion];

    float ver_float = [ver floatValue];

    if (ver_float >= 8.f) {
        return size;
    } else {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        CGFloat returnWidth = size.width;
        CGFloat returnHeight = size.height;
        if (orientation == 0 || orientation == UIInterfaceOrientationPortrait) {

        } else if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            returnWidth = size.height;
            returnHeight = size.width;
        }

        return CGSizeMake(returnWidth, returnHeight);
    }
}

/*
 UIInterfaceOrientationMaskPortrait,
 UIInterfaceOrientationMaskLandscapeLeft,
 UIInterfaceOrientationMaskLandscapeRight,
 UIInterfaceOrientationMaskPortraitUpsideDown,
 UIInterfaceOrientationMaskLandscape,
 UIInterfaceOrientationMaskAll,
 UIInterfaceOrientationMaskAllButUpsideDown,
 
 return [Env getConfOrientation];//UIInterfaceOrientationMaskAllButUpsideDown;
 */

+ (BOOL)getAutoMarkEnabled { return _autoMarkEnabled; }

//Font Size

+ (void)setThreadTitleSize:(NSInteger)size
{
    if (size > 200) size = 200;
    if (size < -200) size = -200;

    _threadTitleSizeIncrement = size;
    _threadTitleSize = 14 + size / 2.f;

    [Env setConfInteger:size forKey:@"threadTitleSize"];

    [[ThemeManager sharedManager] notifyThemeChanged:[NSDictionary dictionaryWithObjectsAndKeys:@"threadTitleSize", @"confChange", nil]];
}

+ (CGFloat)getThreadTitleSize { return _threadTitleSize; }
+ (NSInteger)getThreadTitleSizeIncrement { return _threadTitleSizeIncrement; }

+ (void)setThreadMetaSize:(NSInteger)size
{
    if (size > 200) size = 200;
    if (size < -200) size = -200;
    _threadMetaSize = 11 + size / 2.f;
    _threadMetaSizeIncrement = size;

    [Env setConfInteger:size forKey:@"threadMetaSize"];

    [[ThemeManager sharedManager] notifyThemeChanged:[NSDictionary dictionaryWithObjectsAndKeys:@"threadMetaSize", @"confChange", nil]];
}

+ (CGFloat)getThreadMetaSize { return _threadMetaSize; }
+ (NSInteger)getThreadMetaSizeIncrement { return _threadMetaSizeIncrement; }

+ (void)setResBodySize:(NSInteger)size
{
    if (size > 200) size = 200;
    if (size < -200) size = -200;
    _resBodySize = 14 + size / 2.f;
    _resBodySizeIncrement = size;

    [Env setConfInteger:size forKey:@"resBodySize"];

    [[ThemeManager sharedManager] notifyThemeChanged:[NSDictionary dictionaryWithObjectsAndKeys:@"resBodySize", @"confChange", nil]];
}

+ (CGFloat)getResBodySize { return _resBodySize; }
+ (NSInteger)getResBodySizeIncrement { return _resBodySizeIncrement; }

+ (void)setResHeaderSize:(NSInteger)size
{
    if (size > 200) size = 200;
    if (size < -200) size = -200;
    _resHeaderSize = 12 + size / 2.f;
    _resHeaderSizeIncrement = size;

    [Env setConfInteger:size forKey:@"resHeaderSize"];

    [[ThemeManager sharedManager] notifyThemeChanged:[NSDictionary dictionaryWithObjectsAndKeys:@"resHeaderSize", @"confChange", nil]];
}

+ (CGFloat)getResHeaderSize { return _resHeaderSize; }

+ (NSInteger)getResHeaderSizeIncrement { return _resHeaderSizeIncrement; }

// 0: preserve state
// 1: always tree
// 2: always res order
+ (void)setTreeModeConfig:(NSInteger)index
{
    if (_treeModeConfig != index) {
        [Env setConfInteger:index forKey:@"treeModeConfig"];
        _treeModeConfig = index;
    }
}

+ (NSInteger)getTreeModeConfig
{
    return _treeModeConfig;
}

+ (void)setThumbnailMode:(NSInteger)index
{
    //  if (_thumbnailMode != index) {
    [Env setConfInteger:index forKey:@"thumbnailMode"];
    [[ThemeManager sharedManager] notifyThemeChanged:[NSDictionary dictionaryWithObjectsAndKeys:@"resBodySize", @"confChange", nil]];
    _thumbnailMode = index;
    //    }
}

+ (NSInteger)getThumbnailMode
{
    return _thumbnailMode;
}

+ (void)setThumbnailSizeType:(NSInteger)index
{
    if (_thumbnailSizeType != index) {
        [Env setConfInteger:index forKey:@"thumbnailSizeType"];
        [[ThemeManager sharedManager] notifyThemeChanged:[NSDictionary dictionaryWithObjectsAndKeys:@"resBodySize", @"confChange", nil]];
        _thumbnailSizeType = index;
    }
}

+ (NSInteger)getThumbnailSizeType
{
    return _thumbnailSizeType;
}

+ (void)setTreeEnabled:(BOOL)enabled
{
    if (_treeEnabled != enabled) {
        [Env setConfBOOL:enabled forKey:@"treeEnabled"];
        _treeEnabled = enabled;
        _treeEnabledLoaded = YES;
    }
}

+ (BOOL)getTreeEnabled
{
    if (_treeEnabledLoaded == NO) {
        _treeEnabledLoaded = YES;
        _treeEnabled = [Env getConfBOOLForKey:@"treeEnabled" withDefault:YES];
    }
    return _treeEnabled;
}

+ (void)setConfObject:(NSObject *)obj forKey:(NSString *)key
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      [defaults setObject:obj forKey:key];

      [defaults synchronize];
    });
}

+ (void)setConfString:(NSString *)str forKey:(NSString *)key
{
    [self setConfObject:str forKey:key];
}

+ (void)setEncryptedString:(NSString *)str forKey:(NSString *)key
{
    SyncCrypt *crypt = [[SyncCrypt alloc] init];
    [crypt setKey:@"PO2Ia98zcx7JFIOPW3WEaOIafVWPEKOFjpfwioPf21eOI" withCryptLevel:4];

    NSString *text = [crypt encTitle:str url:@"jfpawoJ28SFDIO2ej2awi27o34oa21w34jmp2134aeao12wOWIFJjfoa234jpafjpawfj"];

    [self setConfString:text forKey:key];
}

+ (NSString *)getEncryptedStringForKey:(NSString *)key withDefault:(NSString *)defaultString
{
    NSString *str = [self getConfStringForKey:key withDefault:defaultString];

    SyncCrypt *crypt = [[SyncCrypt alloc] init];
    [crypt setKey:@"PO2Ia98zcx7JFIOPW3WEaOIafVWPEKOFjpfwioPf21eOI" withCryptLevel:4];

    return [crypt decTitle:str url:@"jfpawoJ28SFDIO2ej2awi27o34oa21w34jmp2134aeao12wOWIFJjfoa234jpafjpawfj"];
}

+ (void)setConfArray:(NSArray *)array forKey:(NSString *)key
{
    [self setConfObject:array forKey:key];
}

+ (void)setConfDictionary:(NSDictionary *)dictionary forKey:(NSString *)key
{
    [self setConfObject:dictionary forKey:key];
}

+ (void)setConfData:(NSData *)data forKey:(NSString *)key
{
    [self setConfObject:data forKey:key];
}

+ (void)setConfURL:(NSURL *)value forKey:(NSString *)key
{
    [self setConfObject:value forKey:key];
}

+ (void)setConfInteger:(NSInteger)value forKey:(NSString *)key
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      [defaults setInteger:value forKey:key];
      [defaults synchronize];
    });
}

+ (void)setConfFloat:(float)value forKey:(NSString *)key
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      [defaults setFloat:value forKey:key];
      [defaults synchronize];
    });
}

+ (void)setConfDouble:(double)value forKey:(NSString *)key
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      [defaults setDouble:value forKey:key];
      [defaults synchronize];
    });
}

+ (void)setConfBOOL:(BOOL)value forKey:(NSString *)key
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      [defaults setBool:value forKey:key];
      [defaults synchronize];
    });
}

+ (id)getConfObjectForKey:(NSString *)key withDefault:(NSObject *)defaultObject
{
    NSObject *obj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return obj ? obj : defaultObject;
}

+ (NSString *)getConfStringForKey:(NSString *)key withDefault:(NSString *)defaultString
{
    NSString *str = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    return str ? str : defaultString;
}

+ (NSArray *)getConfArrayForKey:(NSString *)key withDefault:(NSArray *)defaultValue
{
    NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey:key];
    return array ? array : defaultValue;
}

+ (NSDictionary *)getConfDictionaryForKey:(NSString *)key withDefault:(NSDictionary *)defaultValue
{
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
    return dict ? dict : defaultValue;
}

+ (NSData *)getConfDataForKey:(NSString *)key withDefault:(NSData *)defaultValue
{
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:key];
    return data ? data : defaultValue;
}

+ (NSURL *)getConfURLForKey:(NSString *)key withDefault:(NSURL *)defaultValue
{
    NSURL *value = [[NSUserDefaults standardUserDefaults] URLForKey:key];
    return value ? value : defaultValue;
}

+ (NSInteger)getConfIntegerForKey:(NSString *)key withDefault:(NSInteger)defaultValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[[defaults dictionaryRepresentation] allKeys] containsObject:key]) {
        NSInteger integerValue = [[NSUserDefaults standardUserDefaults] integerForKey:key];
        return integerValue;
    } else {
        return defaultValue;
    }
}

+ (float)getConfFloatForKey:(NSString *)key withDefault:(float)defaultValue
{

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[[defaults dictionaryRepresentation] allKeys] containsObject:key]) {
        float floatValue = [[NSUserDefaults standardUserDefaults] floatForKey:key];
        return floatValue;
    } else {
        return defaultValue;
    }
}

+ (double)getConfDoubleForKey:(NSString *)key withDefault:(double)defaultValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[[defaults dictionaryRepresentation] allKeys] containsObject:key]) {
        double value = [[NSUserDefaults standardUserDefaults] doubleForKey:key];
        return value;
    } else {
        return defaultValue;
    }
}

+ (BOOL)getConfBOOLForKey:(NSString *)key withDefault:(BOOL)defaultValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[[defaults dictionaryRepresentation] allKeys] containsObject:key]) {
        BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:key];
        return value;
    } else {
        return defaultValue;
    }
}


- (void)setDefault
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [NSDictionary dictionary];
    [defaults registerDefaults:dict];
    // synchronize メソッドは失敗する
    myLog(@"synchronize:%d", [defaults synchronize]);
    myLog(@"%@", [defaults objectForKey:@"home"]);
    myLog(@"%@", [defaults objectForKey:@"bookmark"]);
    myLog(@"%ld", (long)[defaults integerForKey:@"font-size"]);
    myLog(@"%d", [defaults boolForKey:@"javascript-enabled"]);
}
@end
