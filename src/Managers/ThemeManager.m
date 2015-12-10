#import "Env.h"
#import <FMDB/FMDatabase.h>

#define XOYIP_DEFINE_GLOBALS
#import "ThemeManager.h"

static ThemeManager *_sharedThemeManager = nil;

@implementation ThemeEntry

- (void)deleteFile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (self.folderPath && [fm fileExistsAtPath:self.folderPath]) {
        NSError *error;

        BOOL result = [fm removeItemAtPath:self.folderPath error:&error];
        if (result) {
            NSLog(@"ファイルを削除に成功：%@", self.folderPath);
        } else {
            NSLog(@"ファイルの削除に失敗：%@", error.description);
        }
    }
}

@end

@interface ThemeManager ()

@property (nonatomic) NSMutableArray *localThemeEntries;

@property (nonatomic, readwrite) NSMutableDictionary *darkTheme;
@property (nonatomic, readwrite) NSMutableDictionary *lightTheme;
@property (nonatomic, readwrite) NSMutableDictionary *userTheme;

@end

//
// テーマ管理
//
@implementation ThemeManager

@synthesize selectedTheme = _selectedTheme;


+ (ThemeManager *)sharedManager
{
    @synchronized(self)
    {
        if (!_sharedThemeManager) {
            _sharedThemeManager = [[self alloc] init];
        }
    }
    return _sharedThemeManager;
}

- (id)init
{
    if (self = [super init]) {
        _lightTheme = [ThemeManager createBaseLightTheme];
        _darkTheme = [ThemeManager createDarkBaseWithLightTheme:self.lightTheme];

        [self compileThemeDictionary:_lightTheme];
        [self compileThemeDictionary:_darkTheme];

        NSString *currentTheme = [Env getConfStringForKey:@"currentTheme" withDefault:@"light"];
        if ([currentTheme isEqualToString:@"light"]) {
            _selectedTheme = self.lightTheme;
        } else if ([currentTheme isEqualToString:@"dark"]) {
            _selectedTheme = _darkTheme;
        } else {
            [self _tryApplyLocalTheme:currentTheme];
        }
    }

    return self;
}

- (NSMutableDictionary *)mergeFromUserCustomThemeDictionary:(NSMutableDictionary *)themeDictionary
{
    NSMutableDictionary *customTheme = [[NSMutableDictionary alloc] initWithDictionary:self.lightTheme copyItems:YES];
    for (NSString *key in [themeDictionary allKeys]) {
        [customTheme setObject:[themeDictionary objectForKey:key] forKey:key];
    }

    _userTheme = customTheme;
    return customTheme;
}

