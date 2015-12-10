#import "Env.h"
#import "ThManager.h"
#import "ThemeManager.h"
#import "AppDelegate.h"
#import "CookieManager.h"
#import "MyNavigationVC.h"
#import "HistoryVC.h"
#import "ThUpdater.h"
#import "ResVC.h"
#import "PostConfirmVC.h"
#import "PostNaviVC.h"
#import "TextUtils.h"
#import "AccountConfVC.h"

// 書き込み確認・承認・待機ダイアログ

@interface PostConfirmVC ()

@property (nonatomic) PostSession *postSession;

@property (nonatomic) BOOL confirmMode; //書き込み確認ありか (現時点では確認あり固定)

@end

@implementation PostConfirmVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)viewWillAppear:(BOOL)animated
{

    [self.navigationController setNavigationBarHidden:NO animated:NO];

    self.title = self.postNaviVC.board ? self.postNaviVC.board.boardName : self.postNaviVC.th.title;

    NSString *bodyText = self.text;
    NSString *showText = [NSString stringWithFormat:@"名前: %@\nメール: %@\n\n--------------  本文ここから  --------------\n%@\n--------------  本文ここまで  --------------", self.name, self.mail, bodyText];

    if (self.postNaviVC.board) {
        showText = [NSString stringWithFormat:@"スレッドタイトル: %@\n\n%@", self.threadTitle, showText];
    }

    [self.contentTextView setText:showText];
    [self.contentTextView.superview bringSubviewToFront:self.contentTextView];
    [self.cancelButton setTitle:@"キャンセル" forState:UIControlStateNormal];

    self.confirmMode = YES;
    if (self.confirmMode) {
        [self.proceedButton setTitle:self.postNaviVC.board ? @"スレ立て開始" : @"書き込み開始" forState:UIControlStateNormal];
    } else {
        //[self.proceedButton setTitle:@"承認" forState: UIControlStateNormal];
        [self startPostSession];
    }

    self.statusLabel.text = @"";
}

- (void)setHeightConstraint:(UIView *)view value:(CGFloat)value
{
    for (NSLayoutConstraint *constraint in view.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeHeight || constraint.firstAttribute == NSLayoutAttributeWidth) {
            constraint.constant = value;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.contentWebView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

    self.borderView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    self.middleBorderView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];

    [self setHeightConstraint:self.borderView value:thinLineWidth];
    [self setHeightConstraint:self.middleBorderView value:thinLineWidth];

    self.proceedButton.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    self.cancelButton.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"戻る"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(backPressed:)];

    [self.proceedButton addTarget:self action:@selector(onProceedButtonTap:) forControlEvents:UIControlEventTouchUpInside];

    [self.cancelButton addTarget:self
                          action:@selector(onCancelButtonTap:)
                forControlEvents:UIControlEventTouchUpInside];

    self.navigationItem.leftBarButtonItem = backButton;
    self.contentTextView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    self.contentTextView.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    self.statusLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];

    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    //[self.view bringSubviewToFront:self.modalBackground];
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)backPressed:(id)sender
{
    if (self.postSession) {
        self.postSession.delegate = nil;
        self.postSession = nil;
    }

    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onProceedButtonTap:(id)sender
{
    if (self.postSession == nil) {
        [self startPostSession];
    } else {
        [self.postSession startPost];
    }
}

- (IBAction)onCancelButtonTap:(id)sender
{
    if (self.postSession) {
        self.postSession.delegate = nil;
        self.postSession = nil;
    }

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)startPostSession
{
    self.statusLabel.text = self.postNaviVC.board ? @"スレッド作成中・・・" : @"書き込み中・・・";
    self.postNaviVC.th.lastPostText = self.text;
    self.postSession = [[PostSession alloc] init];
    self.postSession.th = self.postNaviVC.th;
    self.postSession.board = self.postNaviVC.board;
    self.postSession.name = self.name;
    self.postSession.mail = self.mail;
    self.postSession.text = self.text;
    self.postSession.threadTitle = self.threadTitle;

    self.postSession.delegate = self;

    [self.proceedButton setEnabled:NO];

    [self.postSession startPost];
}

- (void)onPostResult:(NSInteger)statusCode
          resultType:(PostResultType)type
          resultBody:(NSString *)body
{

    self.statusLabel.text = @"";
    [self.proceedButton setEnabled:NO];
    if (type == POST_RESULT_SUCCESS) { //成功
        [self.contentTextView setText:self.postNaviVC.board ? @"新規スレッド作成" : @"書き込みが成功しました。"];
        [self.contentTextView.superview bringSubviewToFront:self.contentTextView];


        [self.postNaviVC notifyPostSuccess];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          [NSThread sleepForTimeInterval:1];
          dispatch_async(dispatch_get_main_queue(),
                         ^{

                           [self dismissViewControllerAnimated:YES
                                                    completion:^{
                                                      if (self.postNaviVC.resVC) {
                                                          [self.postNaviVC.resVC requestUpdateForPostSuccess];
                                                      }

                                                      if (self.postNaviVC.onPostCompleted) {

                                                          self.postNaviVC.onPostCompleted(YES);

                                                          self.postNaviVC.onPostCompleted = nil;
                                                      }

                                                    }];

                           [self.navigationController popViewControllerAnimated:NO];
                         });
        });

    } else if (type == POST_RESULT_CONFIRM) { //確認・承認
        [self.contentWebView.superview bringSubviewToFront:self.contentWebView];

        [self.contentWebView loadHTMLString:body baseURL:nil];
        [self.proceedButton setTitle:@"確認・承諾" forState:UIControlStateNormal];
        [self.proceedButton setEnabled:YES];

    } else { // 失敗
        [self.contentWebView loadHTMLString:body baseURL:nil];
        //[self.contentTextView setText:showText];
        [self.contentWebView.superview bringSubviewToFront:self.contentWebView];
        [self.proceedButton setTitle:self.postNaviVC.board ? @"スレ立て開始" : @"書き込み開始" forState:UIControlStateNormal];
        [self.proceedButton setEnabled:YES];
    }
}

