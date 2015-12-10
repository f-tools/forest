//
//  ThemeManageVC.m
//
//  タブ: 利用可能、ダウンロード、アップロード
//

#import "ThemeVC.h"
#import "BaseModalNavigationVC.h"
#import "ThemeManager.h"
#import "SSZipArchive.h"

@interface ThemeVC ()

@property (nonatomic, copy) NSArray *themeList;

@property (nonatomic) ThemeEntry *downloadTargetThemeEntry;

@property (nonatomic) UIBarButtonItem *refreshBarButton;

@end

@implementation ThemeVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"戻る"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(backPressed:)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    return self;
}

- (void)backPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidLoad
{
    self.title = @"テーマ";
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.tabBar.delegate = self;
    self.tabBar.selectedItem = self.localTabBarItem;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    self.tableView.separatorColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];
    self.tabBar.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    self.tabBorder.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];

    [self reloadLocalThemes:YES]; // shouldRefresh:YES

    self.refreshBarButton = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                             target:self
                             action:@selector(refreshed:)];
    self.navigationItem.rightBarButtonItem = self.refreshBarButton;
}

- (void)refreshed:(id)sender
{
    if (self.tabBar.selectedItem == self.localTabBarItem) {
        [self reloadLocalThemes:YES];
    } else if (self.tabBar.selectedItem == self.downloadTabBarItem) {
        [self reloadDownloadList];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.themeList count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 46;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tabBar.selectedItem == self.localTabBarItem) {
        return YES;
    } else if (self.tabBar.selectedItem == self.downloadTabBarItem) {
        return NO;
    }

    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ThemeEntry *themeEntry = [self.themeList objectAtIndex:indexPath.row];
        if (themeEntry) {
            [themeEntry deleteFile];
        }

        [self reloadLocalThemes:YES];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {

    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"theme_cell"];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"theme_cell"];
        cell.textLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
        cell.detailTextLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeSubTextColor];

        cell.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
        cell.textLabel.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

        UIView *selectedBackgroundViewForCell = [UIView new];
        [selectedBackgroundViewForCell setBackgroundColor:[[ThemeManager sharedManager] colorForKey:ThemeTableSelectedBackgroundColor]];
        cell.selectedBackgroundView = selectedBackgroundViewForCell;
    }

    ThemeEntry *themeEntry = [self.themeList objectAtIndex:indexPath.row];

    cell.textLabel.text = themeEntry.themeName;
    if (themeEntry.isDownloading) {
        cell.detailTextLabel.text = @"Downloading...";
    } else {
        cell.detailTextLabel.text = @"";
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (tableView.isEditing) {
        //return;
    }

    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    ThemeEntry *themeEntry = [self.themeList objectAtIndex:indexPath.row];
    if (themeEntry.canDownload) {
        self.downloadTargetThemeEntry = themeEntry;
        // 複数行で書くタイプ（複数ボタンタイプ）
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.delegate = self;
        alert.title = @"確認";
        alert.message = @"ダウンロードしますか？";
        [alert addButtonWithTitle:@"いいえ"];
        [alert addButtonWithTitle:@"はい"];
        [alert show];

    } else {
        [self uploadTheme:themeEntry];

        [self dismissViewControllerAnimated:YES
                                 completion:^{
                                   [[ThemeManager sharedManager] tryApplyLocalThemeWithFolderName:themeEntry.folderName];
                                 }];
    }
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item == self.localTabBarItem) {
        self.title = @"テーマ";
        [self reloadLocalThemes:NO]; // shouldRefresh:NO

    } else if (item == self.downloadTabBarItem) {
        self.title = @"ダウンロード";
        [self reloadDownloadList];
    }
}

- (void)reloadLocalThemes:(BOOL)shouldRefresh
{
    if (shouldRefresh) {
        [[ThemeManager sharedManager] updateLocalThemeEntries];
    }
    self.themeList = [[ThemeManager sharedManager] localThemeEntries];
    [self.tableView reloadData];
}