+ (NSMutableDictionary *)createDarkBaseWithLightTheme:(NSMutableDictionary *)lightTheme
{
    NSMutableDictionary *darkTheme = [[NSMutableDictionary alloc] initWithDictionary:lightTheme copyItems:YES];

    [darkTheme setObject:@"0x101010" forKey:ThemeHomeNavigationBarBackgroundColor];
    [darkTheme setObject:@"0x774a4a4a" forKey:ThemeHomeNavigationBarBorderColor];


    [darkTheme setObject:@"0x101010" forKey:ThemeResPageTitleBarBackgroundColor];
    [darkTheme setObject:@"0x101010" forKey:ThemeResPageToolBarBackgroundColor];

    [darkTheme setObject:@"dark" forKey:@"themeKey"];
    [darkTheme setObject:@"dark" forKey:@"base"];

    [darkTheme setObject:@"0x000000" forKey:ThemeUnderneathBackgroundColor];

    [darkTheme setObject:@"0x007aFF" forKey:ThemeAccentColor];


    [darkTheme setObject:@"0xE0E0E0" forKey:ThemeNormalColor]; //E0E0E0
    [darkTheme setObject:@"0x666669" forKey:ThemeSubTextColor];

    [darkTheme setObject:@"0xDDDDDD" forKey:ThemeResPageTitleColor];
    [darkTheme setObject:@"0x666a6a6a" forKey:ThemeResPageTitleBarBorderColor];

    [darkTheme setObject:@"0xE2E2E2" forKey:ThemeGestureTextColor];       //141414
    [darkTheme setObject:@"0x252c3D" forKey:ThemeGestureBackgroundColor]; //DD686868

    [darkTheme setObject:@"0xcca23242" forKey:ThemeResMyResMarkColor]; //141414
    [darkTheme setObject:@"0xcc999e3b" forKey:ThemeResRefMarkColor];   //DD686868,956c3D

    [darkTheme setObject:@"0x252c3D" forKey:ThemeResPageReadMarkBackgroundColor];             //293144,37415B
    [darkTheme setObject:@"0x3B4660" forKey:ThemeResPageReadMarkAfterReleaseBackgroundColor]; //fFfDeD

    [darkTheme setObject:@"0x8c8c8c" forKey:ThemeTabUnselectedTextColor];
    [darkTheme setObject:@"0x101010" forKey:ThemeTabBackgroundColor];
    [darkTheme setObject:@"0x141414" forKey:ThemeToolBarBackgroundColor];
    [darkTheme setObject:@"0x141414" forKey:ThemeEndOfThreadBackgroundColor];

    [darkTheme setObject:@"0x774a4a4a" forKey:ThemeTabBorderColor];
    [darkTheme setObject:@"0x774a4a4a" forKey:ThemeResPageToolBarBorderColor];

    [darkTheme setObject:@"0x161616" forKey:ThemeMainBackgroundColor];
    [darkTheme setObject:@"0x161616" forKey:ThemeActionSheetBackgroundColor];
    [darkTheme setObject:@"0x161616" forKey:ThemeThreadRowBackgroundColor];
    [darkTheme setObject:@"0x161616" forKey:ThemeBoardViewBackgroundColor];

    [darkTheme setObject:@"0x161616" forKey:ThemeResRowBackgroundColor];
    [darkTheme setObject:@"0x161616" forKey:ThemeResHighlightBackgroundColor];

    [darkTheme setObject:@"0x161616" forKey:ThemeHomeBackgroundColor];
    [darkTheme setObject:@"0x161616" forKey:ThemeResPageBackgroundColor];
    [darkTheme setObject:@"0x161616" forKey:ThemeThreadListPageBackgroundColor];

    [darkTheme setObject:@"0x353535" forKey:ThemeTableSeparatorColor];
    [darkTheme setObject:@"0x252525" forKey:ThemeTableSelectedBackgroundColor];

    [darkTheme setObject:@"0x111111" forKey:ThemeTableSectionBackgroundColor];
    [darkTheme setObject:@"0x111111" forKey:ThemeBoardSectionBackgroundColor];

    [darkTheme setObject:@"0x777882" forKey:ThemeThListCountColor];
    [darkTheme setObject:@"0x777779" forKey:ThemeThListSpeedColor];
    [darkTheme setObject:@"0x007aFF" forKey:ThemeThListUnreadCountColor];

    [darkTheme setObject:@"0xAE00FF" forKey:ThemeThListUnreadOverFlagColor];
    [darkTheme setObject:@"0x7F7F2E" forKey:ThemeThListFavMarkColor];

    [darkTheme setObject:@"0x666666" forKey:ThemeThListReadFlagColor];

    [darkTheme setObject:@"0x00000000" forKey:ThemeResListBackgroundColor];

    [darkTheme setObject:@"0x4C97E8" forKey:ThemeResNumTextColor];     //54a6ff
    [darkTheme setObject:@"0x4182C6" forKey:ThemeResReadNumTextColor]; //90abfa,547997
    [darkTheme setObject:@"0x777777" forKey:ThemeResNameTextColor];
    [darkTheme setObject:@"0x666666" forKey:ThemeResMailTextColor];
    [darkTheme setObject:@"0x666666" forKey:ThemeResDateTextColor];
    [darkTheme setObject:@"0x666666" forKey:ThemeResHeaderIDTextColor];
    [darkTheme setObject:@"0x666666" forKey:ThemeResMultiIDTextColor]; //0055ff
    [darkTheme setObject:@"0x666666" forKey:ThemeResManyIDTextColor];  //ff5533
    [darkTheme setObject:@"0x007aFF" forKey:ThemeResLinkTextColor];
    [darkTheme setObject:@"0x9b995e" forKey:ThemeResAnchorTextColor]; //919E60,007aFF,54a6ff
    [darkTheme setObject:@"0x1B212D" forKey:ThemeResHighlightBackgroundColor];
    [darkTheme setObject:@"0xD4Db13" forKey:ThemeResHighlightTextColor];
    [darkTheme setObject:@"0x7c7c7e" forKey:ThemeResReadRefTextColor];

    [darkTheme setObject:@"0x4d9caa" forKey:ThemeResPopupBorderColor];   //0077FF
    [darkTheme setObject:@"0xf023476b" forKey:ThemeResPopupMarginColor]; //0xe528517F,00397a

    [darkTheme setObject:@"0xddb800" forKey:ThemeResIDPopupBorderColor];                //,ffd800
    [darkTheme setObject:@"0xf0564800" forKey:ThemeResIDPopupMarginColor];              //493D00
    [darkTheme setObject:@"0xEB191400" forKey:ThemeResIDPopupHighlightBackgroundColor]; //F82D2600,EB110e00

    [darkTheme setObject:@"0x89dd66" forKey:ThemeResExtractPopupBorderColor]; // 9EFF75
    [darkTheme setObject:@"0xf0385900" forKey:ThemeResExtractPopupMarginColor];

    [darkTheme setObject:@"0x66333333" forKey:ThemeThumbnailBackgroundColor];
    [darkTheme setObject:@"0x66007aFF" forKey:ThemeThumbnailProgressColor];

    [darkTheme setObject:@"0xcccccccc" forKey:ThemeMenuIconColor];

    return darkTheme;
}

