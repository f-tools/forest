#import "Env.h"
#import "ImageUploadManager.h"
#import "ResVm.h"
#import <SDWebImage/SDWebImageManager.h>
#import <FMDatabase.h>
#import <AssetsLibrary/ALAssetRepresentation.h>

@implementation ImageUploadEntry

- (id)init
{
    if (self = [super init]) {
        self.rowId = -1;
    }
    return self;
}

@end

@interface ImageUploadManager ()

@property (nonatomic) NSMutableArray *queue;
@property (nonatomic) BOOL isUploading;

@end

//
// 画像のアップロードを管理する
//
@implementation ImageUploadManager

static ImageUploadManager *_sharedImageUploadManager;

static NSString *const UploadImageTableName = @"uploaded_images";
static NSString *const COL_DeleteUrl = @"deleteUrl";
static NSString *const COL_WebUrl = @"webUrl";
static NSString *const COL_SDWebImageUrl = @"sdWebImageUrl";
static NSString *const COL_UploadedTime = @"uploadedTime";
static NSString *const COL_ImageKey = @"imageKey";

- (id)init
{
    if (self = [super init]) {
        _queue = [NSMutableArray array];

        FMDatabase *db = [self openFMDatabase];

        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT, %@ TEXT,  %@ TEXT, %@ TEXT, %@ TEXT, %@ INTEGER);", UploadImageTableName, COL_WebUrl, COL_DeleteUrl, COL_SDWebImageUrl, COL_ImageKey, COL_UploadedTime];

        [db open];
        [db executeUpdate:sql];
        [db close];
    }
    return self;
}

- (FMDatabase *)openFMDatabase
{
    FMDatabase *db = [FMDatabase databaseWithPath:[[Env documentPath]
                                                      stringByAppendingPathComponent:@"upimg.db"]];
    return db;
}

+ (ImageUploadManager *)sharedManager
{
    @synchronized(self)
    {
        if (!_sharedImageUploadManager) {
            _sharedImageUploadManager = [[self alloc] init];
        }
    }
    return _sharedImageUploadManager;
}

- (NSMutableArray *)historyEntries
{

    FMDatabase *db = [self openFMDatabase];
    if (db == nil) return nil;

    NSString *sql = [NSString stringWithFormat:@"SELECT %@, %@,%@,%@,%@,%@ FROM %@ order by id desc;", COL_WebUrl, COL_DeleteUrl, COL_SDWebImageUrl, COL_UploadedTime, COL_ImageKey, @"id", UploadImageTableName];

    [db open];

    FMResultSet *results = [db executeQuery:sql];
    NSMutableArray *entries = [[NSMutableArray alloc] initWithCapacity:0];
    while ([results next]) {
        ImageUploadEntry *entry = [[ImageUploadEntry alloc] init];
        //entry.rowid = [results intForColumnIndex:0];
        entry.webUrl = [results stringForColumnIndex:0];
        entry.deleteUrl = [results stringForColumnIndex:1];
        entry.sdWebImageUrl = [results stringForColumnIndex:2];
        entry.uploadedTime = [results intForColumnIndex:3];
        entry.imageKey = [results stringForColumnIndex:4];
        entry.rowId = [results intForColumnIndex:5];

        [entries addObject:entry];
    }

    [db close];

    return entries;
}

- (void)deleteImageFromDB:(ImageUploadEntry *)entry
{
    if (entry.rowId >= 0) {
        FMDatabase *db = [self openFMDatabase];
        if (db == nil) return;
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE id = ?", UploadImageTableName];

        [db open];
        [db executeUpdate:sql, [NSNumber numberWithInteger:entry.rowId]];
        [db close];
    }
}


- (void)addRequests:(NSArray *)entries
{
    @synchronized(self.queue)
    {

        for (NSInteger i = [entries count] - 1; i >= 0; i--) {
            ImageUploadEntry *entry = [entries objectAtIndex:i];
            entry.isUploading = YES;

            [self.queue addObject:entry];
        }
    }

    [self _tryStartUpload];
}

