#import "SyncManager.h"
#import "FavVC.h"
#import "Env.h"
#import "HistoryVC.h"
#import "ThManager.h"
#import "SyncCrypt.h"

#import "TextUtils.h"

static SyncManager *_sharedSyncManager;

@interface SyncManager ()

@property (nonatomic) NSTimer *autoSyncTimer;
@property (nonatomic, copy) NSString *currentCategory;
@property (nonatomic) FavFolder *currentFavFolder;
@property (nonatomic, copy) NSString *receiveSyncNumber;
@property (nonatomic, copy) NSString *receiveClientId;
@property (nonatomic) NSMutableArray *favFolders;
@property (nonatomic) NSMutableArray *historyList;
@property (nonatomic) NSMutableDictionary *idEntities;

@property (nonatomic) NSMutableData *receivedData;
@property (nonatomic) NSHTTPURLResponse *response;
@property (nonatomic) SyncCrypt *crypt;

@end

@implementation SyncManager

+ (SyncManager *)sharedManager
{
    @synchronized(self)
    {
        if (!_sharedSyncManager) {
            _sharedSyncManager = [[self alloc] init];
        }
    }
    return _sharedSyncManager;
}

- (BOOL)canSync
{
    return !self.isSynchronizing;
}

- (void)startAutoSyncIfEnabled
{
    BOOL autoSyncEnabled = [Env getConfBOOLForKey:@"autoSync" withDefault:NO];
    if (autoSyncEnabled) {
        [self startAutoSync];
    }
}

- (void)startAutoSync
{
    [self stopAutoSync];

    self.autoSyncTimer = [NSTimer scheduledTimerWithTimeInterval:180.f
                                                          target:self
                                                        selector:@selector(callTrySyncWithTimer:)
                                                        userInfo:nil
                                                         repeats:YES];
    [self.autoSyncTimer fire];
}

- (void)stopAutoSync
{
    if (self.autoSyncTimer) {
        [self.autoSyncTimer invalidate];
        self.autoSyncTimer = nil;
    }
}

- (void)callTrySyncWithTimer:(NSTimer *)timer
{
    [self trySync:nil];
}

- (void)finalize:(BOOL)succeed message:(NSString *)message completion:(void (^)(BOOL success))completionBlock
{
    if (!succeed) {
        NSLog(@"sync2ch error: %@", message);
    }
    self.isSynchronizing = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
      if (completionBlock) {
          completionBlock(succeed);
      }
    });
}

- (void)trySync:(void (^)(BOOL success))completionBlock
{
    if (self.isSynchronizing) {
        [self finalize:NO message:@"同期中です" completion:completionBlock];
        return;
    }

    self.isSynchronizing = YES;

    NSString *body = [self createRequestXML];

    NSString *urlstr = @"http://sync2ch.com/api/sync3";

    NSURL *nsurl = [NSURL URLWithString:urlstr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    request.HTTPMethod = @"POST";

    NSString *syncId = [Env getConfStringForKey:@"Sync2ch_ID" withDefault:nil];
    NSString *syncPass = [Env getConfStringForKey:@"Sync2ch_PASS" withDefault:nil];
    if (syncId == nil || syncPass == nil) {
        [self finalize:NO message:@"設定不備" completion:completionBlock];
    }

    NSString *idAndPass = [self encBase64:[NSString stringWithFormat:@"%@:%@", syncId, syncPass]];
    [request addValue:[NSString stringWithFormat:@"Basic %@", idAndPass] forHTTPHeaderField:@"Authorization"];

    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

                             if (error) {
                                 if (error.code == -1003) {
                                     //   NSLog(@"not found hostname. targetURL=%@", url);
                                 } else if (-1019) {
                                     NSLog(@"auth error. reason=%@", error);
                                 } else {
                                     NSLog(@"unknown error occurred. reason = %@", error);
                                 }

                                 [self finalize:NO message:@"network error" completion:completionBlock];

                             } else {
                                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                 NSUInteger httpStatusCode = httpResponse.statusCode;
                                 if (httpStatusCode == 404) {
                                     [self finalize:NO message:@"NOT Found" completion:completionBlock];
                                 } else {
                                     if (httpStatusCode != 200) {
                                         NSString* errorMsg = [NSString stringWithFormat:@"Error, status code: %@", @(httpStatusCode)];
                                         [self finalize:NO message:errorMsg completion:completionBlock];
                                         return;
                                     }

                                     [self parseResponseXML:data];
                                     [self finalize:YES message:@"Success" completion:completionBlock];
                                 }
                             }

                             self.isSynchronizing = NO;
                           }];
}