- (void)reloadDownloadList
{
    // リストの取得
    NSString *urlstr = @"http://repo.webcrow.jp/theme/part.php?q=list&page=0";
    NSURL *url = [NSURL URLWithString:urlstr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";

    //NSData* requestData = [postDataString dataUsingEncoding:[bbsItem boardEncoding]];

    [request addValue:[Env userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setTimeoutInterval:10];

    request.HTTPBody = nil;

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

                             } else {
                                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                 NSInteger httpStatusCode = httpResponse.statusCode;
                                 if (httpStatusCode == 404) {
                                     NSLog(@"404 NOT FOUND ERROR. targetURL=%@", url);

                                 } else {
                                     NSLog(@"success request!!");
                                     NSLog(@"statusCode = %ld", (long)((NSHTTPURLResponse *)response).statusCode);
                                     NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                                     if (httpStatusCode != 200) { //404とか
                                         return;
                                     }

                                     NSError *error = nil;
                                     NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                                                  options:NSJSONReadingAllowFragments
                                                                                                    error:&error];

                                     NSMutableArray *themeList = [NSMutableArray array];
                                     for (NSDictionary *entryDict in [jsonResponse objectForKey:@"theme_list"]) {
                                         ThemeEntry *themeEntry = [[ThemeEntry alloc] init];
                                         themeEntry.themeName = [entryDict objectForKey:@"name"];
                                         themeEntry.canDownload = YES;
                                         themeEntry.themeId = [entryDict objectForKey:@"id"];

                                         [themeList addObject:themeEntry];
                                     }

                                     self.themeList = themeList;

                                     // ここはサブスレッドなので、メインスレッドで
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       [self.tableView reloadData];
                                     });
                                 }
                             }
                           }];
}

// アラートのボタンが押された時に呼ばれるデリゲート例文
- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex
{

    switch (buttonIndex) {
    case 0:
        break;
    case 1:
        if (self.downloadTargetThemeEntry) {
            [self downloadTheme:self.downloadTargetThemeEntry];
        }
        break;
    }
}

- (void)downloadTheme:(ThemeEntry *)themeEntry
{
    NSString *themeId = themeEntry.themeId;

    NSString *urlstr = [NSString stringWithFormat:@"http://repo.webcrow.jp/theme/part.php?q=download&id=%@", themeId];
    NSURL *url = [NSURL URLWithString:urlstr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";

    themeEntry.isDownloading = YES;
    [self.tableView reloadData];

    [request addValue:[Env userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setTimeoutInterval:10];

    request.HTTPBody = nil;

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

                             themeEntry.isDownloading = NO;
                             if (error) {
                                 // エラー処理を行う。
                                 if (error.code == -1003) {
                                     NSLog(@"not found hostname. targetURL=%@", url);
                                 } else if (-1019) {
                                     NSLog(@"auth error. reason=%@", error);
                                 } else {
                                     NSLog(@"unknown error occurred. reason = %@", error);
                                 }

                             } else {
                                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                 NSInteger httpStatusCode = httpResponse.statusCode;
                                 if (httpStatusCode == 404) {
                                     NSLog(@"404 NOT FOUND ERROR. targetURL=%@", url);

                                 } else {
                                     NSLog(@"success request!!");
                                     NSLog(@"statusCode = %ld", (long)((NSHTTPURLResponse *)response).statusCode);
                                     NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                                     if (httpStatusCode != 200) { //404とか
                                         return;
                                     }

                                     NSFileManager *fm = [NSFileManager defaultManager];

                                     NSString *tempZipPath = [self tempZipPath:@".zip"];
                                     NSLog(@"tempZipPath = %@", tempZipPath);
                                     //zip保存

                                     if (![fm fileExistsAtPath:tempZipPath]) {
                                         [fm createFileAtPath:tempZipPath
                                                     contents:nil
                                                   attributes:nil];
                                     }
                                     NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:tempZipPath];
                                     if (file == nil) {
                                         myLog(@"Failed to open file23");
                                     }

                                     //[file seekToFileOffset: 0];
                                     //[file truncateFileAtOffset: 0];

                                     [file writeData:data];
                                     [file closeFile];

                                     //解凍フォルダの作成
                                     NSString *tempFolderPath = [self tempZipPath:@"a"];
                                     NSLog(@"tempFolderPath = %@", tempFolderPath);
                                     NSError *theError = nil;

                                     if (![fm createDirectoryAtPath:tempFolderPath
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&theError]) {
                                         // エラーを処理する。
                                     }

                                     [SSZipArchive unzipFileAtPath:tempZipPath toDestination:tempFolderPath];

                                     //zipの消去
                                     NSError *error;
                                     BOOL result = [fm removeItemAtPath:tempZipPath error:&error];
                                     if (result) {
                                     }

                                     // ここはサブスレッドなので、メインスレッドで
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       self.title = @"テーマ";
                                       self.tabBar.selectedItem = self.localTabBarItem;

                                       [self reloadLocalThemes:YES];
                                     });
                                 }
                             }
                           }];
}