- (void)setSelectedTheme:(NSMutableDictionary *)theme
{
    _selectedTheme = theme;
    [self notifyThemeChanged];
    [self saveThemeAsync:theme];
}

- (NSMutableDictionary *)selectedTheme
{
    return _selectedTheme;
}

- (void)saveThemeAsync:(NSMutableDictionary *)theme
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      [Env setConfString:[self.selectedTheme objectForKey:@"themeKey"] forKey:@"currentTheme"];
    });
}

- (void)notifyThemeChanged
{
    [self notifyThemeChanged:nil];
}

- (void)notifyThemeChanged:(NSDictionary *)userInfo
{
    NSNotification *notification = [NSNotification notificationWithName:@"themeChanged" object:nil userInfo:userInfo];

    NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];
    [queue enqueueNotification:notification postingStyle:NSPostNow /* NSPostWhenIdle */];
}

- (void)changeToDarkTheme
{
    self.selectedTheme = self.darkTheme;
}

- (void)tryApplyLocalThemeWithFolderName:(NSString *)themeKey
{
    [self _tryApplyLocalTheme:themeKey];
    [self notifyThemeChanged];
}

- (void)_tryApplyLocalTheme:(NSString *)themeKey
{
    NSString *themeFolderPath = [Env themeFolderPath];
    NSString *selectThemeFolderPath = [themeFolderPath stringByAppendingPathComponent:themeKey];

    NSLog(@"selectThemefolderpath = %@", selectThemeFolderPath);
    NSFileManager *fm = [NSFileManager defaultManager];
    _selectedTheme = self.lightTheme;

    if ([fm fileExistsAtPath:selectThemeFolderPath] == NO) {
        //_selectedTheme = self.lightTheme;
    } else {
        //フォルダー内のファイルからテーマを生成
        NSData *databuffer = nil;
        NSString *specJsonPath = [selectThemeFolderPath stringByAppendingPathComponent:@"spec.json"];

        NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:specJsonPath];
        databuffer = [file readDataToEndOfFile];
        [file closeFile];

        NSError *error = nil;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:databuffer
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:&error];

        for (NSDictionary *json in jsonResponse) {
            NSLog(@"%@", [json description]);
        }

        NSMutableDictionary *lightTheme = [ThemeManager createBaseLightTheme];
        NSMutableDictionary *darkTheme = [ThemeManager createDarkBaseWithLightTheme:lightTheme];
        NSMutableDictionary *dict = [[jsonResponse objectForKey:@"base"] isEqualToString:@"dark"] ? darkTheme : lightTheme;
        [dict setObject:selectThemeFolderPath forKey:@"dir"];
        // nameがなければUnknownにしておく
        if ([dict objectForKey:@"name"] == nil) {
            [dict setObject:@"Unknown" forKey:@"name"];
        }
        [dict setObject:themeKey
                 forKey:@"themeKey"];
        [self overrideThemeDictionary:dict source:jsonResponse];

        [self compileThemeDictionary:dict];
        if (dict) {
            _selectedTheme = dict;
            //      [self notifyThemeChanged];
            [self saveThemeAsync:dict];
        }
    }
}

- (void)changeToLightTheme
{
    self.selectedTheme = self.lightTheme;
}

- (void)changeToUserTheme
{
    self.selectedTheme = self.userTheme;
}

