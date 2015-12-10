#import "MyNavigationVC.h"
#import "ThListTransaction.h"
#import "BoardManager.h"
#import "ThManager.h"
#import "ActionLayout.h"
#import "ThemeManager.h"
#import "NGManager.h"
#import "SDWebImageManager.h"
#import "SearchWebViewController.h"
#import "Th+ParseAdditions.h"
#import "CopyVC.h"
#import "ResVC+Touch.h"
#import "MySplitVC.h"
#import "ResActionMenu.h"
#import "ResVm.h"
#import "NGItemEditVC.h"
#import "UIViewController+WrapWithNavigationController.h"

@interface ResActionMenu ()

@property (nonatomic) ActionButtonInfo *addNGIDButtonInfo;
@property (nonatomic) ActionButtonInfo *hissiCheckButtonInfo;

@property (nonatomic) ActionButtonInfo *removeNGItemButtonInfo;
@property (nonatomic) ActionButtonInfo *editNGItemButtonInfo;

@property (nonatomic) ActionButtonInfo *moveBoardButtonInfo;

//forAll
@property (nonatomic) ActionButtonInfo *resWithAnchorButtonInfo;
@property (nonatomic) ActionButtonInfo *ngButtonInfo;
@property (nonatomic) ActionButtonInfo *myResButtonInfo;
@property (nonatomic) ActionButtonInfo *beginCopyButtonInfo;
@property (nonatomic) ActionButtonInfo *selectTextButtonInfo;
@property (nonatomic) ActionButtonInfo *toggleAAButtonInfo;
@property (nonatomic) ActionButtonInfo *popupCenterButtonInfo;

//for NG
@property (nonatomic) ActionButtonInfo *ngWordButtonInfo;
@property (nonatomic) ActionButtonInfo *ngNameButtonInfo;
@property (nonatomic) ActionButtonInfo *ngIdButtonInfo;

@property (nonatomic) ActionButtonInfo *searchGoogleImageButtonInfo;
@property (nonatomic) ActionButtonInfo *saveImageButtonInfo;

//for link
@property (nonatomic) ActionButtonInfo *linkCopyButtonInfo;
@property (nonatomic) ActionButtonInfo *openInEmbedBrowserButtonInfo;
@property (nonatomic) ActionButtonInfo *openInExternalBrowserButtonInfo;

//for Copy
@property (nonatomic) ActionButtonInfo *anchorCopyButtonInfo;
@property (nonatomic) ActionButtonInfo *nameCopyButtonInfo;
@property (nonatomic) ActionButtonInfo *mailCopyButtonInfo;
@property (nonatomic) ActionButtonInfo *allCopyButtonInfo;
@property (nonatomic) ActionButtonInfo *bodyCopyButtonInfo;
@property (nonatomic) ActionButtonInfo *numberCopyButtonInfo;
@property (nonatomic) ActionButtonInfo *selectCopyButtonInfo;

@end

