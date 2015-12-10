//
//  AccountConfVC.m
//  Forest
//

#import "AccountConfVC.h"
#import "Env.h"
#import "CookieManager.h"

@interface AccountConfVC ()

@end

@implementation AccountConfVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (NO == [Env getConfBOOLForKey:@"cryptSupport" withDefault:NO]) {

        NSString *oldRouninId = [Env getConfStringForKey:@"rouninId" withDefault:nil];
        if (oldRouninId) {
            [Env setConfString:nil forKey:@"rouninId"];
            [Env setEncryptedString:oldRouninId forKey:@"rouninId"];
        }

        NSString *oldrouninPass = [Env getConfStringForKey:@"rouninPass" withDefault:nil];
        if (oldrouninPass) {
            [Env setConfString:nil forKey:@"rouninPass"];
            [Env setEncryptedString:oldrouninPass forKey:@"rouninPass"];
        }

        NSString *oldbeId = [Env getConfStringForKey:@"beId" withDefault:nil];
        if (oldbeId) {
            [Env setConfString:nil forKey:@"beId"];
            [Env setEncryptedString:oldbeId forKey:@"beId"];
        }

        NSString *oldbePass = [Env getConfStringForKey:@"bePass" withDefault:nil];
        if (oldbePass) {
            [Env setConfString:nil forKey:@"bePass"];
            [Env setEncryptedString:oldbePass forKey:@"bePass"];
        }

        [Env setConfBOOL:YES forKey:@"cryptSupport"];
    }

    //    rouninLoggedIn
    NSString *rouninId = [Env getEncryptedStringForKey:@"rouninId" withDefault:@""];
    NSString *rouninPass = [Env getEncryptedStringForKey:@"rouninPass" withDefault:@""];
    self.rouninIDTextField.text = rouninId;
    self.rouninPassTextField.text = rouninPass;

    NSString *beId = [Env getEncryptedStringForKey:@"beId" withDefault:nil];
    NSString *bePass = [Env getEncryptedStringForKey:@"bePass" withDefault:nil];
    self.beIDField.text = beId;
    self.bePassField.text = bePass;

    [self refreshLoginStatus:[Env getConfBOOLForKey:@"rouninLoggedIn" withDefault:NO]];
    [self updateBELabel];
}

- (void)refreshLoginStatus:(BOOL)asLogin
{
    [self.loginActionButton setTitle:asLogin ? @"ログアウト" : @"ログイン" forState:UIControlStateNormal];
    self.loginStatusLabel.text = asLogin ? @"状態: ログインしています" : @"状態: ログインしていません";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}

/*
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
 
 // Configure the cell...
 
 return cell;
 }
 */

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Table view delegate
 
 // In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
 - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Navigation logic may go here, for example:
 // Create the next view controller.
 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
 
 // Pass the selected object to the new view controller.
 
 // Push the view controller.
 [self.navigationController pushViewController:detailViewController animated:YES];
 }
 */

/**
 *
 * BE
 *
 */
- (IBAction)loginAction:(id)sender
{
    [Env setEncryptedString:self.rouninIDTextField.text forKey:@"rouninId"];

    [Env setEncryptedString:self.rouninPassTextField.text forKey:@"rouninPass"];

    BOOL loggedIn = [Env getConfBOOLForKey:@"rouninLoggedIn" withDefault:NO];
    if (loggedIn) {
        [Env setConfBOOL:NO forKey:@"rouninLoggedIn"];
        [self refreshLoginStatus:NO];
    } else {
        [self loginRounin:^(BOOL success) {

          [Env setConfBOOL:success forKey:@"rouninLoggedIn"];
          [self refreshLoginStatus:success];
        }];
    }
}

//public
- (void)loginRouninIfEnabled:(void (^)(BOOL))completion
{
    BOOL loggedIn = [Env getConfBOOLForKey:@"rouninLoggedIn" withDefault:NO];
    if (loggedIn) {
        [self loginRounin:completion];
    } else {
        completion(NO);
    }
}

- (void)loginRounin:(void (^)(BOOL))completion
{

    NSString *rouninId = [Env getEncryptedStringForKey:@"rouninId" withDefault:nil];
    NSString *rouninPass = [Env getEncryptedStringForKey:@"rouninPass" withDefault:nil];

    NSString *urlstr = [NSString stringWithFormat:@"https://2chv.tora3.net/futen.cgi"];
    NSString *da = [NSString stringWithFormat:@"ID=%@&PW=%@", rouninId, rouninPass];

    NSURL *url = [NSURL URLWithString:urlstr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";

    self.loginStatusLabel.text = @"ログイン中・・・";

    NSData *requestData = [da dataUsingEncoding:NSUTF8StringEncoding];

    [request addValue:[Env userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setTimeoutInterval:10];
    // [request addValue:[th threadUrl] forHTTPHeaderField:@"Referer"];
    [request addValue:[NSString stringWithFormat:@"%tu", requestData.length] forHTTPHeaderField:@"Content-Length"];

    //- (NSString*) createPostDate:(NSString*)name mail:(NSString*)mail text:(NSString*)text {

    request.HTTPBody = requestData;

    // 送信するリクエストを生成する。
    //NSURL *url = [NSURL URLWithString:@"http://www.yoheim.net/"];
    //NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];

    // リクエストを送信する。
    // 第３引数のブロックに実行結果が渡される。
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

                                 // [self finalize:0];

                             } else {
                                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                 NSInteger httpStatusCode = httpResponse.statusCode;
                                 if (httpStatusCode == 404) {
                                     NSLog(@"404 NOT FOUND ERROR. targetURL=%@", url);
                                     // } else if (・・・) {
                                     // 他にも処理したいHTTPステータスがあれば書く。
                                     //  [self finalize:httpStatusCode];
                                 } else {

                                     NSLog(@"statusCode = %@", @(((NSHTTPURLResponse *)response).statusCode));
                                     NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                                     if (httpStatusCode != 200) { //404とか
                                         //  [self finalize:httpStatusCode];
                                         return;
                                     }

                                     NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

                                     if ([dataString hasPrefix:@"SESSION-ID="]) {
                                         NSString *sid = [dataString substringFromIndex:[@"SESSION-ID=" length]];
                                         if ([sid hasPrefix:@"ERROR"] == NO) {
                                             [Env setEncryptedString:sid forKey:@"rouninSid"];
                                             myLog(@"sessionId = %@", sid);
                                             // ここはサブスレッドなので、メインスレッドで何かしたい場合には
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                   if (completion) {
                                                       completion(YES);
                                                   }
                                             });
                                             return;
                                         }
                                     }
                                 }
                             }
                             dispatch_async(dispatch_get_main_queue(), ^{
                               if (completion) {
                                   completion(NO);
                               }
                             });
                           }];
}