+ (NSMutableDictionary *)createBaseLightTheme
{
    NSMutableDictionary *lightTheme = [[NSMutableDictionary alloc] init];

    [lightTheme setObject:@"light" forKey:@"base"];
    [lightTheme setObject:@"light" forKey:@"themeKey"];

    [lightTheme setObject:@"0xf7f7f7" forKey:ThemeActionSheetBackgroundColor];
    [lightTheme setObject:@"0xf7f7f7" forKey:ThemeHomeNavigationBarBackgroundColor];
    [lightTheme setObject:@"0x7774737a" forKey:ThemeHomeNavigationBarBorderColor];

    [lightTheme setObject:@"0xf7f7f7" forKey:ThemeResPageTitleBarBackgroundColor];
    [lightTheme setObject:@"0xf7f7f7" forKey:ThemeResPageToolBarBackgroundColor];

    [lightTheme setObject:@"0xFFFFFF" forKey:ThemeUnderneathBackgroundColor];
    [lightTheme setObject:@"0x007aFF" forKey:ThemeAccentColor];

    [lightTheme setObject:@"0x111111" forKey:ThemeNormalColor];

    [lightTheme setObject:@"0x999999" forKey:ThemeSubTextColor];

    [lightTheme setObject:@"0x929292" forKey:ThemeTabUnselectedTextColor];

    [lightTheme setObject:@"0xbbd84b2f" forKey:ThemeResMyResMarkColor]; //141414,bb4bd82f
    [lightTheme setObject:@"0xbbe5ba0d" forKey:ThemeResRefMarkColor];   //DD686868

    [lightTheme setObject:@"0xf7f7f7" forKey:ThemeToolBarBackgroundColor];
    [lightTheme setObject:@"0xf7f7f7" forKey:ThemeEndOfThreadBackgroundColor];

    [lightTheme setObject:@"0xf7f7f7" forKey:ThemeTabBackgroundColor];
    [lightTheme setObject:@"0x7774737a" forKey:ThemeTabBorderColor];
    [lightTheme setObject:@"0x7774737a" forKey:ThemeResPageToolBarBorderColor];

    [lightTheme setObject:@"0xFFFFFF" forKey:ThemeMainBackgroundColor];
    [lightTheme setObject:@"0xFFFFFF" forKey:ThemeHomeBackgroundColor];
    [lightTheme setObject:@"0xFFFFFF" forKey:ThemeResPageBackgroundColor];
    [lightTheme setObject:@"0xFFFFFF" forKey:ThemeThreadListPageBackgroundColor];

    [lightTheme setObject:@"0xf7f7f7" forKey:ThemeActionSheetBackgroundColor];
    [lightTheme setObject:@"0xFFFFFF" forKey:ThemeResRowBackgroundColor];
    [lightTheme setObject:@"0xFFFFFF" forKey:ThemeThreadRowBackgroundColor];
    [lightTheme setObject:@"0xFFFFFF" forKey:ThemeBoardViewBackgroundColor];

    [lightTheme setObject:@"0xF7f7f7" forKey:ThemeBoardSectionBackgroundColor];
    [lightTheme setObject:@"0xF7f7f7" forKey:ThemeTableSectionBackgroundColor];
    [lightTheme setObject:@"0xC8C7CC" forKey:ThemeTableSeparatorColor];
    [lightTheme setObject:@"0xDDDDDD" forKey:ThemeTableSelectedBackgroundColor];
    [lightTheme setObject:@"0xDDDDDD" forKey:ThemeTableBackgroundColor];

    [lightTheme setObject:@"0x222222" forKey:ThemeResPageTitleColor];
    [lightTheme setObject:@"0xccC8E8FF" forKey:ThemeResPageReadMarkBackgroundColor]; //fFfDeD, FFE8FB


    [lightTheme setObject:@"0x77339eff" forKey:ThemeResPageReadMarkAfterReleaseBackgroundColor];
    [lightTheme setObject:@"0x6644434a" forKey:ThemeResPageTitleBarBorderColor];

    [lightTheme setObject:@"0x606060" forKey:ThemeGestureTextColor]; //fFfDeD
    [lightTheme setObject:@"0xCCE2E2E2" forKey:ThemeGestureBackgroundColor];

    [lightTheme setObject:@"0x666666" forKey:ThemeThListCountColor];
    [lightTheme setObject:@"0x666666" forKey:ThemeThListSpeedColor];
    [lightTheme setObject:@"0x0055ff" forKey:ThemeThListUnreadCountColor];

    [lightTheme setObject:@"0x999999" forKey:ThemeThListReadFlagColor];
    [lightTheme setObject:@"0x007aFF" forKey:ThemeThListUnreadFlagColor];
    [lightTheme setObject:@"0xCC4C4C" forKey:ThemeThListOverFlagColor];
    [lightTheme setObject:@"0x19CC7F" forKey:ThemeThListDatDownFlagColor];

    [lightTheme setObject:@"0xB359E0" forKey:ThemeThListUnreadOverFlagColor];
    [lightTheme setObject:@"0xBFBF76" forKey:ThemeThListFavMarkColor];

    [lightTheme setObject:@"0x00000000" forKey:ThemeResListBackgroundColor];

    [lightTheme setObject:@"0x4fa4ff" forKey:ThemeResNumTextColor];     //4fa4ff,0x5F7791
    [lightTheme setObject:@"0x4fa4ff" forKey:ThemeResReadNumTextColor]; //0x3f84bf
    [lightTheme setObject:@"0x747474" forKey:ThemeResNameTextColor];
    [lightTheme setObject:@"0x848484" forKey:ThemeResMailTextColor];
    [lightTheme setObject:@"0x6b6b6d" forKey:ThemeResReadRefTextColor];

    [lightTheme setObject:@"0x848484" forKey:ThemeResDateTextColor];
    [lightTheme setObject:@"0x747474" forKey:ThemeResHeaderIDTextColor];        //54a6ff
    [lightTheme setObject:@"0x747474" forKey:ThemeResMultiIDTextColor];         //0x0055ff
    [lightTheme setObject:@"0x747474" forKey:ThemeResManyIDTextColor];          //0xff5533
    [lightTheme setObject:@"0x007aFF" forKey:ThemeResLinkTextColor];            //54a6ff
    [lightTheme setObject:@"0x0077FF" forKey:ThemeResAnchorTextColor];          //F2A06A, 54a6ff, EFE06E,EFDE58
    [lightTheme setObject:@"0xEFF6FF" forKey:ThemeResHighlightBackgroundColor]; //EFF6FF,eaffff
    [lightTheme setObject:@"0xee0000" forKey:ThemeResHighlightTextColor];

    [lightTheme setObject:@"0x0077FF" forKey:ThemeResPopupBorderColor];
    [lightTheme setObject:@"0xF0d2e7FF" forKey:ThemeResPopupMarginColor];

    [lightTheme setObject:@"0xE2A600" forKey:ThemeResIDPopupBorderColor];
    [lightTheme setObject:@"0xF0FFEEBA" forKey:ThemeResIDPopupMarginColor];
    [lightTheme setObject:@"0xD6FFF8E5" forKey:ThemeResIDPopupHighlightBackgroundColor];

    [lightTheme setObject:@"0x688e58" forKey:ThemeResExtractPopupBorderColor];
    [lightTheme setObject:@"0xF0bbff9e" forKey:ThemeResExtractPopupMarginColor];

    [lightTheme setObject:@"0x55CCCCCC" forKey:ThemeThumbnailBackgroundColor];
    [lightTheme setObject:@"0x66007aFF" forKey:ThemeThumbnailProgressColor];

    [lightTheme setObject:@"0xcc666666" forKey:ThemeMenuIconColor];

    return lightTheme;
}

