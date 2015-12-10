#import <Foundation/Foundation.h>

#undef _EXT
#undef _INIT_AS

#ifdef XOYIP_DEFINE_GLOBALS
#define _EXT
#define _INIT_AS(x) = x
#else
#define _EXT extern
#define _INIT_AS(x)
#endif

_EXT NSString *const ThemeAccentColor _INIT_AS(@"tintColor");

_EXT NSString *const ThemeNormalColor _INIT_AS(@"normalTextColor");
_EXT NSString *const ThemeSubTextColor _INIT_AS(@"subTextColor");

_EXT NSString *const ThemeResPageTintColor _INIT_AS(@"resPageTintColor");
_EXT NSString *const ThemeThreadListPageTintColor _INIT_AS(@"threadListPageTintColor");

_EXT NSString *const ThemeGestureTextColor _INIT_AS(@"gestureTextColor");
_EXT NSString *const ThemeGestureBackgroundColor _INIT_AS(@"gestureBackgroundColor");

_EXT NSString *const ThemeHomeNavigationBarBackgroundColor _INIT_AS(@"navigationBarBackgroundColor");
_EXT NSString *const ThemeHomeNavigationBarBorderColor _INIT_AS(@"navigationBarBorderColor");

_EXT NSString *const ThemeHomeBackgroundImage _INIT_AS(@"homeBackgroundImage"); //relative path to image fil)e
_EXT NSString *const ThemeHomeBackgroundColor _INIT_AS(@"homeBackgroundColor");

_EXT NSString *const ThemeToolBarBackgroundColor _INIT_AS(@"toolBarBackgroundColor");
_EXT NSString *const ThemeToolBarBorderColor _INIT_AS(@"toolBarBorderColor");

_EXT NSString *const ThemeThreadListPageBackgroundColor _INIT_AS(@"threadListPageBackgroundColor");
_EXT NSString *const ThemeThreadListPageBackgroundImage _INIT_AS(@"threadListPageBackgroundImage");

_EXT NSString *const ThemeMainBackgroundColor _INIT_AS(@"baseBackgroundColor");
_EXT NSString *const ThemeBoardViewBackgroundColor _INIT_AS(@"boardPageBackgroundColor");
_EXT NSString *const ThemeBoardSectionBackgroundColor _INIT_AS(@"boardSectionBackgroundColor");

_EXT NSString *const ThemeActionSheetBackgroundColor _INIT_AS(@"actionSheetBackgroundColor");

_EXT NSString *const ThemeTabUnselectedTextColor _INIT_AS(@"homeTabBarUnselectedTextColor");
_EXT NSString *const ThemeTabBackgroundColor _INIT_AS(@"homeTabBarBackgroundColor");
_EXT NSString *const ThemeTabBorderColor _INIT_AS(@"homeTabBarBorderColor");

_EXT NSString *const ThemeMenuIconColor _INIT_AS(@"menuIconColor");

_EXT NSString *const ThemeResPageReadMarkBackgroundColor _INIT_AS(@"resPageReadMarkBackgroundColor");
_EXT NSString *const ThemeEndOfThreadBackgroundColor _INIT_AS(@"resPageEndOfThreadBackgroundColor");

_EXT NSString *const ThemeResPageReadMarkAfterReleaseBackgroundColor _INIT_AS(@"resPageReadMarkAfterReleaseBackgroundColor");

_EXT NSString *const ThemeResMyResMarkColor _INIT_AS(@"resMyResMarkColor");
_EXT NSString *const ThemeResRefMarkColor _INIT_AS(@"resResRefMarkColor");

_EXT NSString *const ThemeTableSeparatorColor _INIT_AS(@"listRowSeparatorColor");
_EXT NSString *const ThemeTableBackgroundColor _INIT_AS(@"listRowBackgroundColor");
_EXT NSString *const ThemeTableSelectedBackgroundColor _INIT_AS(@"listRowSelectedBackgroundColor");
_EXT NSString *const ThemeTableSectionBackgroundColor _INIT_AS(@"listSectionRowBackgroundColor");
//static NSString* ThemeTableSectionForegroundColor = @"listSectionForegroundColor";