- (IBAction)rouninIDChanged:(id)sender
{
    [Env setEncryptedString:self.rouninIDTextField.text forKey:@"rouninId"];
}

- (IBAction)rouninPassChanged:(id)sender
{
    [Env setEncryptedString:self.rouninPassTextField.text forKey:@"rouninPass"];
}

- (IBAction)backItemAction:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    //    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateBELabel
{
    CookieManager *cm = [CookieManager sharedManager];
    BOOL loggedIn = [cm hasBECookie];
    [self.beLoginButton setTitle:loggedIn ? @"ログアウト" : @"ログイン" forState:UIControlStateNormal];
    self.beLabel.text = loggedIn ? @"状態: ログインしています" : @"状態: ログインしていません";
}
//@property (weak, nonatomic) IBOutlet UILabel *beLabel;
//

/**
 *
 * BE
 *
 */
- (IBAction)beLoginButtonAction:(id)sender
{
    CookieManager *cm = [CookieManager sharedManager];
    BOOL loggedIn = [cm hasBECookie];
    if (loggedIn) {
        [cm removeBECookie];
        [self updateBELabel];
        return;
    }

    NSString *urlStr = @"http://be.2ch.net/test/login.php";

    NSString *beId = self.beIDField.text;
    NSString *bePass = self.bePassField.text;

    [Env setEncryptedString:beId forKey:@"beId"];
    [Env setEncryptedString:bePass forKey:@"bePass"];

    self.beLabel.text = @"ログイン中・・・";

    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";

    NSString *da = [NSString stringWithFormat:@"m=%@&p=%@&submit=%@", [self urlEncWithSHIFT_JIS:beId], [self urlEncWithSHIFT_JIS:bePass], [self urlEncWithSHIFT_JIS:@"ログイン"]];

    NSData *requestData = [da dataUsingEncoding:NSShiftJISStringEncoding];

    [request addValue:[Env userAgent] forHTTPHeaderField:@"User-Agent"];
    [request addValue:[NSString stringWithFormat:@"%@", @(requestData.length)] forHTTPHeaderField:@"Content-Length"];
    [request setTimeoutInterval:10];

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

                                 // [self finalize:0];

                             } else {
                                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                 NSInteger httpStatusCode = ((NSHTTPURLResponse *)response).statusCode;
                                 if (httpStatusCode == 404) {
                                     NSLog(@"404 NOT FOUND ERROR. targetURL=%@", url);
                                     // } else if (・・・) {
                                     // 他にも処理したいHTTPステータスがあれば書く。
                                     //  [self finalize:httpStatusCode];
                                 } else {
                                     NSLog(@"success request!!");
                                     NSLog(@"statusCode = %@", @(((NSHTTPURLResponse *)response).statusCode));
                                     NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                                     if (httpStatusCode != 200) { //404とか
                                         //  [self finalize:httpStatusCode];
                                         return;
                                     }

                                     BOOL foundDMDM = NO;
                                     //クッキーの取得・設定
                                     NSDictionary *dict = [httpResponse allHeaderFields];
                                     CookieManager *cm = [CookieManager sharedManager];
                                     for (NSString *key in [dict allKeys]) {
                                         myLog(@"There are %@: %@'s in reponse headers", key, [dict objectForKey:key]);
                                         if ([[key lowercaseString] isEqualToString:@"set-cookie"]) {
                                             NSString *cookie = [dict objectForKey:key];

                                             if (cookie) {
                                                 [cm setCookie:cookie forServer:@"be.2ch.net"];
                                                 if ([cookie rangeOfString:@"DMDM"].location != NSNotFound) {
                                                     foundDMDM = YES;
                                                 }
                                             }
                                         }
                                     }

                                     NSString *dataString = [[NSString alloc] initWithData:data encoding:NSShiftJISStringEncoding];

                                     myLog(@"dataString = %@", dataString);
                                 }
                             }
                             dispatch_async(dispatch_get_main_queue(), ^{
                               [self updateBELabel];
                             });
                           }];
}

- (NSString *)urlEncWithSHIFT_JIS:(NSString *)str
{

    NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (CFStringRef)str,
        NULL,
        (CFStringRef) @"!*'();:@&=+$,/?%#[]<>",
        //                kCFStringEncodingUTF8 ));
        kCFStringEncodingShiftJIS));
    return escapedUrlString;
}
@end
