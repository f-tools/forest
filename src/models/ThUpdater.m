#import "ThUpdater.h"
#import "Th+ParseAdditions.h"
#import "Env.h"
#import "TextUtils.h"
#import "DatParser.h"
#import "ThManager.h"
#import "FavVC.h"
#import <JavaScriptCore/JavaScriptCore.h>

static JSContext *_context;

@interface ThUpdater ()


@end

@implementation ThUpdater

- (id)initWithTh:(Th *)th
{
    if (self = [super init]) {
        _th = th;
    }
    return self;
}

- (UpdateResult *)update:(void (^)(UpdateResult *))completionBlock
{
    self.completionBlock = completionBlock;
    [self update];

    return nil;
}

// 初回更新時
- (UpdateResult *)update
{

    NSString *newConvertScript = [Env getConvertScript:YES];
    if (_context == nil || newConvertScript != nil) {
        if (newConvertScript == nil) {
            newConvertScript = [Env getConvertScript:NO];
        }

        // JavaScriptの関数をObjective-Cで呼び出す
        _context = [[JSContext alloc] init];
        _context[@"multiply"] = ^(int a,int b) { return a * b; };

        [_context evaluateScript:newConvertScript];
    }

    @synchronized(self.th)
    {
        if (self.th.isUpdating) {
            [self finalize:nil];
            return nil;
        }
        self.th.isUpdating = YES;
    }

    [[BoardManager sharedManager] updateBoardInfoForTh:self.th];

    self.tryCount = 0;
    self.forceReload = NO;

    return [self _update];
}

- (void)finalize:(UpdateResult *)result
{
    if (self.completionBlock) {
        self.completionBlock(result);
    }
    self.completionBlock = nil;
    [[FavVC sharedInstance] refreshTabBadge];
}

- (UpdateResult *)_update
{
    self.tryCount++;
    if (self.tryCount > 5) {
        self.th.isUpdating = NO;
        [self finalize:nil];
        return nil;
    }

    NSString *datUrl = [self.th datUrl];
    self.startResNumber = 1;
    BOOL useDiffModeForReadCGI = YES;
    if ([self.th is2ch] || [self.th isPink]) {
        if (useDiffModeForReadCGI) {
            self.startResNumber = (self.th.localCount + 1);
            NSInteger requestFrom = self.startResNumber > 1 ? self.startResNumber - 1 : self.startResNumber;
            datUrl = [NSString stringWithFormat:@"%@%lu-", [self.th threadUrl], (long)requestFrom];
        } else {
            datUrl = [NSString stringWithFormat:@"%@1-", [self.th threadUrl]];
        }

        self.useReadCGI = YES;
    } else {
        self.startResNumber = (self.th.localCount + 1);
    }

    
    
    if (self.isItestMode) {
        self.startResNumber = 1;
        datUrl = [NSString stringWithFormat:@"http://itest.2ch.net/public/newapi/client.php?subdomain=%@&board=%@&dat=%llu", [[self.th.host componentsSeparatedByString:@"."] objectAtIndex:0] ,self.th.boardKey,self.th.key];
    }
    



    self.accessUrl = datUrl;
    NSLog(@"url = %@", datUrl);
    NSURL *nsurl = [NSURL URLWithString:datUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    [request setTimeoutInterval:10];

    NSError *error = nil;

    // ヘッダー情報を追加する。
    [request addValue:[Env userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setTimeoutInterval:10];
    [request addValue:@"close" forHTTPHeaderField:@"Connection"];
    [request addValue:@"text" forHTTPHeaderField:@"Accept-Encoding"];

    NSString *datFilePath = [self.th datFilePath:NO];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *attribute = [fm attributesOfItemAtPath:datFilePath error:&error];
    //    NSDate *creationDate = [attribute objectForKey:NSFileCreationDate];
    //    NSDate *modificationDate = [attribute objectForKey:NSFileModificationDate];
    NSNumber *fileSize = [attribute objectForKey:NSFileSize];

    if (self.useReadCGI == NO && self.th.lastModified && fileSize > 0 && self.forceReload == NO) {

        [request addValue:[@"bytes=" stringByAppendingFormat:@"%@-", fileSize] forHTTPHeaderField:@"Range"];
        [request addValue:@"text" forHTTPHeaderField:@"Accept-Encoding"];
    }


    NSURLConnection *aConnection = [[NSURLConnection alloc]
         initWithRequest:request
                delegate:self
        startImmediately:NO];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      if (aConnection != nil) {
          [aConnection start]; //これで、MyConnectionがRunLoopにattachされる
          [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
      }
    });

    if (!aConnection) {
        myLog(@"connection error.");
        self.th.isUpdating = NO;
        [self finalize:nil];
        return nil;
    }

    return nil;
}

/**
 * Instructs the delegate that authentication for challenge has
 * been cancelled for the request loading on connection.
 */
- (void)connection:(NSURLConnection *)connection
    didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    myLog(@"didCancelAuthenticationChallenge Error");
    ;
    self.th.isUpdating = NO;
    [self finalize:nil];
}