- (void)overrideThemeDictionary:(NSMutableDictionary *)target source:(NSDictionary *)source
{
    for (NSString *key in [source allKeys]) {
        id sourceObj = [source objectForKey:key];
        id targetObj = [target objectForKey:key];
        if (targetObj) {
            if ([sourceObj isKindOfClass:[NSDictionary class]]) {
                if ([targetObj isKindOfClass:[NSMutableDictionary class]]) {
                    [self overrideThemeDictionary:targetObj source:sourceObj];
                } else {
                    [target setObject:sourceObj forKey:key];
                }
            } else {
                if (sourceObj) {
                    //プリミティブ値を上書き格納できる
                    [target setObject:sourceObj forKey:key];
                } else {
                    [target removeObjectForKey:key];
                }
            }
        } else {
            if (sourceObj) {
                [target setObject:sourceObj forKey:key];
            } else {
                [target removeObjectForKey:key];
            }
        }
    }
}

//TODO: change name to uiColorFormHexString:
- (UIColor *)hexToUIColor:(NSString *)str
{

    return [self hexToUIColor:str alpha:1.0];
}

- (UIColor *)hexToUIColor:(NSString *)str alpha:(CGFloat)alpha
{
    if ([str hasPrefix:@"0x"]) {
        str = [str substringFromIndex:2];
    } else if ([str hasPrefix:@"#"]) {
        str = [str substringFromIndex:1];
    }
    return [self hexStringToUIColor:str alpha:alpha];
}

//- (UIColor*) hexToUIColor:(NSString *)hex{
//    return [self hexToUIColor:hex alpha:1.0];
//
//}

- (UIColor *)hexStringToUIColor:(NSString *)hex alpha:(CGFloat)alpha
{
    NSScanner *colorScanner = [NSScanner scannerWithString:hex];
    unsigned int color;
    [colorScanner scanHexInt:&color];

    if ([hex length] == 8) { //including alpha
        CGFloat a = ((color & 0xFF000000) >> 24) / 255.0f;
        CGFloat r = ((color & 0x00FF0000) >> 16) / 255.0f;
        CGFloat g = ((color & 0x0000FF00) >> 8) / 255.0f;
        CGFloat b = (color & 0x000000FF) / 255.0f;
        //myLog(@"HEX to RGB >> r:%f g:%f b:%f a:%f\n",r,g,b,a);
        return [UIColor colorWithRed:r green:g blue:b alpha:a];

    } else {
        CGFloat r = ((color & 0xFF0000) >> 16) / 255.0f;
        CGFloat g = ((color & 0x00FF00) >> 8) / 255.0f;
        CGFloat b = (color & 0x0000FF) / 255.0f;
        //myLog(@"HEX to RGB >> r:%f g:%f b:%f a:%f\n",r,g,b,a);
        return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
    }
}