@implementation ResActionMenu

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
    if (self.forIDInText || self.forID) {
        if (self.addNGIDButtonInfo == nil) {
            self.addNGIDButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"NGID登録"
                                                               withImageName:@"ng_shield_30.png"];
        }

        if (self.hissiCheckButtonInfo == nil) {
            self.hissiCheckButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"必死チェッカー" withImageName:@"hissi_30.png"];
        }

        return @[ self.addNGIDButtonInfo, self.hissiCheckButtonInfo ];

    } else if (self.forNGItem) {
        if (self.removeNGItemButtonInfo == nil) {
            self.removeNGItemButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"NG解除" withImageName:@"ng_shield_30.png"];
            self.editNGItemButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"NG編集" withImageName:@"ng_shield_30.png"];
        }
        return @[ self.removeNGItemButtonInfo, self.editNGItemButtonInfo ];

    } else if (self.forAll) {
        if (self.resWithAnchorButtonInfo == nil) {
            self.resWithAnchorButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"返信" withImageName:@"reply_30.png"];
        }

        if (self.ngButtonInfo == nil) {
            self.ngButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"NG" withImageName:@"ng_shield_30.png"];

            self.myResButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"マーク" withImageName:@"check_30.png"];
            self.beginCopyButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"コピー" withImageName:@"copy_30.png"];
            self.selectTextButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"文字選択" withImageName:@"text_30.png"];
            self.popupCenterButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"元位置\n参照" withImageName:@"home2_30.png"];
            self.toggleAAButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"AAモード\n切替" withImageName:@"aa_30.png"];

        }

        return @[
            self.resWithAnchorButtonInfo,
            self.beginCopyButtonInfo,
            self.ngButtonInfo,
            self.myResButtonInfo,
            self.popupCenterButtonInfo,
            self.selectTextButtonInfo,
            self.toggleAAButtonInfo
        ];

    } else if (self.forThumbnail) {
        if (self.saveImageButtonInfo == nil) {
            self.saveImageButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"保存" withImageName:@"download_30.png"];
            self.searchGoogleImageButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"画像検索" withImageName:@"search_30.png"];
        }
        return @[ self.saveImageButtonInfo, self.searchGoogleImageButtonInfo ];

    } else if (self.forNG) {
        self.isVerticalMode = YES;
        if (self.ngWordButtonInfo == nil) {
            self.ngWordButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"本文でNG" withImageName:@"ng_shield_30.png"];
            self.ngIdButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"IDでNG" withImageName:@"ng_shield_30.png"];
            self.ngNameButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"名前でNG" withImageName:@"ng_shield_30.png"];
        }
        return @[ self.ngWordButtonInfo, self.ngIdButtonInfo, self.ngNameButtonInfo ];

    } else if (self.forLink) {
        if (self.linkCopyButtonInfo == nil) {
            self.linkCopyButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"コピー" withImageName:nil];
            self.openInEmbedBrowserButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"内蔵ブラウザ" withImageName:nil];
            self.openInExternalBrowserButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"外部ブラウザ" withImageName:nil];
        }
        return @[ self.linkCopyButtonInfo, self.openInEmbedBrowserButtonInfo, self.openInExternalBrowserButtonInfo ];

    } else if (self.forCopy) {
        self.isVerticalMode = YES;
        if (self.anchorCopyButtonInfo == nil) {

            self.anchorCopyButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"アンカー" withImageName:@"copy_30.png"];
            self.nameCopyButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"名前" withImageName:@"copy_30.png"];
            self.mailCopyButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"メール" withImageName:@"copy_30.png"];
            self.allCopyButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"全部" withImageName:@"copy_30.png"];
            self.bodyCopyButtonInfo = [[ActionButtonInfo alloc] initWithTitle:@"本文" withImageName:@"copy_30.png"];
        }
        return @[ self.anchorCopyButtonInfo, self.nameCopyButtonInfo, self.mailCopyButtonInfo, self.allCopyButtonInfo, self.bodyCopyButtonInfo ];
    }

    return nil;
}

// @override
- (void)onLayoutCompleted
{
}

- (NSString *)encBase64:(NSString *)text
{
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    // base64 encoding
    NSString *encoded_data;
    if ([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        encoded_data = [data base64EncodedStringWithOptions:kNilOptions]; // iOS7 and later
    } else {
        // encoded_data = [data base64Encoding]; // iOS6 and prior
    }

    myLog(@"base64 enced %@", encoded_data);
    return encoded_data;

    myLog(@"%@", encoded_data);

    // base64 decoding
    NSData *decoded_data;
    if ([NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)]) {
        decoded_data = [[NSData alloc] initWithBase64EncodedString:encoded_data options:kNilOptions];
    } else {
        // decoded_data = [[NSData alloc] initWithBase64Encoding:encoded_data];
    }

    return nil;
}