+ (NSString *)xmlEscape:(NSString *)str
{
    if (str == nil) return @"";
    // myLog(@"str = %@", str);

    NSMutableString *result = [NSMutableString stringWithString:str];
    [result replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
    [result replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
    [result replaceOccurrencesOfString:@"'" withString:@"&#x27;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];

    [result replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
    [result replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];

    return result;
}

- (NSString *)encBase64:(NSString *)text
{
    return [TextUtils encodeBase64:text];
}

- (NSString *)createRequestXML
{
    FavVC *favVc = [FavVC sharedInstance];
    HistoryVC *historyVc = [HistoryVC sharedInstance];

    int syncCryptLevel = (int)[Env getConfIntegerForKey:@"syncCryptLevel" withDefault:0];

    SyncCrypt *crypt = [[SyncCrypt alloc] init];
    if (syncCryptLevel > 0) {
        NSString *cryptPass = [Env getConfStringForKey:@"syncCryptPass" withDefault:@""];
        [crypt setKey:cryptPass withCryptLevel:syncCryptLevel];
    }
    self.crypt = crypt;

    NSMutableString *mutableString = [[NSMutableString alloc] init];
    NSString *syncNumStr = [Env getConfStringForKey:@"sync_number" withDefault:@"0"];
    NSString *clientIdStr = [Env getConfStringForKey:@"client_id" withDefault:@"0"];

    NSString *appVersion = [Env appVersion];
    NSString *iosVersion = [Env iosVersion];

    NSString *cryptLevelAttr = syncCryptLevel == 0 ? @"" : [NSString stringWithFormat:@" crypt_level=\"%d\"", syncCryptLevel];

    [mutableString appendFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?> <sync2ch_request  sync_number=\"%@\" client_id=\"%@\" client_name=\"Forest\" client_version=\"%@\" os=\"iOS %@\"%@>", syncNumStr, clientIdStr, appVersion, iosVersion, cryptLevelAttr];

    //履歴
    NSArray *list = [historyVc getThVmList];

    [mutableString appendString:@"<thread_group category=\"history\">"];
    NSInteger historyCount = 0;
    for (ThVm *thVm in list) {
        if (historyCount++ > 50) {
            break;
        }
        Th *th = thVm.th;
        [mutableString appendFormat:@"<th url=\"%@\" title=\"%@\" read=\"%@\" count=\"%@\" now=\"%@\" rt=\"%lu\"/>", [SyncManager xmlEscape:[crypt encUrl:[th threadUrl]]], [SyncManager xmlEscape:[crypt encTitle:th.title url:[th threadUrl]]],
                                    [crypt encRead:th.read
                                               url:[th threadUrl]],
                                    [crypt encCount:th.count
                                                url:[th threadUrl]],
                                    [crypt encNow:th.reading
                                              url:[th threadUrl]],
                                    (unsigned long)th.lastReadTime];
    }
    [mutableString appendString:@"</thread_group>"];

    //お気に入り
    [mutableString appendString:@"<thread_group category=\"favorite\">"];
    BOOL first = YES;
    for (FavFolder *favFolder in favVc.favFolders) {
        BOOL shouldCloseTag = NO;
        if (first) {
            first = NO;
        } else {
            [mutableString appendFormat:@"<dir name=\"%@\">", [SyncManager xmlEscape:[crypt encFolder:favFolder.name]]];
            shouldCloseTag = YES;
        }

        for (ThVm *thVm in favFolder.thVmList) {
            Th *th = thVm.th;
            [mutableString appendFormat:@"<th url=\"%@\" title=\"%@\" read=\"%@\" count=\"%@\" now=\"%@\" rt=\"%lu\"/>",

                                        [SyncManager xmlEscape:[crypt encUrl:[th threadUrl]]],
                                        [SyncManager xmlEscape:[crypt encTitle:th.title url:[th threadUrl]]],
                                        [crypt encRead:th.read
                                                   url:[th threadUrl]],
                                        [crypt encCount:th.count
                                                    url:[th threadUrl]],
                                        [crypt encNow:th.reading
                                                  url:[th threadUrl]],
                                        (unsigned long)th.lastReadTime];
        }

        if (shouldCloseTag) {
            [mutableString appendFormat:@"</dir>"];
        }
    }
    [mutableString appendString:@"</thread_group>"];
    [mutableString appendString:@"</sync2ch_request>"];

    return mutableString;
}

- (void)parseResponseXML:(NSData *)data
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    self.favFolders = nil;
    self.historyList = nil;
    self.idEntities = [NSMutableDictionary dictionary];

    [parser parse];

    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.favFolders) {
          FavVC *favVc = [FavVC sharedInstance];
          [favVc applySyncFavFolders:self.favFolders];
      }
    });
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.historyList) {
          HistoryVC *historyVc = [HistoryVC sharedInstance];
          [historyVc applySyncThList:self.historyList];
      }
    });

    if (self.receiveSyncNumber > 0) {
        [Env setConfString:self.receiveSyncNumber forKey:@"sync_number"];
        self.receiveSyncNumber = 0;
    }

    if (self.receiveClientId > 0) {
        [Env setConfString:self.receiveClientId forKey:@"client_id"];
        self.receiveClientId = 0;
    }
}

