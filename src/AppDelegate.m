//
//  AppDelegate.m
//  Forest
//

#import "AppDelegate.h"
#import "TopWindow.h"
#import "Env.h"
#import "ResTransaction.h"
#import <SDImageCache.h>
#import <GLKit/GLKit.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Env initVariables];

    [self.window windowInit];
    
    SDImageCache *cache = [SDImageCache sharedImageCache];
    [cache setMaxMemoryCost:20];// pixels

    application.applicationIconBadgeNumber = 0;

    // エラー追跡用の機能を追加する。
    NSSetUncaughtExceptionHandler(&exceptionHandler);

    NSString *thUrl = [Env getLastThread];
    if (thUrl) {
        NSLog(@"th Url = %@", thUrl);
        [MainVC instance].requestOpenThreadUrl = thUrl;
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{

    NSString *absoluteString = [url absoluteString];
    if ([absoluteString length] > 18 && [absoluteString hasPrefix:@"forest2ch://"]) {
        NSString *thUrl = [NSString stringWithFormat:@"http://%@", [absoluteString substringFromIndex:[@"forest2ch://" length]]];
        [MainVC instance].requestOpenThreadUrl = thUrl;
    }

    return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    UIInterfaceOrientationMask orientation = [Env getOrientation];
    if (orientation == UIInterfaceOrientationMaskAllButUpsideDown) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else if (orientation == UIInterfaceOrientationMaskPortrait) {
        return UIInterfaceOrientationMaskPortrait;
    } else if (orientation == UIInterfaceOrientationMaskLandscape) {
        return UIInterfaceOrientationMaskLandscape;
    } else if (orientation == UIInterfaceOrientationMaskLandscapeLeft) {
        return UIInterfaceOrientationMaskLandscapeLeft;
    } else if (orientation == UIInterfaceOrientationMaskLandscapeRight) {
        return UIInterfaceOrientationMaskLandscapeRight;
    } else {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    //return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

/*
 UIInterfaceOrientationMaskPortrait,
 UIInterfaceOrientationMaskLandscapeLeft,
 UIInterfaceOrientationMaskLandscapeRight,
 UIInterfaceOrientationMaskPortraitUpsideDown,
 UIInterfaceOrientationMaskLandscape,
 UIInterfaceOrientationMaskAll,
 UIInterfaceOrientationMaskAllButUpsideDown,
 */

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notif
{

    NSLog(@"didReceiveLocalNotification");

    ///通知イベントで送られてきた情報（文字列）をメイン画面のラベルに表示します。
    // NSString *itemName = [notif.userInfo objectForKey:@"EventKey"];
    //  [self.viewController updateLabel:itemName];

    // アイコンに右肩に表示されていた数字をカウントダウンします。
    //ここでは数字が０になり、アイコンの右肩の赤丸表示がなくなります。
    application.applicationIconBadgeNumber = 0; //notif.applicationIconBadgeNumber+1;
}

static TopWindow *customWindow = nil;

- (TopWindow *)window
{
    if (customWindow == nil) {
        customWindow = [[TopWindow alloc] init];
        [customWindow makeKeyAndVisible];
        [customWindow setFrame:[[UIScreen mainScreen] bounds]]; //Add
    }
    return customWindow;
}

// 異常終了を検知した場合に呼び出されるメソッド
void exceptionHandler(NSException *exception)
{
    // ここで、例外発生時の情報を出力します。
    // myLog関数でcallStackSymbolsを出力することで、
    // XCODE上で開発している際にも、役立つスタックトレースを取得できるようになります。
    myLog(@"#######%@", exception.name);
    myLog(@"%@", exception.reason);
    myLog(@"%@", exception.callStackSymbols);

    // ログをUserDefaultsに保存しておく。
    // 次の起動の際に存在チェックすれば、前の起動時に異常終了したことを検知できます。
    NSString *log = [NSString stringWithFormat:@"%@, %@, %@", exception.name, exception.reason, exception.callStackSymbols];
    [[NSUserDefaults standardUserDefaults] setValue:log forKey:@"failLog"];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