- (void)_tryStartUpload
{
    @synchronized(self)
    {
        if (self.isUploading) {
            return;
        }
        self.isUploading = YES;
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
 
    [self _startUpload];
}

- (void)_startUpload
{
    @synchronized(self)
    {
        if ([self.queue count] == 0) {
            self.isUploading = NO;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            return;
        }

        ImageUploadEntry *entry = [self.queue lastObject];
        if (!entry) {
            self.isUploading = NO;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            return;
        }

        [self.queue removeLastObject];
        [self uploadImageAsync:entry];
    }
}

- (void)uploadImageAsync:(ImageUploadEntry *)entry
{

    ALAsset *asset = entry.asset;

    ALAssetRepresentation *rep = [asset defaultRepresentation];
    Byte *buffer = (Byte *)malloc((long)rep.size);

    // add error checking here
    long long buffered = [rep getBytes:buffer fromOffset:0.0 length:(NSUInteger)rep.size error:nil];
    NSData *imageData = [NSData dataWithBytesNoCopy:buffer length:(NSUInteger)buffered freeWhenDone:YES];

    NSString *urlstr = @"http://repo.webcrow.jp/image/image.php?q=upload";

    NSURL *nsurl = [NSURL URLWithString:urlstr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    request.HTTPMethod = @"POST";
    [request setTimeoutInterval:140];

    NSMutableData *body = [[NSMutableData alloc] init];

    NSString *boundary = @"------------------a7V4kRcFA8E79pivMuV2tukQ85cmNKeoEgJgq";
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];

    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"json\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/json; charset=UTF-8\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Transfer-Encoding: 8bit\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

    NSString *text = @"tet";
    // request JSON
    NSString *bodyString = [NSString stringWithFormat:@""
                                                       "{ \"body\":\r\n"
                                                       "   {\r\n"
                                                       "      \"messageSegments\" : [\r\n"
                                                       "      {\r\n"
                                                       "         \"type\" : \"Text\", \r\n"
                                                       "         \"text\" : \"%@\"\r\n"
                                                       "      }\r\n"
                                                       "      ]\r\n"
                                                       "   }, \r\n"
                                                       "   \"attachment\": \r\n"
                                                       "   {\r\n"
                                                       "      \"desc\": \"Quarterly review\",\r\n"
                                                       "      \"filename\": \"filename.png\"\r\n"
                                                       "   }\r\n"
                                                       "}",
                                                      text];

    [body appendData:[[NSString stringWithFormat:@"%@\r\n", bodyString] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"img1\"; filename=\"%@\"\r\n", @"fileName"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

    [body appendData:imageData];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    request.HTTPBody = body;

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                             entry.isUploading = NO;

                             if (error) {
                                 if (error.code == -1003) {
                                     //   NSLog(@"not found hostname. targetURL=%@", url);
                                 } else if (-1019) {
                                     NSLog(@"auth error. reason=%@", error);
                                 } else {
                                     NSLog(@"unknown error occurred. reason = %@", error);
                                 }


                             } else {
                                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                 NSInteger httpStatusCode = httpResponse.statusCode;
                                 if (httpStatusCode == 404) {
                                     // NSLog(@"404 NOT FOUND ERROR. targetURL=%@", url);
                                 } else {
                                     NSLog(@"success request!!");
                                     NSLog(@"statusCode = %ld", (long)((NSHTTPURLResponse *)response).statusCode);
                                     NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                                     if (httpStatusCode != 200) { //404とか
                                         return;
                                     }

                                     NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];

                                     FMDatabase *db = [self openFMDatabase];
                                     if (db == nil) return;
                                     [db open];

                                     //{"key":"uZrCL.jpg","url":"http:\/\/repo.webcrow.jp\/iuZrCL.jpg","deleteUrl":"http:\/\/repo.webcrow.jp\/image\/image.php?q=delete&key=uZrCL&del=aH8pN"}

                                     NSString *uuid = [[NSUUID UUID] UUIDString];
                                     NSString *sdWebImageUrl = [NSString stringWithFormat:@"forestupimage://images/%@.jpg", uuid];

                                     NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@) VALUES (?,?,?,?,?);",
                                                                                UploadImageTableName, COL_WebUrl, COL_DeleteUrl, COL_SDWebImageUrl, COL_ImageKey, COL_UploadedTime];

                                     NSString *imageKey = [jsonObj objectForKey:@"key"];

                                     NSString *webUrl = [jsonObj objectForKey:@"url"];
                                     NSString *deleteUrl = [jsonObj objectForKey:@"deleteUrl"];
                                     NSLog(@"imageKey = %@", imageKey);
                                     NSLog(@"deleteUrl = %@", deleteUrl);
                                     NSLog(@"sdWebImageUrl =%@ ", sdWebImageUrl);
                                     NSLog(@"time = %f", [[NSDate date] timeIntervalSince1970]);

                                     NSInteger nowTime = (NSInteger)[[NSDate date] timeIntervalSince1970];
                                     [db executeUpdate:sql, webUrl, deleteUrl, sdWebImageUrl, imageKey, [NSNumber numberWithInteger:nowTime]];
                                     NSInteger lastId = (NSInteger)[db lastInsertRowId];
                                     [db close];

                                     entry.webUrl = webUrl;
                                     entry.imageKey = imageKey;
                                     entry.deleteUrl = deleteUrl;
                                     entry.sdWebImageUrl = sdWebImageUrl;
                                     entry.uploadedTime = nowTime;
                                     entry.rowId = lastId;

                                     if (entry.completion) {
                                         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                           dispatch_sync(dispatch_get_main_queue(), ^{
                                             entry.completion(entry);
                                             entry.completion = nil;
                                           });
                                         });
                                     }
                                 }
                             }

                             [self _startUpload];
                           }];
}

- (void)deleteImage:(ImageUploadEntry *)entry completion:(void (^)(BOOL))completionBlock
{
    NSString *urlstr = entry.deleteUrl; // @"http://repo.webcrow.jp/image/image.php?q=delete&keys";
    NSURL *nsurl = [NSURL URLWithString:urlstr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    request.HTTPMethod = @"GET";
    [request setTimeoutInterval:140];

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

                                 // [self finalize:0 message:@"network error" completion:completionBlock];

                             } else {
                                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                 NSInteger httpStatusCode = httpResponse.statusCode;
                                 if (httpStatusCode == 404) {
                                     // NSLog(@"404 NOT FOUND ERROR. targetURL=%@", url);
                                     // } else if (・・・) {
                                     // 他にも処理したいHTTPステータスがあれば書く。
                                     //  [self finalize:httpStatusCode message:@"NOT Found" completion:completionBlock];
                                 } else {
                                     NSLog(@"success request!!");
                                     NSLog(@"statusCode = %ld", (long)((NSHTTPURLResponse *)response).statusCode);
                                     NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                                     if (httpStatusCode != 200) { //404とか
                                         return;
                                     }

                                     NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                                     entry.deleteResultMessage = [jsonObj objectForKey:@"message"];
                                     [self deleteImageFromDB:entry];
                                     if (completionBlock) {
                                         completionBlock(YES);
                                         return;
                                     }
                                 }
                             }

                             if (completionBlock) {
                                 completionBlock(NO);
                                 return;
                             }


                           }];
}

@end