// ---------- スレ一覧 ----------

_EXT NSString *const ThemeThreadListPageToolBarBackgroundColor _INIT_AS(@"threadListPageToolBarBackgroundColor");
_EXT NSString *const ThemeThreadListPageToolBarBorderColor _INIT_AS(@"threadListPageToolBarBorderColor");

_EXT NSString *const ThemeThreadRowBackgroundColor _INIT_AS(@"threadRowBackgroundColor");
_EXT NSString *const ThemeThreadRowSeparatorColor _INIT_AS(@"threadRowSeparatorColor");
_EXT NSString *const ThemeThreadRowSelectedBackgroundColor _INIT_AS(@"threadRowSelectedBackgroundColor");
_EXT NSString *const ThemeThreadSectionRowBackgroundColor _INIT_AS(@"threadSectionRowBackgroundColor");

_EXT NSString *const ThemeThListCountColor _INIT_AS(@"threadCountColor");
_EXT NSString *const ThemeThListSpeedColor _INIT_AS(@"threadSpeedColor");
_EXT NSString *const ThemeThListUnreadCountColor _INIT_AS(@"threadUnreadCountColor");
_EXT NSString *const ThemeThListFavMarkColor _INIT_AS(@"threadFavMarkColor");

_EXT NSString *const ThemeThListReadFlagColor _INIT_AS(@"threadReadFlagColor");
_EXT NSString *const ThemeThListUnreadFlagColor _INIT_AS(@"threadUnreadFlagColor");
_EXT NSString *const ThemeThListOverFlagColor _INIT_AS(@"threadOverFlagColor");
_EXT NSString *const ThemeThListDatDownFlagColor _INIT_AS(@"threadDatDownFlagColor");
_EXT NSString *const ThemeThListUnreadOverFlagColor _INIT_AS(@"threadUnreadOverFlagColor");

// --------- レス一覧 ---------
//
_EXT NSString *const ThemeResPageTitleColor _INIT_AS(@"resPageTitleColor");
_EXT NSString *const ThemeResPageTitleBarBorderColor _INIT_AS(@"resPageTitleBarBorderColor");
_EXT NSString *const ThemeResPageTitleBarBackgroundColor _INIT_AS(@"resPageTitleBarBackgroundColor");

_EXT NSString *const ThemeResPageToolBarBackgroundColor _INIT_AS(@"resPageToolBarBackgroundColor");
_EXT NSString *const ThemeResPageToolBarBorderColor _INIT_AS(@"resPageToolBarBorderColor");

_EXT NSString *const ThemeResPageBackgroundColor _INIT_AS(@"resPageBackgroundColor");
_EXT NSString *const ThemeResListBackgroundColor _INIT_AS(@"resListBackgroundColor");

_EXT NSString *const ThemeResPageBackgroundImage _INIT_AS(@"resPageBackgroundImage");
_EXT NSString *const ThemeResPageBackgroundImageForLandscape _INIT_AS(@"resPageBackgroundImageForLandscape");

_EXT NSString *const ThemeResRowBackgroundColor _INIT_AS(@"resRowBackgroundColor");
_EXT NSString *const ThemeResRowSeparatorColor _INIT_AS(@"resRowSeparatorColor");
_EXT NSString *const ThemeResRowSelectedBackgroundColor _INIT_AS(@"resRowSelectedBackgroundColor");
_EXT NSString *const ThemeResSectionRowBackgroundColor _INIT_AS(@"resSectionRowBackgroundColor");