/*
 * Called when an NSURLConnection has failed to load successfully.
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    myLog(@"didFailWithError Error");
    ;
    self.th.isUpdating = NO;
    [self finalize:nil];
}

/**
 * Called when an NSURLConnection has finished loading successfully.
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

      @synchronized(self.th)
      {
          [self dealWithReceivedData];
      }
    });
}

- (NSString *)stringEscapedForJavasacript:(NSString *)str
{
    // valid JSON object need to be an array or dictionary
    NSArray *arrayForEncoding = @[ str ];
    NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:arrayForEncoding options:0 error:nil] encoding:NSUTF8StringEncoding];

    NSString *escapedString = [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];
    return escapedString;
}

- (void)dealWithReceivedData
{

    __block NSData *tempReceivedData = self.receivedData;
    self.receivedData = nil;

    // BOOL downFlag = NO;
    NSInteger statusCode = [self.response statusCode];

    NSLog(@"statusCode = %zd", statusCode);

    NSString *lastModified = nil; //self.lastModified;
    NSString *etag = nil;         //self.etag;

    NSDictionary *dict = [self.response allHeaderFields];
    for (NSString *key in [dict allKeys]) {
        if ([[key lowercaseString] isEqualToString:@"last-modified"]) {
            lastModified = [dict objectForKey:key];
        } else if ([[key lowercaseString] isEqualToString:@"etag"]) {
            etag = [dict objectForKey:key];
        }
    }

    if (statusCode == 503 || statusCode == 520) {
        if ([self.th is2ch] || [self.th isPink]) {
            if (self.isItestMode == NO) {
                self.isItestMode = YES;
                [self _update];
                return;
                
            }
        }
    }
    
    if (statusCode == 416) { // Request Range not valid
        self.forceReload = YES;
        [self _update];
        return;
    }

    if (statusCode != 200 && statusCode != 206 && statusCode != 203 && statusCode != 302) {
        //404とか
        self.th.isUpdating = NO;
        [self finalize:nil];
        return;
    }


    NSString *dataString = nil;

    if (self.isItestMode) {
        dataString = [[NSString alloc] initWithData:tempReceivedData encoding:NSUTF8StringEncoding];
        
        NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:tempReceivedData options:NSJSONReadingAllowFragments error:nil];
        
        NSArray* comments = [jsonObj objectForKey:@"comments"];
        NSMutableString* mutableStr = [NSMutableString string];
        for (NSArray* comment in comments) {
            NSNumber* number = [comment objectAtIndex:0];
            NSString* name = [comment objectAtIndex:1];
            NSString* mail = [comment objectAtIndex:2];
            NSNumber* dateNum = [comment objectAtIndex:3];
            NSString* idStr = [comment objectAtIndex:4];
            NSString* beStr = [comment objectAtIndex:5];
            NSString* bodyText = [comment objectAtIndex:6];
            
            NSString* dateStr = nil;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:dateNum.integerValue];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
            [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [dateFormatter setDateFormat:@"yyyy/MM/dd(E) HH:mm:ss"];
            // [dateFormatter setDateFormat:@"MMM dd, yyyy h:mm"];
            //[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
            
            
            NSString *dte=[dateFormatter stringFromDate:date];
            
            if (idStr && [idStr length] > 0) {
                dateStr = [NSString stringWithFormat:@"%@ ID:%@", dte, idStr];
            } else {
                dateStr = [NSString stringWithFormat:@"%@", dte];
            }
            
            NSString * title = @"";
            if (number.integerValue == 1) {
                NSArray * threadArray = [jsonObj objectForKey:@"thread"];
                title = [threadArray objectAtIndex:5];
            }
            name = [name stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
            name = [name stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
            
            mail = [mail stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
            mail = [mail stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
            
            [mutableStr appendFormat:@"%@<>%@<>%@<>%@<>%@\n", name, mail, dateStr, bodyText,  title];
            
        }
        
        
        
        tempReceivedData = [mutableStr dataUsingEncoding:[self.th boardEncoding]];
        dataString = mutableStr;
        
    } else {
        
        dataString = [TextUtils decodeString:tempReceivedData encoding:[self.th boardEncoding] substitution:@"?"];

        if (self.useReadCGI) { // dat変換

            JSValue *result = [_context[@"convertHtml2Dat"] callWithArguments:@[
                self.accessUrl,
                [NSNumber numberWithInteger:self.startResNumber],
                dataString
            ]];

            dataString = [result toString];

            if ([dataString isEqualToString:@""]) {
                self.th.isUpdating = NO;
                [self finalize:nil];
                return;
            }

            tempReceivedData = [dataString dataUsingEncoding:[self.th boardEncoding]];
        } 
    }

    int nextResNumber = (int)self.th.localCount + 1;
    //BOOL initMode = self.forceReload || ![self.th canAppendDatFileWithInt:statusCode];
    BOOL initMode = self.forceReload;
    if (self.useReadCGI == NO && ![self.th canAppendDatFileWithInt:statusCode]) {
        initMode = YES;
    }
    if (self.isItestMode) {
        initMode = YES;
    }

    if (initMode) {
        nextResNumber = 1; // 新規ファイル作成
        self.th.localCount = 0;

        self.th.count = 0;
        //self.th.read = 0;
        @synchronized(self.th)
        {
            if (self.th.shouldResAdded) {
                [self.th clearResponses];
                self.th.shouldResAdded = YES;
            }
        }
        self.th.lastModified = nil;
    }

    BOOL hasNumber = [self.th isShitaraba] || [self.th isMachiBBS];

    DatParser *datParser = [[DatParser alloc] init];

    [datParser setBBSSubType:[self.th getBBSSubType]];

    NSArray *resList = [datParser parse:dataString offset:(0)];

    NSInteger resCount = self.th.localCount;
    for (Res *res in resList) {
        if (hasNumber) {
            resCount = res.number;
        } else {
            resCount = res.number = nextResNumber;
            nextResNumber++;
        }

        [self.th addRes:res];
    }

    if (resCount != 0)
        self.th.localCount = resCount;

    if (self.th.isDown) {
        //ここまで来たらDat落ち復活
        self.th.isDown = NO;
    }


    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *datPath = [self.th datFilePath:YES];
    if ([fm fileExistsAtPath:datPath] != YES) {
        [fm createFileAtPath:datPath
                    contents:nil
                  attributes:nil];
    }

    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:datPath];

    if (file == nil) {
        myLog(@"Failed to open file");
        return;
    }

    if (initMode) {
        [file truncateFileAtOffset:0];
    } else {
        [file seekToEndOfFile];
    }

    //[file seekToFileOffset: 0];
    [file writeData:tempReceivedData];

    [file closeFile];

    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:datPath error:NULL];
    unsigned long long fileSize = [attributes fileSize];

    myLog(@"th dataSize = %lld", fileSize);
    self.th.datSize = fileSize;

    // カウント更新
    if (self.th.localCount > self.th.count) {
        self.th.count = self.th.localCount;
    }
    if (lastModified != nil) {
        self.th.lastModified = lastModified;
    }
    if (etag != nil) {
        //self.etag = etag;
    }

    self.th.isUpdating = NO;
    // 通知の受取側に送る値を作成する

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

      [NSThread sleepForTimeInterval:2];
      [[ThManager sharedManager] saveThAsync:self.th];

    });

    [self finalize:nil];
    return;
}

/**
 * Called when an authentication challenge is received ... the delegate
 * should send -useCredential:forAuthenticationChallenge: or
 * -continueWithoutCredentialForAuthenticationChallenge: or
 * -cancelAuthenticationChallenge: to the challenge sender when done.
 */