- (NSString *)tempZipPath:(NSString *)suffix
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *themeFolderPath = [Env themeFolderPath];

    if (suffix == nil) {
        suffix = @"";
    }

    for (NSInteger i = 0; i < 5000; i++) {
        NSString *tempPath = [themeFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"theme%ld%@", (long)i, suffix]];
        //zipファイルが存在していたら消去
        if ([fm fileExistsAtPath:tempPath]) {
            continue;
        } else {
            return tempPath;
        }
    }

    return nil;
}

- (void)uploadTheme:(ThemeEntry *)themeEntry
{
    NSString *urlstr = [NSString stringWithFormat:@"http://repo.webcrow.jp/theme/part.php?q=upload"];
    NSURL *url = [NSURL URLWithString:urlstr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";

    NSMutableString *mutableStr = [[NSMutableString alloc] init];
    [mutableStr appendFormat:@"name=%@", @"themeSample"];
    [mutableStr appendFormat:@"&creator=%@", @"creator"];
    [mutableStr appendFormat:@"&description=%@", @"description"];
    [mutableStr appendFormat:@"&link=%@", @"link"];
    [mutableStr appendFormat:@"&zipStr=%@", @"zipStr"]; //base64_encode(themeEntry.folderPath)

    /* name creator description link protocol zipStr */

    NSData *requestData = [mutableStr dataUsingEncoding:NSUTF8StringEncoding];

    [request addValue:[Env userAgent] forHTTPHeaderField:@"User-Agent"];
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

                             } else {
                                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                 NSInteger httpStatusCode = httpResponse.statusCode;
                                 if (httpStatusCode == 404) {
                                     NSLog(@"404 NOT FOUND ERROR. targetURL=%@", url);

                                 } else {
                                     NSLog(@"success request!!");
                                     NSLog(@"statusCode = %ld", (long)((NSHTTPURLResponse *)response).statusCode);
                                     NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                                     if (httpStatusCode != 200) { //404とか
                                         return;
                                     }

                                     //zip保存
                                     //
                                     //                NSString *zippedPath = @"owwfef";
                                     //                NSArray *inputPaths = [NSArray arrayWithObjects:
                                     //                         [[NSBundle mainBundle] pathForResource:@"photo1" ofType:@"jpg"],
                                     //                         [[NSBundle mainBundle] pathForResource:@"photo2" ofType:@"jpg"]
                                     //                                 nil];
                                     //                [SSZipArchive createZipFileAtPath:zippedPath withFilesAtPaths:inputPaths];
                                     //
                                     //

                                     // ここはサブスレッドなので、メインスレッドで何かしたい場合には
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       [self.tableView reloadData];
                                     });
                                 }
                             }
                           }];
}

@end