- (void)startCommunicate
{
}

- (void)setTextViewStyle:(UITextView *)textView
{
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.keyboardAppearance = UIKeyboardAppearanceDark;
    textView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    textView.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    [textView setFont:[UIFont systemFontOfSize:14]];
}

@end

@interface PostSession ()

@property (nonatomic, copy) NSString *hiddenName;
@property (nonatomic, copy) NSString *hiddenValue;

@end

@implementation PostSession

- (void)startPost
{

    AccountConfVC *confVC = [[AccountConfVC alloc] init];
    [confVC loginRouninIfEnabled:^(BOOL success) {
      Th *th = self.th;
        
      BBSItemBase *bbsItem = self.board ? self.board : self.th;
        NSString *urlstr = [bbsItem getPostUrl];
        NSURL *url = [NSURL URLWithString:urlstr];
      NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
      request.HTTPMethod = @"POST";

      CookieManager *cm = [CookieManager sharedManager];
      // ヘッダー情報を追加する。
      NSString *cookie = [cm cookieForServer:bbsItem.host];
      if (cookie) {
          [request addValue:cookie forHTTPHeaderField:@"Cookie"];
      }

      NSString *postDataString = [bbsItem createPostData:self.board != nil name:self.name mail:self.mail text:self.text subjectOrKey:self.board ? self.threadTitle : [NSString stringWithFormat:@"%llu", self.th.key]];

      if (self.hiddenName && self.hiddenValue) {
          postDataString = [postDataString stringByAppendingFormat:@"&%@=%@", self.hiddenName, self.hiddenValue];
      }

      if ([Env getConfBOOLForKey:@"rouninLoggedIn" withDefault:NO]) {
          NSString *sid = [Env getEncryptedStringForKey:@"rouninSid" withDefault:nil];
          if (sid) {
              postDataString = [postDataString stringByAppendingFormat:@"&sid=%@", [self percentEscape:sid]];
          }

          myLog(@"postData = %@", postDataString);
      }

      NSData *requestData = [postDataString dataUsingEncoding:[bbsItem boardEncoding]];

      [request addValue:[Env userAgent] forHTTPHeaderField:@"User-Agent"];
        
      [request setTimeoutInterval:10];
      [request addValue:self.board ? [self.board boardUrl] : [th threadUrl] forHTTPHeaderField:@"Referer"];
      [request addValue:[NSString stringWithFormat:@"%ld", (unsigned long)requestData.length] forHTTPHeaderField:@"Content-Length"];

      request.HTTPBody = requestData;

      [NSURLConnection sendAsynchronousRequest:request
                                         queue:[[NSOperationQueue alloc] init]
                             completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

                               if (error) {
                                   // エラー処理を行う。
                                   if (error.code == -1003) {
                                       NSLog(@"not found hostname. targetURL=%@", url);
                                   } else if (-1019) {
                                       NSLog(@"auth error. reason=%@", error);
                                   } else {
                                       NSLog(@"unknown error occurred. reason = %@", error);
                                   }

                                   [self finalize:0];

                               } else {
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   NSInteger httpStatusCode = ((NSHTTPURLResponse *)response).statusCode;
                                   if (httpStatusCode == 404) {
                                       NSLog(@"404 NOT FOUND ERROR. targetURL=%@", url);
                                       // } else if (・・・) {
                                       // 他にも処理したいHTTPステータスがあれば書く。
                                       [self finalize:httpStatusCode];
                                   } else {
                                       NSLog(@"success request!!");
                                       NSLog(@"statusCode = %ld", (long)((NSHTTPURLResponse *)response).statusCode);
                                       NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                                       //クッキーの取得・設定
                                       NSDictionary *dict = [httpResponse allHeaderFields];
                                       for (NSString *key in [dict allKeys]) {
                                           myLog(@"There are %@: %@'s in reponse headers", key, [dict objectForKey:key]);
                                           if ([[key lowercaseString] isEqualToString:@"set-cookie"]) {
                                               CookieManager *cm = [CookieManager sharedManager];
                                               NSString *cookie = [dict objectForKey:key];

                                               if (cookie) {
                                                   [cm setCookie:cookie forServer:bbsItem.host];
                                               }
                                           }
                                       }

                                       if (httpStatusCode != 200) { //404とか
                                           [self finalize:httpStatusCode];
                                           return;
                                       }

                                       NSString *dataString = [TextUtils decodeString:data encoding:[bbsItem boardEncoding] substitution:@"?"];

                                       [self tryFindHiddenValues:dataString];

                                       PostResultType resultType = [bbsItem getPostResult:dataString];

                                       // ここはサブスレッドなので、メインスレッドで
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                         if (self.delegate) {
                                             [self.delegate onPostResult:httpStatusCode resultType:resultType resultBody:dataString];
                                         }
                                       });
                                   }
                               }
                             }];
    }];
}