- (void)connection:(NSURLConnection *)connection
    didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    myLog(@"didReceiveAuthenticationChallenge");
}

/**
 * Called when content data arrives during a load operations ... this
 * may be incremental or may be the compolete data for the load.
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{

    [self.receivedData appendData:data];

    NSString *contentLength = [self.response.allHeaderFields objectForKey:@"Content-Length"];

    if (contentLength) {
        self.progress = self.receivedData.length / (float)[contentLength intValue];
    }
}

/**
 * Called when enough information to build a NSURLResponse object has
 * been received.
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.receivedData = [[NSMutableData alloc] init];

    self.response = (NSHTTPURLResponse *)response;
    myLog(@"response %ld", (long)[self.response statusCode]);
}

/**
 * Called with the cachedResponse to be stored in the cache.
 * The delegate can inspect the cachedResponse and return a modified
 * copy if if wants changed to what whill be stored.<br />
 * If it returns nil, nothing will be stored in the cache.
 */
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    myLog(@"willCacheResponse");
    //self.isUpdating = NO;
    return nil;
}

/**
 * Informs the delegate that the connection must change the URL of
 * the request in order to continue with the load operation.<br />
 * This allows the delegate to ionspect and/or modify a copy of the request
 * before the connection continues loading it.  Normally the delegate
 * can return the request unmodifield.<br />
 * The redirection can be rejectected by the delegate calling -cancel
 * or returning nil.<br />
 * Cancelling the load will simply stop it, but returning nil will
 * cause it to complete with a redirection failure.<br />
 * As a special case, this method may be called with a nil response,
 * indicating a change of URL made internally by the system rather than
 * due to a response from the server.
 */
- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{

    myLog(@"willSendRequest URL:%@", [[request URL] absoluteString]);
    NSURLRequest *newRequest = request;
    if (redirectResponse) {
        newRequest = nil;
    }
    return newRequest;
}


@end
