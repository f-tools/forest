//
//  ThListTransaction.m
//  Forest
//

#import "ThListTransaction.h"
#import "Env.h"
#import "TextUtils.h"
#import "AppDelegate.h"
#import "ThreadListParser.h"
#import "ThManager.h"
#import "NextSearchVC.h"
#import "MyNavigationVC.h"
#import "MySplitVC.h"

@implementation ThListTransaction


- (void)dealloc
{
}

// 板のスレ一覧を開く開始
- (BOOL)startOpenThListTransaction:(Board *)board
{
    if (board == nil) return NO;

    self.isNavigationTransaction = YES;

    self.title = [@"板「" stringByAppendingString:board.boardName == nil ? board.boardKey : board.boardName];
    self.title = [self.title stringByAppendingString:@"」をロード中・・"];

    self.board = board;

    BOOL success = [[MySplitVC sideNavInstance] startTransaction:self];
    if (success) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{

                         dispatch_async(dispatch_get_main_queue(),
                                        ^{
                                          [self updateWithBoard:board];
                                        });
                       });
    } 

    return success;
}

- (void)updateWithBoard:(Board *)board
{
    NSArray *list = [self loadThreadListWithBoard:board];
    if (list) {
    }
}

// スレ一覧の更新
- (NSArray *)loadThreadListWithBoard:(Board *)board
{
    NSString *subjectUrl = [board subjectUrl];
    myLog(@"url= %@", subjectUrl);
    NSURL *nsurl = [NSURL URLWithString:subjectUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];

    [request addValue:[Env userAgent] forHTTPHeaderField:@"User-Agent"];
    [request addValue:@"close" forHTTPHeaderField:@"Connection"];
    [request addValue:@"text" forHTTPHeaderField:@"Accept-Encoding"];

    NSURLConnection *aConnection = [[NSURLConnection alloc]
         initWithRequest:request
                delegate:self
        startImmediately:NO];

    [aConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [aConnection start];

    // 作成に失敗する場合には、リクエストが送信されないので
    // チェックする
    if (!aConnection) {
        myLog(@"connection error.");
        //self.th.isUpdating = NO;
        [self finalize:nil];
        return nil;
    }

    return nil;
}

- (void)finalize:(NSObject *)result
{
    [[MySplitVC sideNavInstance] closeTransaction:self];
}

/**
 * Instructs the delegate that authentication for challenge has
 * been cancelled for the request loading on connection.
 */
- (void)connection:(NSURLConnection *)connection
    didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    myLog(@"didCancelAuthenticationChallenge Error");
    [self finalize:nil];
}

/*
 * Called when an NSURLConnection has failed to load successfully.
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    myLog(@"didFailWithError Error");
    ;
    //   self.th.isUpdating = NO;
    [self finalize:nil];
}

/**
 * Called when an NSURLConnection has finished loading successfully.
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //@synchronized (self.th) {
    [self dealWithReceivedData];
    // }
}

- (void)dealWithReceivedData
{

    __block NSData *tempReceivedData = self.receivedData;
    self.receivedData = nil;
    BOOL downFlag = NO;
    NSInteger statusCode = [self.response statusCode];

    myLog(@"statusCode = %d", statusCode);

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

    if (statusCode == 416) { // Request Range not valid
        [self finalize:nil];
        return;
    }

    if (statusCode == 203 || statusCode == 302) { // dat落ちフラグ
        [self finalize:nil];
        downFlag = YES;
        return;
    }

    if (statusCode != 200 && statusCode != 206 && statusCode != 203 && statusCode != 302) {
        //404とか
        [self finalize:nil];
        return;
    }


    dispatch_async(dispatch_get_main_queue(), ^{

      [UIView animateWithDuration:0.1
          delay:0.1
          options:0
          animations:^{
            [self changeProgress:1];

          }
          completion:^(BOOL finished) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              ThreadListParser *threadListParser = [ThreadListParser alloc];
              [threadListParser setBBSSubType:[self.board getBBSSubType]];

              NSArray *thList = [threadListParser parse:tempReceivedData];

              NSMutableArray *newThList = [NSMutableArray array];
              ThManager *sharedManager = [ThManager sharedManager];
              for (Th *th in thList) {
                  th.serverDir = self.board.serverDir;
                  th.host = self.board.host;
                  th.boardKey = self.board.boardKey;
                  // th.boardName = board.boardName;

                  Th *newTh = [sharedManager registerTh:th canLoadFile:NO];

                  if (newTh != th) {
                      newTh.number = th.number;
                  }
                  [newThList addObject:newTh];
              }


              dispatch_async(dispatch_get_main_queue(), ^{
                if (self.isCanceled) {
                    return;
                }

                if (self.isNextSearch) {
                    NextSearchVC *vc = [[NextSearchVC alloc] init];
                    vc.thList = newThList;
                    vc.th = self.th;

                    if ([MySplitVC instance].isTabletMode) {
                        [[MainVC instance] showThListVC:vc];
                    } else {
                        [[MyNavigationVC instance] pushMyViewController:vc withTransaction:self];
                    }

                } else if (self.thListVC) {
                    [self.thListVC notifyThListUpdated:newThList];

                } else {
                    ThListVC *ctrl = [[ThListVC alloc] initWithNibName:@"ThListVC" bundle:nil];
                    [ctrl setThList:newThList withBoard:self.board];

                    if ([MySplitVC instance].isTabletMode) {
                        [[MainVC instance] showThListVC:ctrl];
                    } else {
                        [[MyNavigationVC instance] pushMyViewController:ctrl withTransaction:self];
                    }
                }

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                  dispatch_async(dispatch_get_main_queue(), ^{
                    [self finalize:nil];
                  });
                });
              });
            });

          }];

      // });
    });

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
}

/**
 * Called when content data arrives during a load operations ... this
 * may be incremental or may be the compolete data for the load.
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];

    //  for (NSString* key in self.response.allHeaderFields.keyEnumerator) {
    //    myLog(@"key = %@, value = %@", key, [self.response.allHeaderFields objectForKey:key]);
    //  }

    NSString *contentLength = [self.response.allHeaderFields objectForKey:@"Content-Length"];
    myLog(@"contentLength = %@", contentLength);
    myLog(@"self.response.expectedContentLength = %lld", self.response.expectedContentLength);

    if (contentLength) {
        self.progress = self.receivedData.length / (float)[contentLength intValue];

        [self changeProgress:self.progress];
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