- (void)changeTableViewStyle:(UITableView *)tableView
{
    tableView.indicatorStyle = [self useBlackKeyboard] ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleBlack;
}

- (BOOL)useBlackKeyboard
{
    NSString *base = [self.selectedTheme objectForKey:@"base"];
    if ([base isEqualToString:@"dark"]) {
        return YES;
    }
    return NO;
}

- (UIStatusBarStyle)statusBarStyle
{
    return [self useBlackKeyboard] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (UIBarStyle)barStyle
{
    return [self useBlackKeyboard] ? UIBarStyleBlack : UIBarStyleDefault;
}

- (void)copyPropertyIfNil:(NSMutableDictionary *)dictionary fromKey:(NSString *)fromKey toKey:(NSString *)toKey
{
    if ([dictionary objectForKey:toKey] == nil || [[dictionary objectForKey:toKey] isKindOfClass:[NSNull class]]) {
        NSObject *newValue = [dictionary objectForKey:fromKey];
        if (newValue) {
            [dictionary setObject:newValue forKey:toKey];
        }
    }
}


- (void)compileThemeDictionary:(NSMutableDictionary *)themeDictionary
{
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeAccentColor toKey:ThemeResPageTintColor];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeAccentColor toKey:ThemeThreadListPageTintColor];

    [self copyPropertyIfNil:themeDictionary fromKey:ThemeHomeBackgroundImage toKey:ThemeResPageBackgroundImage];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeHomeBackgroundImage toKey:ThemeThreadListPageBackgroundImage];

    [self copyPropertyIfNil:themeDictionary fromKey:ThemeTableSeparatorColor toKey:ThemeThreadRowSeparatorColor];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeTableBackgroundColor toKey:ThemeThreadRowBackgroundColor];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeTableSelectedBackgroundColor toKey:ThemeThreadRowSelectedBackgroundColor];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeTableSectionBackgroundColor toKey:ThemeThreadSectionRowBackgroundColor];

    [self copyPropertyIfNil:themeDictionary fromKey:ThemeTableSeparatorColor toKey:ThemeResRowSeparatorColor];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeTableBackgroundColor toKey:ThemeResRowBackgroundColor];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeTableSelectedBackgroundColor toKey:ThemeResRowSelectedBackgroundColor];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeTableSectionBackgroundColor toKey:ThemeResSectionRowBackgroundColor];

    [self copyPropertyIfNil:themeDictionary fromKey:ThemeToolBarBackgroundColor toKey:ThemeResPageToolBarBackgroundColor];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeToolBarBackgroundColor toKey:ThemeThreadListPageToolBarBackgroundColor];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeToolBarBorderColor toKey:ThemeResPageToolBarBorderColor];
    [self copyPropertyIfNil:themeDictionary fromKey:ThemeToolBarBorderColor toKey:ThemeThreadListPageToolBarBorderColor];

    for (NSString *key in [themeDictionary allKeys]) {
        if ([key hasSuffix:@"Color"]) {
            [themeDictionary setObject:[self hexToUIColor:[themeDictionary objectForKey:key]] forKey:key];
        }
    }
}

- (NSString *)imagePathForKey:(NSString *)key
{
    NSString *dir = [_selectedTheme objectForKey:@"dir"];
    if (dir) {
        NSString *imagePath = [_selectedTheme objectForKey:key];
        return [dir stringByAppendingPathComponent:imagePath];
    }

    return nil;
}

- (UIColor *)colorForKey:(NSString *)key
{
    UIColor *color = [self.selectedTheme objectForKey:key];
    if (color) {
        return color;
    }
    return [UIColor grayColor];
}

- (UIImage *)backgroundImageForKey:(NSString *)key
{
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:[[ThemeManager sharedManager] imagePathForKey:key]];
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];

    UIImage *backgroundImage = nil;
    if (data) {
        UIImage *img = [UIImage imageWithData:data];
        backgroundImage = [UIImage imageWithCGImage:img.CGImage scale:2 orientation:img.imageOrientation];
    }

    return backgroundImage;
}

- (NSArray *)localThemeEntries
{
    if (_localThemeEntries == nil) {
        [self updateLocalThemeEntries];
    }

    return _localThemeEntries;
}