- (NSString *)percentEscape:(NSString *)str
{

    NSString *escapedUrlString = (NSString *)CFBridgingRelease(
        CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)str, NULL, (CFStringRef) @"!*'();:@&=+$,/?%#[]<>", kCFStringEncodingUTF8));
    //                                                                                                       kCFStringEncodingShiftJIS));
    return escapedUrlString;
}

- (void)finalize:(NSInteger)statusCode
{
    if (self.delegate) {
        [self.delegate onPostResult:statusCode resultType:POST_RESULT_FAIL resultBody:@"error"];
    }
}

- (void)tryFindHiddenValues:(NSString *)str
{

    NSString *target = @"input type=hidden name=\"";

    NSRange result = [str rangeOfString:target];
    if (result.location == NSNotFound) return;

    NSInteger nameStart = result.location + [target length];

    str = [str substringFromIndex:nameStart];
    result = [str rangeOfString:@"\""];
    if (result.location == NSNotFound) return;

    NSString *tempHiddenName = [str substringToIndex:result.location];

    str = [str substringFromIndex:result.location + 1];

    result = [str rangeOfString:@"\""];
    if (result.location == NSNotFound) return;

    str = [str substringFromIndex:result.location + 1];

    result = [str rangeOfString:@"\""];
    if (result.location == NSNotFound) return;

    NSString *tempHiddenValue = [str substringToIndex:result.location];

    if (tempHiddenName && tempHiddenValue) {
        if ([tempHiddenName rangeOfString:@"<"].location == NSNotFound) {
            // addCookie(server, name + "=" + value + ";");
            self.hiddenName = tempHiddenName;
            self.hiddenValue = tempHiddenValue;
            myLog(@"hiddenName and hiddenValue = ", self.hiddenName, self.hiddenValue);
        }
    }
}

@end