- (void)onButtonTap:(ActionButtonInfo *)info
{
    if (self.forID || self.forIDInText) {
        if (info.button == self.addNGIDButtonInfo.button) {
            NGItem *ngItem = [NGItem ngIdItem];
            ngItem.value = self.forIDInText ? self.idText : self.res.ID;
            ngItem.board = [[BoardManager sharedManager] boardForTh:self.resVC.th];
            [[NGManager sharedManager] addNGItem:ngItem];
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{
                                                 [[ThemeManager sharedManager] notifyThemeChanged:[NSDictionary dictionaryWithObjectsAndKeys:@"resBodySize", @"confChange", nil]];

                                               }];
        } else if (info.button == self.hissiCheckButtonInfo.button) {
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{

                                                 Th *th = self.resVC.th;
                                                 Res *res = self.res;
                                                 [res date];
                                                 NSString *dateStr = res.dateStr;
                                                 NSString *tempStr = [dateStr stringByReplacingOccurrencesOfString:@"/" withString:@""];
                                                 if ([tempStr rangeOfString:@"("].location == NSNotFound) {

                                                 } else {
                                                     tempStr = [tempStr substringToIndex:8];
                                                 }
                                                 myLog(@"tempStr = %@", tempStr);

                                                 NSString *url = [NSString stringWithFormat:@"http://hissi.org/read.php/%@/%@/%@.html", th.boardKey, tempStr,
                                                                                            [[self encBase64:res.ID] stringByReplacingOccurrencesOfString:@"="
                                                                                                                                               withString:@""]];

                                                 SearchWebViewController *searchWebViewController = [[SearchWebViewController alloc] init];
                                                 searchWebViewController.searchUrl = url; //self.searchTextView.text;
                                                   if ([MySplitVC instance].isTabletMode) {
                                                       
                                                       [[MainVC instance] showThListVC:searchWebViewController];
                                                   } else {
                                                       [[MyNavigationVC instance] pushMyViewController:searchWebViewController];
                                                   }

                                               }];
        }
    }

    if (self.forNGItem) {
        if (info.button == self.removeNGItemButtonInfo.button) {
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{
                                                 [[NGManager sharedManager] removeNGItem:self.ngItem];
                                                 [[ThemeManager sharedManager] notifyThemeChanged:[NSDictionary dictionaryWithObjectsAndKeys:@"resBodySize", @"confChange", nil]];
                                               }];

        } else if (info.button == self.editNGItemButtonInfo.button) {
            NGItemEditVC *ngItemEditVC = [[NGItemEditVC alloc] initWithNibName:@"NGItemEditVC" bundle:nil];

            ngItemEditVC.ngItem = self.ngItem;
            //ngItemEditVC.shouldDismiss = YES;

            UINavigationController *navVC = [ngItemEditVC wrapWithNavigationController];
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{
                                                 [[MySplitVC instance] presentViewController:navVC
                                                                                         animated:YES
                                                                                       completion:^{

                                                                                       }];
                                               }];
        }
    }

    if (self.forAll) {
        if (info.button == self.resWithAnchorButtonInfo.button) {
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{
                                                 PostNaviVC *postNaviVC = [[MySplitVC instance]  sharedPostNaviVC];
                                                 postNaviVC.th = self.resVC.th;
                                                 postNaviVC.resVC = self.resVC;
                                                 [[MySplitVC instance] presentViewController:postNaviVC
                                                                                         animated:YES
                                                                                       completion:^{
                                                                                         [postNaviVC addText:[NSString stringWithFormat:@">>%d\n", self.res.number]];

                                                                                       }];
                                               }];
        } else if (info.button == self.ngButtonInfo.button) {
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{
                                                 ResActionMenu *actionMenu = [[ResActionMenu alloc] init];
                                                 actionMenu.forNG = YES;
                                                 actionMenu.resVC = self.resVC;
                                                 actionMenu.res = self.res;
                                                 [actionMenu build];
                                                 [actionMenu open];
                                               }];
        } else if (info.button == self.myResButtonInfo.button) {
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{
                                                 [self.resVC.th updateMyResInfo:self.res isMine:!self.res.isMine];
                                                 [[ThemeManager sharedManager] notifyThemeChanged:[NSDictionary dictionaryWithObjectsAndKeys:@"resBodySize", @"confChange", nil]];
                                               }];

        } else if (info == self.beginCopyButtonInfo) {
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{
                                                 ResActionMenu *actionMenu = [[ResActionMenu alloc] init];
                                                 actionMenu.forCopy = YES;
                                                 actionMenu.isVerticalMode = YES;
                                                 actionMenu.resVC = self.resVC;
                                                 actionMenu.res = self.res;
                                                 [actionMenu build];
                                                 [actionMenu open];
                                               }];

        } else if (info == self.selectTextButtonInfo) {
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{
                                                 CopyVC *copyVc = [[CopyVC alloc] init];
                                                 copyVc.text = [self.res allText];

                                                 __weak ResActionMenu *weakSelf = self;
                                                 copyVc.onResSearchRequest = ^(NSString *searchText) {
                                                   if (weakSelf && weakSelf.resVC) {
                                                       [weakSelf.resVC startSearchWithText:searchText];
                                                   }
                                                 };

                                                 UINavigationController *con = [copyVc wrapWithNavigationController];

                                                 [[MySplitVC instance] presentViewController:con
                                                                                         animated:YES
                                                                                       completion:^{
                                                                                       }];
                                               }];


        } else if (info == self.toggleAAButtonInfo) {
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{
                                                 self.res.isAA = !self.res.isAA;
                                                 [[ThemeManager sharedManager] notifyThemeChanged:
                                                                                   [NSDictionary dictionaryWithObjectsAndKeys:@"resBodySize", @"confChange", nil]];
                                               }];
        } else if (info == self.popupCenterButtonInfo) {
            [[MySplitVC instance] closeActionMenu:nil
                                         complete:^{
                                                        [self.resVC popupCenterWithRes:self.res];
                                         }];

            


        }
    }

    if (self.forNG) {
        if (info == self.ngWordButtonInfo || info == self.ngIdButtonInfo || info == self.ngNameButtonInfo) {
            NGItemEditVC *ngItemEditVC = [[NGItemEditVC alloc] initWithNibName:@"NGItemEditVC" bundle:nil];
            NGItem *ngItem = nil;
            if (self.ngWordButtonInfo == info) {
                ngItem = [NGItem ngWordItem];
                ngItem.value = [self.res naturalText];
            } else if (info == self.ngIdButtonInfo) {
                ngItem = [NGItem ngIdItem];
                ngItem.value = self.res.ID;
            } else if (info == self.ngNameButtonInfo) {
                ngItem = [NGItem ngNameItem];
                ngItem.value = self.res.name;
            }
            if (ngItem) {
                ngItem.board = [[BoardManager sharedManager] boardForTh:self.resVC.th];

                ngItemEditVC.initialMode = YES;
                ngItemEditVC.ngItem = ngItem;
                //ngItemEditVC.shouldDismiss = YES;

                UINavigationController *navVC = [ngItemEditVC wrapWithNavigationController];
                [[MySplitVC instance] closeActionMenu:nil
                                                   complete:^{
                                                     [[MySplitVC instance] presentViewController:navVC
                                                                                             animated:YES
                                                                                           completion:^{

                                                                                           }];
                                                   }];
            }
        }
    }

    if (self.forCopy) {

        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             if (info == self.anchorCopyButtonInfo) {
                                                 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                 pasteboard.string = [NSString stringWithFormat:@">>%d", self.res.number];
                                             } else if (info == self.nameCopyButtonInfo) {
                                                 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                 pasteboard.string = self.res.name;
                                             } else if (info == self.mailCopyButtonInfo) {
                                                 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                 pasteboard.string = self.res.mail;
                                             } else if (info == self.allCopyButtonInfo) {
                                                 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                 pasteboard.string = [self.res allText];
                                             } else if (info == self.bodyCopyButtonInfo) {
                                                 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                 pasteboard.string = [self.res naturalText];
                                             }

                                           }];
    }

    if (self.forLink) {
        [[MySplitVC instance] closeActionMenu:nil
                                           complete:^{
                                             if (info == self.linkCopyButtonInfo) {
                                                 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                 pasteboard.string = self.linkUrl;
                                             } else if (info == self.openInEmbedBrowserButtonInfo) {
                                                 SearchWebViewController *searchWebViewController = [[SearchWebViewController alloc] init];
                                                 searchWebViewController.searchUrl = self.linkUrl;
                                                 UINavigationController *con = [searchWebViewController wrapWithNavigationController];

                                                 [[MySplitVC instance] presentViewController:con
                                                                                         animated:YES
                                                                                       completion:^{

                                                                                       }];

                                             } else if (info == self.openInExternalBrowserButtonInfo) {
                                                 NSURL *nsurl = [NSURL URLWithString:self.linkUrl];
                                                 [[UIApplication sharedApplication] openURL:nsurl];
                                             }

                                           }];
    }
    if (self.forThumbnail) {
        if (info.button == self.saveImageButtonInfo.button) {
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{

                                                 SDWebImageManager *manager = [SDWebImageManager sharedManager];
                                                 [manager downloadImageWithURL:[NSURL URLWithString:self.thumbnailInfo.url]
                                                     options:SDWebImageRetryFailed
                                                     progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                     }
                                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                       [self savePhoto:image];
                                                     }];

                                               }];
        } else if (info == self.searchGoogleImageButtonInfo) {
            [[MySplitVC instance] closeActionMenu:nil
                                               complete:^{
                                                 NSString *googleUrl = [NSString stringWithFormat:@"https://www.google.co.jp/searchbyimage?&image_url=%@", [self percentEscape:self.thumbnailInfo.url]];
                                                 
                                                   
                                                 [self.resVC.navigationController openUrlInDefaultWay:googleUrl];
                                               }];
        }
    }
}

- (NSString *)percentEscape:(NSString *)str
{

    NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (CFStringRef)str,
        NULL,
        (CFStringRef) @"!*'();:@&=+$,/?%#[]<>",
        kCFStringEncodingUTF8));
    //kCFStringEncodingShiftJIS));
    return escapedUrlString;
}

- (void)savePhoto:(UIImage *)orizinalSizeImage
{
    UIImageWriteToSavedPhotosAlbum(orizinalSizeImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

//写真保存後にコールバックされる
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) { //エラーのとき

    } else { //保存できたとき
    }
}
@end