- (NSString *)escape:(NSString *)str
{
    return str;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
       namespaceURI:(NSString *)namespaceURI
      qualifiedName:(NSString *)qName
         attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"sync2ch_response"]) {
        self.receiveSyncNumber = [attributeDict objectForKey:@"sync_number"];
        self.receiveClientId = [attributeDict objectForKey:@"client_id"];

    } else if ([elementName isEqualToString:@"entities"]) {

        self.currentCategory = nil;

    } else if ([elementName isEqualToString:@"thread_group"]) {
        self.currentCategory = [attributeDict objectForKey:@"category"];
        if ([self.currentCategory isEqualToString:@"favorite"]) {
            self.favFolders = [NSMutableArray array];
            FavFolder *favFolder = [[FavFolder alloc] init];
            favFolder.name = @"Top";
            favFolder.isTopFolder = YES;
            [self.favFolders addObject:favFolder];
            self.currentFavFolder = favFolder;
        } else if ([self.currentCategory isEqualToString:@"history"]) {

            self.historyList = [NSMutableArray array];
        }

    } else if ([elementName isEqualToString:@"dir"]) {
        if ([self.currentCategory isEqualToString:@"favorite"]) {
            FavFolder *favFolder = [[FavFolder alloc] init];

            favFolder.name = [self.crypt decFolder:[attributeDict objectForKey:@"name"]];
            [self.favFolders addObject:favFolder];
            self.currentFavFolder = favFolder;
        }
    } else if ([elementName isEqualToString:@"th"]) {
        if (self.currentCategory == nil) {
            //in entities
            Th *th = [self registerSyncTh:attributeDict];

            if (th) {
                [self.idEntities setObject:th forKey:[attributeDict objectForKey:@"id"]];
            }
        } else if ([self.currentCategory isEqualToString:@"favorite"]) {
            Th *th = [self.idEntities objectForKey:[attributeDict objectForKey:@"id"]];
            if (th && self.currentFavFolder) {
                ThVm *thVm = [[ThVm alloc] initWithTh:th];
                thVm.showFavState = NO;
                [self.currentFavFolder.thVmList addObject:thVm];
            }
        } else if ([self.currentCategory isEqualToString:@"history"]) {
            Th *th = [self.idEntities objectForKey:[attributeDict objectForKey:@"id"]];
            if (th) {
                [self.historyList addObject:th];
            }
        }
    }
}

- (Th *)registerSyncTh:(NSDictionary *)dict
{

    NSString *url = [self.crypt decUrl:[dict objectForKey:@"url"]];

    if (url == nil) return nil;

    Th *th = [Th thFromUrl:url];
    th.reading = [[self.crypt decNow:[dict objectForKey:@"now"] url:url] integerValue];
    th.read = [[self.crypt decRead:[dict objectForKey:@"read"] url:url] integerValue];
    th.count = [[self.crypt decCount:[dict objectForKey:@"count"] url:url] integerValue];
    th.title = [self.crypt decTitle:[dict objectForKey:@"title"] url:url];

    NSString *rt = [dict objectForKey:@"rt"];
    th.lastReadTime = rt ? [rt longLongValue] : [[NSDate date] timeIntervalSince1970] - 60 * 30;
    // myLog(@"th.lastReadTime = %lld", th.lastReadTime);

    Th *newTh = [[ThManager sharedManager] registerTh:th];
    if (newTh != th) {
        [[ThManager sharedManager] saveThAsync:newTh];
    }
    return newTh;
}

@end