- (void)updateLocalThemeEntries
{
    // ファイルマネージャを作成
    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *themeRoot = [Env themeFolderPath];

    NSError *error;
    NSArray *list = [fm contentsOfDirectoryAtPath:themeRoot error:&error];

    _localThemeEntries = [NSMutableArray array];

    // ファイルやディレクトリの一覧を表示する
    for (NSString *fileName in list) {

        NSString *themeFolderPath = [themeRoot stringByAppendingPathComponent:fileName];
        NSString *specJsonPath = [themeFolderPath stringByAppendingPathComponent:@"spec.json"];
        NSString *infoJsonPath = [themeFolderPath stringByAppendingPathComponent:@"info.json"];

        //spec.jsonの確認
        if ([fm fileExistsAtPath:infoJsonPath] == NO || [fm fileExistsAtPath:specJsonPath] == NO) {
            continue;
        }

        NSData *infoJsonData = [NSData dataWithContentsOfFile:infoJsonPath];

        NSError *error = nil;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:infoJsonData
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:&error];

        if (jsonResponse) {
            NSString *themeName = [jsonResponse objectForKey:@"name"];

            ThemeEntry *newThemeEntry = [[ThemeEntry alloc] init];
            newThemeEntry.folderName = fileName;
            newThemeEntry.folderPath = themeFolderPath;
            newThemeEntry.themeName = themeName ? themeName : fileName;

            [_localThemeEntries addObject:newThemeEntry];
        }
    }
}

