//
//  RootViewController.m
//  Forest
//

#import "MainVC.h"
#import "FavVC.h"
#import "HistoryVC.h"
#import "ThListVC.h"
#import "BoardVC.h"
#import <QuartzCore/QuartzCore.h>
#import "ThemeManager.h"
#import "AppDelegate.h"
#import "ThManager.h"
#import "ResVC.h"
#import "Env.h"
#import "ResTransaction.h"
#import "SyncManager.h"
#import "UIView+NSObjectProperty.h"
#import "Views.h"
#import "SearchWebViewController.h"
#import "MySplitVC.h"
#import "UIViewController+WrapWithNavigationController.h"

static MainVC *_instance;

@interface MainVC ()

@property (nonatomic) NSUInteger prevTabSaveTime;
@property (nonatomic) UIViewController *tempViewController;
@property (nonatomic) BOOL hasUpdateState;
@property (nonatomic) NSString *releaseNoteUrl;

@end

@implementation MainVC

+ (MainVC *)instance
{
    return _instance;
}

- (void)awakeFromNib
{
    _instance = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [[MyNavigationVC instance] setNavigationBarHidden:NO animated:NO];
}


- (void)viewDidLoad
{
    _instance = self;
    [super viewDidLoad];

    self.navigationController.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];

    [self changeTheme];

    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"FFFFFF-0.png"]];
    [self.tabBar setClipsToBounds:YES];

    // IBでは小数設定できない
    self.lineTopBarHeightConstraint.constant = thinLineWidth;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(themeChange:)
               name:@"themeChanged"
             object:nil];

    self.tabBar.delegate = self;
    
    NSMutableArray *tabBarItems = [[NSMutableArray alloc] init];

    self.boardTabItem = [[UITabBarItem alloc] initWithTitle:@"板一覧"
                                                      image:[UIImage imageNamed:@"board_gray_30.png"]
                                              selectedImage:[UIImage imageNamed:@"board_blue_30.png"]];

    self.favTabItem = [[UITabBarItem alloc] initWithTitle:@"お気に入り"
                                                    image:[UIImage imageNamed:@"star_gray_30.png"]
                                            selectedImage:[UIImage imageNamed:@"star_blue_30.png"]];

    self.historyTabItem = [[UITabBarItem alloc] initWithTitle:@"履歴"
                                                        image:[UIImage imageNamed:@"clock_gray_30.png"]
                                                selectedImage:[UIImage imageNamed:@"clock_blue_30.png"]];

    self.moreTabItem = [[UITabBarItem alloc] initWithTitle:@""
                                                     image:[UIImage imageNamed:@"more_gray_tab.png"]
                                             selectedImage:[UIImage imageNamed:@"more_blue_tab.png"]];



    if ([Env hasInVersionFile] == NO && [Env getConfBOOLForKey:kConfigAppUpdateNotificationKey withDefault:YES]) {
        [self checkVersion:nil];
    }

    //    self.moreTabItem.badgeValue = @"3";
    [tabBarItems addObject:self.boardTabItem];
    [tabBarItems addObject:self.historyTabItem];
    [tabBarItems addObject:self.favTabItem];
    [tabBarItems addObject:self.moreTabItem];

    self.tabBar.items = tabBarItems;
    [self.view setNeedsUpdateConstraints];

    self.favVC = [[FavVC alloc] initWithNibName:@"FavVC" bundle:nil];
    self.favVC.isTabInMain = YES;

    self.boardVC = [[BoardVC alloc] initWithNibName:@"BoardVC" bundle:nil];
    

    self.historyVC = [[HistoryVC alloc] initWithNibName:@"HistoryVC" bundle:nil];
    self.historyVC.isTabInMain = YES;

    //初期タブ決定
    NSString *selectTab = [Env getConfStringForKey:@"selectedTab" withDefault:@"板一覧"];

    UITabBarItem *firstTabItem = nil;
    for (UITabBarItem *item in tabBarItems) {
        if ([item.title isEqualToString:selectTab]) {
            firstTabItem = item;
            break;
        }
    }
    if (firstTabItem == nil) {
        firstTabItem = self.boardTabItem;
    }

    UIViewController *tabViewController = [self __tabViewControllerFromTabItem:firstTabItem];
    self.tabBar.selectedItem = firstTabItem;
    self.currentTabItem = firstTabItem;

    // Navigation ControllerのNavigation Barに割り当て用
    self.title = tabViewController.title;

    [self.mainContainerView addSubview:tabViewController.view];
    [self addChildViewController:tabViewController];
    [Views _constraintParentFit:tabViewController.view withParentView:self.mainContainerView];

    [self updateNavigationBarButtons];

    [[SyncManager sharedManager] startAutoSyncIfEnabled];
}