//
_EXT NSString *const ThemeResNumTextColor _INIT_AS(@"resNumTextColor");
_EXT NSString *const ThemeResReadNumTextColor _INIT_AS(@"resUnreadNumTextColor");
_EXT NSString *const ThemeResNameTextColor _INIT_AS(@"resNameTextColor");
_EXT NSString *const ThemeResReadRefTextColor _INIT_AS(@"resReadRefTextColor");
_EXT NSString *const ThemeResMailTextColor _INIT_AS(@"resMailTextColor");
_EXT NSString *const ThemeResDateTextColor _INIT_AS(@"resDateTextColor");
_EXT NSString *const ThemeResHeaderIDTextColor _INIT_AS(@"resHeaderIDTextColor");
_EXT NSString *const ThemeResMultiIDTextColor _INIT_AS(@"resMultiIDTextColor");
_EXT NSString *const ThemeResManyIDTextColor _INIT_AS(@"resManyIDTextColor");
_EXT NSString *const ThemeResLinkTextColor _INIT_AS(@"resLinkTextColor");
_EXT NSString *const ThemeResAnchorTextColor _INIT_AS(@"resAnchorTextColor");
_EXT NSString *const ThemeResHighlightBackgroundColor _INIT_AS(@"resHighlightBackgroundColor");

_EXT NSString *const ThemeThumbnailProgressColor _INIT_AS(@"thumbnailProgressColor");
_EXT NSString *const ThemeThumbnailBackgroundColor _INIT_AS(@"thumbnailBackgroundColor");

//popup
_EXT NSString *const ThemeResPopupBorderColor _INIT_AS(@"resPopupBorderColor");
_EXT NSString *const ThemeResPopupMarginColor _INIT_AS(@"resPopupPadColor");

_EXT NSString *const ThemeResIDPopupBorderColor _INIT_AS(@"resIDPopupBorderColor");
_EXT NSString *const ThemeResIDPopupMarginColor _INIT_AS(@"resIDPopupPadColor");
_EXT NSString *const ThemeResIDPopupHighlightBackgroundColor _INIT_AS(@"resIDPopupHighlightBackgroundColor");

_EXT NSString *const ThemeResExtractPopupBorderColor _INIT_AS(@"resExtractPopupBorderColor");
_EXT NSString *const ThemeResExtractPopupMarginColor _INIT_AS(@"resExtractPopupPadColor");

_EXT NSString *const ThemeResHighlightTextColor _INIT_AS(@"resHighlightTextColor");

_EXT NSString *const ThemeUnderneathBackgroundColor _INIT_AS(@"ThemeUnderneathBackgroundColor");

@class UIColor;

@interface ThemeEntry : NSObject {
}
@property (nonatomic) BOOL downloaded; //すでにダウンロード済み
@property (nonatomic) BOOL canDownload;
@property (nonatomic, copy) NSString *themeId;

@property (nonatomic, copy) NSString *themeName;
@property (nonatomic, copy) NSString *folderName;
@property (nonatomic, copy) NSString *folderPath;

@property (nonatomic, copy) NSString *creator;

@property (nonatomic) UIImage *mainScreenImage;

@property (nonatomic) BOOL isDownloading;
@property (nonatomic) BOOL isDownloaded;

- (void)deleteFile;

@end



@interface ThemeManager : NSObject

@property (nonatomic,readonly) NSMutableArray *localThemeEntries;

@property (nonatomic) NSMutableDictionary *selectedTheme;
@property (nonatomic, readonly) NSMutableDictionary *darkTheme;
@property (nonatomic, readonly) NSMutableDictionary *lightTheme;
@property (nonatomic, readonly) NSMutableDictionary *userTheme;

+ (ThemeManager *)sharedManager;

- (id)init;
- (BOOL)useBlackKeyboard;
- (UIColor *)colorForKey:(NSString *)key;
- (NSString *)imagePathForKey:(NSString *)key;
- (UIImage *)backgroundImageForKey:(NSString *)key;

- (void)changeToDarkTheme;
- (void)changeToLightTheme;
- (void)changeToUserTheme;


- (UIStatusBarStyle)statusBarStyle;
- (UIBarStyle)barStyle;

- (void)changeTableViewStyle:(UITableView *)tableView;

- (void)notifyThemeChanged;
- (void)notifyThemeChanged:(NSDictionary *)userInfo;

- (void)tryApplyLocalThemeWithFolderName:(NSString *)themeKey;


- (void)updateLocalThemeEntries;

@end
