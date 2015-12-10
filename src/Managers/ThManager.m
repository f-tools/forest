#import "ThManager.h"
#import "Env.h"


//
// スレッドの情報を管理する
//
@implementation ThManager


//
// スレのインスタンスを一元管理する(スレのキー -> Thオブジェクト）
// 2chの場合は".2ch.net/apple/1402839204"
// したらばの場合は "anime/1234/1402939203"がキー
//
// _thMapはstrongToWeakObjectsMapTable :値は弱参照
//
static NSMapTable *_thMap;

static ThManager *_sharedThManager;

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

+ (ThManager *)sharedManager
{
    @synchronized(self)
    {
        if (!_sharedThManager) {
            _sharedThManager = [[self alloc] init];

            _thMap = [NSMapTable strongToWeakObjectsMapTable];

            for (NSString *key in _thMap.keyEnumerator) { // enumerate
                myLog(@"There are %@ %@'s in stock", [_thMap objectForKey:key], key);
            }
        }
    }
    return _sharedThManager;
}

// uniqueKeyからThオブジェクトを取得する。 板移転に対応
// nullの場合もあり
- (Th *)thForUniqueKey:(NSString *)threadUniqueKey
{
    @synchronized(_thMap)
    {
        Th *th = [_thMap objectForKey:threadUniqueKey];
        return th;
    }
}

- (void)deleteThDataAsync:(Th *)th
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      th.lastReadTime = 0;
      th.read = 0;
      NSString *infoFilePath = [th infoFilePath:NO];
      NSString *datPath = [th datFilePath:NO];

      NSFileManager *fm = [NSFileManager defaultManager];
      if (datPath && [fm fileExistsAtPath:datPath]) {
          NSError *error;

          BOOL result = [fm removeItemAtPath:datPath error:&error];
          if (result) {
              NSLog(@"ファイルを削除に成功：%@", datPath);
          } else {
              NSLog(@"ファイルの削除に失敗：%@", error.description);
          }
      }

      if (infoFilePath && [fm fileExistsAtPath:infoFilePath]) {
          NSError *error;

          BOOL result = [fm removeItemAtPath:infoFilePath error:&error];
          if (result) {
              NSLog(@"ファイルを削除に成功：%@", infoFilePath);
          } else {
              NSLog(@"ファイルの削除に失敗：%@", error.description);
          }
      }
    });
}

// スレッドの情報を非同期でローカルファイルへ保存する
- (void)saveThAsync:(Th *)th
{
    if (th == nil) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      @synchronized(th)
      {
          NSString *infoFilePath = [th infoFilePath];
          BOOL successful = [NSKeyedArchiver archiveRootObject:th toFile:infoFilePath];

          if (successful) {
              //myLog(@"%@", @"データの保存に成功しました。");
          } else {
              myLog(@"%@", @"データの保存に失敗しました。");
          }
      }
    });
}

- (Th *)registerTh:(Th *)th
{
    return [self registerTh:th canLoadFile:NO];
}

// スレッドの登録と取得
// canLoadFile: ファイルの読み込みを可能とする。
- (Th *)registerTh:(Th *)th canLoadFile:(BOOL)canLoadFile
{
    if (th == nil) return nil;
    NSString *uniqueKey = [th threadUniqueKey];
    if (uniqueKey == nil) return th;

    @synchronized(_thMap)
    {
        Th *existedTh = [_thMap objectForKey:uniqueKey];
        if (existedTh) {
            [self commonImportThreadInfo:existedTh source:th];
            return existedTh;
        }

        Th *newTh = nil;
        if (canLoadFile) {
            newTh = [self loadThFromInfoFile:th];
            if (newTh) {
                [self commonImportThreadInfo:newTh source:th];
            }
        }

        if (newTh == nil) {
            newTh = th;
        }

        newTh.board = [[BoardManager sharedManager] boardForTh:newTh];
        [_thMap setObject:newTh forKey:uniqueKey];

        return newTh;
    }
}

- (Th *)loadThFromInfoFile:(Th *)th
{
    if (th == nil) {
        return nil;
    }

    NSString *infoFilePath = [th infoFilePath:YES];
    @try {
        Th *tempTh = [NSKeyedUnarchiver unarchiveObjectWithFile:infoFilePath];
        return tempTh;
    } @catch (NSException *exception) {
       
    }
    
    return nil;

}

- (BOOL)isRegisteredTh:(Th *)th
{
    if (th == nil) return NO;
    NSString *uniqueKey = [th threadUniqueKey];
    if (uniqueKey == nil) return NO;

    @synchronized(_thMap)
    {
        Th *existedTh = [_thMap objectForKey:uniqueKey];
        return existedTh != nil;
    }
}

/*
 * スレ一覧を読み込んだ時、 同期した時、共通のスレッド情報取り込み
 */
- (void)commonImportThreadInfo:(Th *)target source:(Th *)source
{

    if ([target.host isEqualToString:source.host] == NO) {
        target.host = source.host;
    }

    if (target.tempHighlightResNumber == 0 && source.tempHighlightResNumber > 0) {
        target.tempHighlightResNumber = source.tempHighlightResNumber;
    }

    if (target.localCount < source.localCount) {
        target.localCount = source.localCount;
    }

    if (target.count < source.count) {
        target.count = source.count;
    }

    if (target.lastReadTime < source.lastReadTime) {
        target.lastReadTime = source.lastReadTime;
    }

    if (source.reading > 0) {
        target.reading = source.reading; // Sync
        if (target.reachedLastReading < source.reading || source.reading < target.reachedLastReading - 30) {
            target.reachedLastReading = 0; //一番下にスクロールした時のレス番保持してたのを0か
        }
    }

    if (target.board == nil && source.board) {
        target.board = source.board;
    }

    if (source.read > 0) {
        target.read = source.read;
    }

    if (source.title != nil && [source.title isEqualToString:@""] == NO) {
        if (target.title == nil || [target.title isEqualToString:source.title] == NO) {
            target.title = source.title;
        }
    }

    //  if (source.boardName && target.boardName == nil) {
    //    target.boardName = source.boardName;
    //  }
}

@end