- (void)updateNavigationBarButtons
{

    UIViewController *tabViewController = [self __tabViewControllerFromTabItem:self.currentTabItem];
    self.navigationItem.titleView = tabViewController.navigationItem.titleView; // 板のスレ一覧のボックス用
    self.navigationItem.rightBarButtonItem = tabViewController.navigationItem.rightBarButtonItem;
    self.navigationItem.rightBarButtonItems = tabViewController.navigationItem.rightBarButtonItems;
    self.navigationItem.leftBarButtonItem = tabViewController.navigationItem.leftBarButtonItem;
    self.navigationItem.leftBarButtonItems = tabViewController.navigationItem.leftBarButtonItems;
}

// 通知と値を受けるonThemeChangedメソッド
- (void)themeChange:(NSNotification *)center
{
    [self changeTheme];
}

- (void)changeTheme
{
    self.mainContainerView.backgroundColor = [UIColor clearColor];
    [self.mainContainerView layoutIfNeeded];
    [self.mainContainerView setNeedsDisplay];

    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeUnderneathBackgroundColor];

    UIImage *backgroundImage = [[ThemeManager sharedManager] backgroundImageForKey:ThemeHomeBackgroundImage];
    self.backgroundImageView.image = backgroundImage;
    self.backgroundImageView.contentMode = UIViewContentModeTop;

    self.backgroundImageView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeHomeBackgroundColor];

    [self.tabBar setBackgroundColor:[[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor]];
    [self.lineOverTabbar setBackgroundColor:[[ThemeManager sharedManager]
                                                colorForKey:ThemeTabBorderColor]];
}



- (void)hideTabBar
{
    self.tabbarHeightConstraint.constant = 0;

    [UIView animateWithDuration:0.2
                     animations:^{
                       [self.tabBar layoutIfNeeded];
                       [self.mainContainerView layoutIfNeeded];

                       [self.lineOverTabbar layoutIfNeeded];
                     }];
}

- (void)showTabBar
{
    self.tabBar.opaque = 1;
    self.tabbarHeightConstraint.constant = 49;
    [UIView animateWithDuration:0.2
                     animations:^{
                       [self.tabBar layoutIfNeeded];
                       [self.mainContainerView layoutIfNeeded];
                       [self.lineOverTabbar layoutIfNeeded];
                     }];
}

- (UIViewController *)__tabViewControllerFromTabItem:(UITabBarItem *)tabBarItem
{
    if (tabBarItem == self.historyTabItem) {
        return self.historyVC;
    } else if (tabBarItem == self.favTabItem) {
        return self.favVC;
    } else if (tabBarItem == self.boardTabItem) {
        return self.boardVC;
    } else {
        return self.tempViewController;
    }

    return nil;
}

- (void)onBackFromModalView
{
    if (self.currentTabItem) { //iOS7
//        UIViewController *currentViewController = [self __tabViewControllerFromTabItem:self.currentTabItem];
//        [currentViewController.view removeFromSuperview];
//        [currentViewController removeFromParentViewController];
//        [self addChildViewController:currentViewController];
//        [self.mainContainerView addSubview:currentViewController.view];
//        [Views _constraintParentFit:currentViewController.view withParentView:self.mainContainerView];
//        //    [currentViewController.view removeConstraints:currentViewController.view.constraints];
//        //    [self constraintParentFit:currentViewController.view withParentView:self.mainContainerView];
//        [self.view updateConstraints];
//        [self.mainContainerView updateConstraints];
//        [self.view setNeedsDisplay];
//        [self.mainContainerView setNeedsDisplay];
    }
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{

    self.moreTabItem.badgeValue = nil;
    BOOL toOpenMenu = item == self.moreTabItem;

    UIViewController *nextTabViewController = [self __tabViewControllerFromTabItem:item];
    UIViewController *currentViewController = [self __tabViewControllerFromTabItem:self.currentTabItem];

    if (toOpenMenu) {
        
        self.tabBar.selectedItem = self.currentTabItem; //戻す
        
        if (self.hasUpdateState) {
            self.hasUpdateState = NO;
            
            SearchWebViewController *searchWebViewController = [[SearchWebViewController alloc] init];
            searchWebViewController.searchUrl = self.releaseNoteUrl ? self.releaseNoteUrl : @"https://github.com/f-tools/forest/blob/master/ChangeLog.md";
            UINavigationController *con = [searchWebViewController wrapWithNavigationController];
            
            [[MySplitVC instance] presentViewController:con
                                               animated:YES
                                             completion:^{  }];

            return;
        }

        if ([currentViewController respondsToSelector:@selector(onContextMenuTap)]) {
            [(id)currentViewController onContextMenuTap];
        }
        return;
    }

    if ([nextTabViewController respondsToSelector:@selector(onTabSelected:tapTwice:)]) {
        [(id)nextTabViewController onTabSelected:item
                                        tapTwice:(nextTabViewController == currentViewController)];
    }

    [self __showViewController:nextTabViewController];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(doSaveTab:) withObject:item.title afterDelay:3.4];

    self.tempViewController = nil;
    self.currentTabItem = item;
}

