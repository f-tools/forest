#import "PostActionMenu.h"
#import "MyNavigationVC.h"
#import "ThListTransaction.h"
#import "BoardManager.h"
#import "ThManager.h"
#import "ActionLayout.h"
#import "ThemeManager.h"
#import "AppDelegate.h"
#import "SearchWebViewController.h"
#import "FontSizeActionMenu.h"
#import "NGListVC.h"
#import "SyncManager.h"
#import "SyncTransaction.h"
#import "ThemeVC.h"
#import "ImageUploadVC.h"
#import "MySplitVC.h"
#import "BaseModalNavigationVC.h"
#import "UIViewController+WrapWithNavigationController.h"

@interface PostActionMenu ()



@property (nonatomic) ActionButtonInfo *deleteTextInfo;
@property (nonatomic) ActionButtonInfo *imageUploadConf;
@property (nonatomic) ActionButtonInfo *imgurButtonInfo;

@property (nonatomic) UISegmentedControl *themeSegmentedControl;

@end

@implementation PostActionMenu

- (void)dealloc
{
}

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

- (NSArray *)createAllButtons
{
    if (self.deleteTextInfo == nil) {
        self.deleteTextInfo = [[ActionButtonInfo alloc] initWithTitle:@"本文消去" withImageName:@"delete_30.png"];
        self.imageUploadConf = [[ActionButtonInfo alloc] initWithTitle:@"画像アップロード"
                                                         withImageName:@"arrowup.png"];
        ;
        self.imgurButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"Imgur"
                                                         withImageName:@"arrowup.png"];
        ;
    }

    return @[self.imgurButtonInfo, self.deleteTextInfo, self.imageUploadConf];
}

- (void)onButtonTap:(ActionButtonInfo *)info
{
    if (info == self.deleteTextInfo) {
        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
          [[MySplitVC instance] closeActionMenu:nil
                                             complete:^{

                                               if (self.onDeleteRequest) {
                                                   self.onDeleteRequest();
                                               }

                                             }];
        });

    } else if (info == self.imageUploadConf) {
        [self.navigationController closeActionMenu:nil
                                           complete:^{
                                             ImageUploadVC *picker = [[ImageUploadVC alloc] init];
                                             picker.onAddedText = self.onAddedText;
                                             UINavigationController *navi = [picker wrapWithNavigationController];
                                             [self.navigationController presentViewController:navi animated:YES completion:nil];
                                           }];
    } else if (info == self.imgurButtonInfo) {
        [self.navigationController closeActionMenu:nil
                                           complete:^{
                                               NSString *url = @"http://m.imgur.com/upload";
                                               
                                               SearchWebViewController *searchWebViewController = [[SearchWebViewController alloc] init];
                                               searchWebViewController.searchUrl = url;
                                               
                                               UINavigationController *con = [searchWebViewController wrapWithNavigationController];
                                               
                                               [self.navigationController presentViewController:con animated:YES completion:nil];
                   
                                           }];
    }
}

@end