/*
 ----- カスタムテーマについて -----
 カスタムテーマを創るにはForestフォルダにあるthemeフォルダ(脱獄環境においては/var/mobile/Documents/Forest/theme)の中に適当な名前のフォルダを作成します。その中に「spec.json」という色情報などを指定するjsonファイルと画像ファイルを入れます。
 実際の作業はiFunBoxなどでファイルをコピーして編集し、再度貼り付けることになると思います。
 spec.jsonのサンプルは以下のようになります。
 
 "base"で「light」か「dark」を指定し、基本となるテーマを指定します。
 ～Colorで終わるプロパティには0x332232のような16進数のRGBを与えるか、0x66332232のようなARGBも使えます。
 透明色を使いすぎると重くなる時があります。
 ～Imageで終わるプロパティには"image.jpg"のように画像の名前を指定します。
 
 "tintColor"は軸となる色が入ります。
 
 {
 "name": "spotlight"
 , "creator": "Wide Attack"
 , "base": "dark"
 
 , "resPageBackgroundColor": "0x101010" //レス一覧ページでの背景色
 , "resPageBackgroundImage": "md703617.jpg"//レス一覧ページでの背景色
 
 , "homeBackgroundColor": "0x101010"
 , "homeBackgroundImage": "md703617.jpg"
 
 , "threadListPageBackgroundColor": "0x101010"
 , "threadListPageBackgroundImage": "md703617.jpg"
 
 
 , "tintColor":"0x0092FF"
 
 , "mainBackgroundColor": "0x101010"
 
 , "homeTabBarBackgroundColor": "0x61000000"
 , "navigationBarBackgroundColor": "0x01000000"
 , "navigationBarBorderColor": "0x01000000"
 , "homeTabBarBorderColor": "0x774a4a4a"
 
 , "listSectionRowBackgroundColor": "0xaa050505"
 , "listSeparatorColor": "0x33AAAAAA"
 , "listSelectedBackgroundColor": "0x88252555"
 
 , "resPageReadMarkBackgroundColor": "0x99252c3D"
 , "resPageEndOfThreadBackgroundColor": "0x99252c3D"
 , "resPageTitleBarBackgroundColor": "0x61000000"
 , "resPageToolBarBackgroundColor": "0x61000000"
 , "resRowBackgroundColor": "0x41000000"
 
 , "boardViewBackgroundColor": "0x61000000"
 , "boardSectionBackgroundColor": "0x11000000"
 
 , "actionSheetBackgroundColor": "0xbb101010"
 , "threadRowBackgroundColor": "0x61000000"
 
 
 }
 
 
 
 
 "tintColor"     軸となる色
 "resPageTintColor" レスページのtintColor
 "threadListPageTintColor" 板のスレ一覧のtintColor
 
 "normalTextColor"   ノーマルなテキストの文字色
 "subTextColor"  サブように使うノーマルより暗めの文字色
 
 "gestureTextColor"  ジェスチャー表示用の文字色
 "gestureBackgroundColor"  ジェスチャー表示用の背景色
 
 
 "homeBackgroundImage" ホームの背景画像
 "homeBackgroundColor" ホームの背景色
 
 "navigationBarBackgroundColor" ナビゲーションバーの背景色
 "navigationBarBorderColor" ナビゲーションバーのボーダー色
 
 "homeTabBarBackgroundColor"　ホームのタブバーの背景色
 "homeTabBarBorderColor" タブバーのボーダー色
 
 "baseBackgroundColor" 基本の背景色
 "actionSheetBackgroundColor" メニュー用の背景色
 "menuIconColor" メニュー用の色(タップ時はtintColorが使用される)
 
 
 "toolBarBackgroundColor" ツールバーの背景色
 "toolBarBorderColor" ツールバーのボーダー色
 
 ----- リスト共通 -----
 "listRowBackgroundColor"  行背景色
 "listRowSeparatorColor"  セパレーターの色
 "listRowSelectedBackgroundColor" タップした時の背景色
 "listSectionRowBackgroundColor" セクションの背景色
 
 ---- レス一覧 ----
 "resPageTintColor" レス一覧ページのtintColor (省略時にはtintColorを適用)
 
 "resPageBackgroundColor" レス一覧ページの背景色
 "resPageBackgroundImage" レス一覧ページの背景画像
 "resListBackgroundColor"　レス一覧の背景色
 "resPageBackgroundImageForLandscape" 横向き用の背景画像
 
 "resPageReadMarkBackgroundColor" 新着数マークの背景色
 "resPageEndOfThreadBackgroundColor" スレッドのおわりの背景色
 "resPageToolBarBackgroundColor" //レス一覧のツールバーの背景色
 "resPageToolBarBorderColor" //レス一覧のツールバーのボーダー色
 
 
 "resRowBackgroundColor" レスの背景色 (nullでlistBac
 "resRowSeparatorColor" レスの区切り線の色
 "resRowSelectedBackgroundColor" 選択レスの背景色
 "resSectionRowBackgroundColor" レスの背景色 (nullでlistBac
 
 "resPageTitleColor" レスページのタイトルカラー
 "resPageTitleBarBackgroundColor" //レス一覧のタイトルバーの背景色
 "resPageTitleBarBorderColor" レスタイトルバーのボーター色
 
 
 ----- スレッド一覧 ----
 "ThemeThreadListPageTintColor" スレ一覧ページのtintColor (省略時にはtintColorを適用)
 "threadListPageBackgroundColor" スレ一覧の背景色
 "threadListPageBackgroundImage" スレ一覧の背景画像
 
 "threadListPageToolBarBackgroundColor" ツールバーの背景色
 "threadListPageToolBarBorderColor"  ツールバーのボーダー色
 
 "threadCountColor" レス数の文字色
 "threadSpeedColor" 勢いの文字色
 "threadUnreadCountColor" 未読数の文字色
 
 "threadReadFlagColor" 既読用マーク色
 "threadUnreadFlagColor" 未読マーク色
 "threadOverFlagColor" 1000越えまたはもう書き込めない場合のマーク色
 "threadDatDownFlagColor" Dat落ちのマーク色
 
 "threadRowBackgroundColor" スレッド行の背景色
 "threadRowSeparatorColor" スレッド行の区切り線
 "threadRowSelectedBackgroundColor" 選択された背景色
 "threadSectionRowBackgroundColor" スレッドセクション行(お気に入りの場合はフォルダ名を示すために使い、履歴では時間)
 
 ----- 板一覧 -----
 
 "boardPageBackgroundColor"  板一覧ページの背景色
 "boardSectionBackgroundColor"  板一覧ページのセクション背景色
 
 
 
 ------ レス -------
 "resNumTextColor" レス番号
 "resUnreadNumTextColor" 未読時のレス番号
 "resNameTextColor" 名前
 "resReadRefTextColor" 　ツリー表示時の新着から既読レス参照時の文字色
 "resMailTextColor" メール
 "resDateTextColor"　日付
 "resHeaderIDTextColor" ID
 "resMultiIDTextColor" 発言2以上のID
 "resManyIDTextColor" 発言5つ以上のID
 "resLinkTextColor" リンク
 "resAnchorTextColor" アンカー
 "resHighlightBackgroundColor" ハイライト用の背景速
 
 "resMyResMarkColor" 自分のレス用のマーク色
 "resResRefMarkColor" 自分のレスに返信されたマーク色
 
 //popup
 "resPopupBorderColor" 通常ポップアップのボーダー色
 "resPopupPadColor" 通常ポップアップのパッド色
 
 "resIDPopupBorderColor" IDポップアップのボーダー色
 "resIDPopupPadColor"  IDポップアップのパッド色
 "resIDPopupHighlightBackgroundColor" IDポップアップ時のハイライト背景色
 
 "resExtractPopupBorderColor" 抽出ポップアップのボーダー色
 "resExtractPopupPadColor" 抽出ポップアップのパッド色
 
 "thumbnailProgressColor" サムネイルの進捗バーの色
 "thumbnailBackgroundColor" サムネイルの背景色
 
 */
@end