- (void) __showViewController:(UIViewController*)nextTabViewController 
{
    UIViewController *currentViewController = [self __tabViewControllerFromTabItem:self.currentTabItem];


    if (nextTabViewController != currentViewController) {
        [currentViewController removeFromParentViewController];
        [self addChildViewController:nextTabViewController];


        if (currentViewController) {
            [UIView transitionFromView:currentViewController.view
                                toView:nextTabViewController.view
                              duration:0.2
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            //UIViewAnimationOptionTransitionNone
                            completion:^(BOOL finished){
                                
                            }];
        } else {
            [self.mainContainerView addSubview:nextTabViewController.view];
        }
        
        [Views _constraintParentFit:nextTabViewController.view withParentView:self.mainContainerView];
    }
    
    self.title = nextTabViewController.title;
  
    self.navigationItem.rightBarButtonItem = nextTabViewController.navigationItem.rightBarButtonItem;
    self.navigationItem.rightBarButtonItems = nextTabViewController.navigationItem.rightBarButtonItems;
    
    self.navigationItem.leftBarButtonItem = nextTabViewController.navigationItem.leftBarButtonItem;
    self.navigationItem.leftBarButtonItems = nextTabViewController.navigationItem.leftBarButtonItems;

    
}



- (void)showThListVC:(UIViewController*)thListVC
{
    [self __showViewController:thListVC];
    self.currentTabItem = nil;
    self.tempViewController = thListVC;
    self.tabBar.selectedItem = nil;
}

- (void)doSaveTab:(NSString *)tabTitle
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      [Env setConfString:tabTitle forKey:@"selectedTab"];
    });
}

- (void)setFavTabBarBadge:(NSString *)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
      self.favTabItem.badgeValue = value;
    });
}

/*
 ver1がver2より大きいかどうかを返します
 */
- (NSInteger) compareVersion:(NSString *)ver1 withAnother:(NSString *)ver2 {
    NSArray *verArray1 = [ver1 componentsSeparatedByString:@"."];
    NSArray *verArray2 = [ver2 componentsSeparatedByString:@"."];
    
    NSInteger len = [verArray1 count] > [verArray2 count] ? [verArray1 count] : [verArray2 count];
    NSInteger index = 0;
    for (index = 0; index < len; index++) {
        BOOL has1 = index < [verArray1 count];
        BOOL has2 = index < [verArray2 count];
        
        if (!has1 && has2) {return -1;}
        if (has1 && !has2) {return 1;}
        if (!has1 && !has2) return 0;
        
        NSInteger val1 = [verArray1[index] intValue];
        NSInteger val2 = [verArray2[index] intValue];
        
        if (val1 != val2) {
            return val1  - val2;
        }
    }
    
    return 0;
}

- (NSDictionary *)extractVersionInfo:(NSData *) data {
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray<NSString *> *srtList = [str componentsSeparatedByString:@"\n"];
    for (NSString * str in srtList) {
        NSRange range = [str rangeOfString:@":"];
        if (range.location == NSNotFound) {
            continue;
        }
        
        
        NSString *name = [str substringToIndex:range.location];
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *value = [str substringFromIndex:range.location+1];
        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        dict[name] = value;
    }
    
    return dict;
    
}



- (void)checkVersion:(id)sender
{

    
    
    NSString *urlstr = @"https://f-tools.github.io/forest-version-gh-pages/version.txt";
    
    NSURL *nsurl = [NSURL URLWithString:urlstr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10000];
    request.HTTPMethod = @"GET";
    
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         
         if (error) {
             dispatch_async(dispatch_get_main_queue(), ^{
                       });
             
             
             if (error.code == -1003) {
                 //   NSLog(@"not found hostname. targetURL=%@", url);
             } else if (error.code == -1019) {
                 NSLog(@"auth error. reason=%@", error);
             } else {
                 NSLog(@"unknown error occurred. reason = %@", error);
             }
             
             
             
         } else {
             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
             NSUInteger httpStatusCode = httpResponse.statusCode;
             if (httpStatusCode == 404) {
                 
             } else {
                 if (httpStatusCode != 200) {
                     NSString* errorMsg = [NSString stringWithFormat:@"Error, status code: %@", @(httpStatusCode)];
                     return;
                 }
                 
                 NSDictionary *dict = [self extractVersionInfo:data];
                 
                 NSString *nextVersion = dict[@"version"];
                 NSString *forestZipUrl = dict[@"path"];
                 NSString *releaseNoteUrl = dict[@"releaseNoteUrl"];
                 NSString *checkedVersion = [Env getConfStringForKey:@"checkedVersion" withDefault:nil];
                 if (checkedVersion) {
                     if ([nextVersion isEqualToString:checkedVersion]) {
                         return;
                     }
                 }
                 
                 [Env setConfString:nextVersion forKey:@"checkedVersion"];
                 NSString * str = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                 NSLog(@"version = %@", str);

                 if (str && nextVersion && [self compareVersion:nextVersion withAnother:str] > 0) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         self.hasUpdateState = YES;
                         self.moreTabItem.badgeValue = @"更新";
                     });
                 }

             }
         }
         
         
     }];
    
    //    [[sender window] setDocumentEdited:NO];
    
}


@end
