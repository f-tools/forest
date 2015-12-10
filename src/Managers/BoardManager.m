#import "BoardManager.h"
#import "Th.h"
#import "ThUpdater.h"
#import "BoardMenuParser.h"
#import "Env.h"
#import "Category.h"
#import "Board.h"

//
// 板の情報を格納します（板のキー => Boardオブジェクト）
// したらばの場合は "anime/1234"がキー
// 2chの場合は"apple"
static NSMapTable *_boardMap;
//NSMapTable strongToWeakObjectsMapTable
//
//全てのカテゴリを格納する - 表示のため
static NSMutableArray *_categories;

// 標準のカテゴリ一覧
static NSMutableArray *_standardCategories;
static NSString *_standardCategoriesPath;

// お気に入りの板の一覧
static ArkCategory *_favCategory;
static NSString *_favBoardsPath;

// ユーザーが定義した外部板の一覧
static ArkCategory *_externalCategory;
static NSString *_externalBoardsPath;

// 最近読み込んだ板一覧
static NSMutableArray *_recentBoards;
static NSString *_recentBoardsPath;

//
// 板の情報を管理する
//
@implementation BoardManager


+ (BoardManager *)sharedManager
{
    static id sharedManager = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedManager = [[[self class] alloc] init];

      NSString *docPath = [Env documentPath];
      _standardCategoriesPath = [docPath stringByAppendingPathComponent:@"categories"];
      _favBoardsPath = [docPath stringByAppendingPathComponent:@"favBoards"];
      _recentBoardsPath = [docPath stringByAppendingPathComponent:@"recentBoards"];
      _externalBoardsPath = [docPath stringByAppendingPathComponent:@"externalBoards"];

      [sharedManager loadBoards];
        
    });

    return sharedManager;
}

- (void)addBoardLoadedHandler:(id<BoardMovedHandler>)handler
{
    [_onNotifyBoardMovedHandlers addObject:handler];
}

// スレッドに対応した板を取得する。
// 板移転に対応するため
- (Board *)boardForTh:(Th *)th
{
    Board *board = [Board alloc];
    board.boardKey = th.boardKey;
    board.host = th.host;
    board.serverDir = th.serverDir;

    return [self registerBoard:board];
}

- (BOOL)updateBoardInfoForTh:(Th *)th
{
    NSString *uniqueKey = [th boardUniqueKey];
    Board *existBoard = [_boardMap objectForKey:uniqueKey];

    if (existBoard) {

        th.boardKey = existBoard.boardKey;
        th.host = existBoard.host;
        th.serverDir = existBoard.serverDir;

        return YES;
    }
    return NO;
}

- (Board *)boardForUniqueKey:(NSString *)boardUniqueKey
{
    @synchronized(self)
    {
        Board *v = [_boardMap objectForKey:boardUniqueKey];
        return v;
    }
}

- (id)init
{
    if (self = [super init]) {
        _boardMap = [NSMapTable strongToWeakObjectsMapTable];

        _onNotifyBoardMovedHandlers = [NSMutableArray array];

        //
        // カテゴリ一覧
        _categories = [NSMutableArray array];

        //
        // 全てのカテゴリ一覧
        _standardCategories = [NSMutableArray array];

        //
        // ユーザーが定義した外部板の一覧
        _favCategory = [[ArkCategory alloc] init];
        _favCategory.name = @"お気に入り";

        //
        // ユーザーが定義した外部板の一覧
        _externalCategory = [[ArkCategory alloc] init];
        _externalCategory.name = @"外部板";

        //
        // 最近読み込んだ板一覧
        _recentBoards = [NSMutableArray array];
    }
    return self;
}

- (NSMutableArray *)categories
{
    return _categories;
}

- (ArkCategory *)favoriteCategory
{
    return _favCategory;
}

- (ArkCategory *)externalCategory
{
    return _externalCategory;
}

- (void)rebuildCategories
{
    [_categories removeAllObjects];
    [_categories addObject:_favCategory];
    [_categories addObject:_externalCategory];
    [_categories addObjectsFromArray:_standardCategories];
}

/*
 * 板一覧の更新により受け取ったカテゴリ一覧から内部情報を更新します。
 */
- (void)updateBoardsWithUpdate:(NSMutableArray *)categories
{
    if (categories == nil) return;

    for (ArkCategory *cate in categories) {
        NSMutableArray *newBoards = [NSMutableArray array];
        for (Board *board in cate.boards) {

            Board *b = [self registerBoard:board canChangeHost:YES];
            [newBoards addObject:b];
        }
        cate.boards = newBoards;
    }

    _standardCategories = categories;
    [self rebuildCategories];

    [self saveBoardsAsync];
}

- (void)fetchBBSMenuAsync
{
    NSString *bbsMenu = @"http://menu.2ch.net/bbsmenu.html";
    NSURL *nsurl = [NSURL URLWithString:bbsMenu];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;

    // ヘッダー情報を追加する。
    [request addValue:[Env userAgent] forHTTPHeaderField:@"User-Agent"];
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];

    NSString *errorStr = [error localizedDescription];
    if (0 < [errorStr length]) {
        return;
    }

    NSString *dataString = nil;
    dataString = [[NSString alloc] initWithData:data encoding:NSShiftJISStringEncoding];
    if (dataString != nil) {
        BoardMenuParser *parser = [BoardMenuParser alloc];

        NSArray *categories = [parser parse:dataString];

        [self updateBoardsWithUpdate:categories];
    }
}

- (void)saveBoardsAsync
{
    BOOL successful = [NSKeyedArchiver archiveRootObject:_standardCategories toFile:_standardCategoriesPath];
    if (successful) {
        myLog(@"%@", @"Boardデータの保存に成功しました。");
    }
}

- (void)saveFavBoardsAsync
{
    BOOL successful = [NSKeyedArchiver archiveRootObject:_favCategory.boards toFile:_favBoardsPath];
    if (successful) {
        myLog(@"%@", @"Boardデータの保存に成功しました。");
    }
}

- (void)saveRecentBoardsAsync
{
    BOOL successful = [NSKeyedArchiver archiveRootObject:_recentBoards toFile:_recentBoardsPath];
    if (successful) {
        //myLog(@"%@", @"データの保存に成功しました。");
    }
}

- (void)saveExternalBoardsAsync
{
    BOOL successful = [NSKeyedArchiver archiveRootObject:_externalCategory.boards toFile:_externalBoardsPath];
    if (successful) {
        //myLog(@"%@", @"データの保存に成功しました。");
    }
}

/*
- (void)addExternalBoard:(Board *)board
{
    [_externalCategory.boards addObject:board];
    [self saveExternalBoardsAsync];
}
*/

- (BOOL)containsExternalBoard:(Board *)board
{
    return [_externalCategory.boards containsObject:board];
}

- (void)removeExternalBoard:(Board *)board
{
    [_externalCategory.boards removeObject:board];
    [self saveExternalBoardsAsync];
}

- (void) addExternalBoard:(Board*) board {
    Board* b =[self registerBoard:board];

    if (b) {
        @synchronized(_externalCategory) {
            [_externalCategory.boards addObject:b];
        }
    }
}

- (void)addFavBoard:(Board *)board
{
    if (![_favCategory.boards containsObject:board]) {
        [_favCategory.boards addObject:board];
    } else {
        [_favCategory.boards removeObject:board];
    }
    [self saveFavBoardsAsync];
}
- (void)removeFavBoard:(Board *)board
{
    [_favCategory.boards removeObject:board];
    [self saveFavBoardsAsync];
}

- (void)loadBoards
{
    @try {
        NSArray *categoryArray = [NSKeyedUnarchiver unarchiveObjectWithFile:_standardCategoriesPath];
        if (categoryArray) {
            [_standardCategories removeAllObjects];
            for (ArkCategory *category in categoryArray) {
                NSMutableArray *boards = [NSMutableArray array];
                for (Board *board in category.boards) {
                    Board *b = [self registerBoard:board];
                    if (b) {
                        @synchronized(category)
                        {
                            [boards addObject:b];
                        }
                    }
                }
                category.boards = boards;
                @synchronized(_standardCategories)
                {
                    [_standardCategories addObject:category];
                }
            }
        }

    }
    @catch (NSException *exception) {
        
    }
    @finally {
     
    }
    
    @try {
        NSArray *favBoards = [NSKeyedUnarchiver unarchiveObjectWithFile:_favBoardsPath];
        if (favBoards) {
            [_favCategory.boards removeAllObjects];
            for (Board *board in favBoards) {
                Board *b = [self registerBoard:board];
                if (b) {
                    @synchronized(_favCategory)
                    {
                        [_favCategory.boards addObject:b];
                    }
                }
            }
        }
        [self loadExternalBoards];

    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
    
    [self rebuildCategories];
}

- (void)loadRecentBoards
{
    NSArray *boardArray = [NSKeyedUnarchiver unarchiveObjectWithFile:_recentBoardsPath];
    if (boardArray) {
        [_recentBoards removeAllObjects];
        for (Board *board in boardArray) {
            Board *b = [self registerBoard:board];
            if (b) {
                @synchronized(_recentBoards)
                {
                    [_recentBoards addObject:b];
                }
            }
        }
    }
}

- (void)loadExternalBoards
{
    @try {
        NSArray *boardArray = [NSKeyedUnarchiver unarchiveObjectWithFile:_externalBoardsPath];
        if (boardArray) {
            [_externalCategory.boards removeAllObjects];
            for (Board *board in boardArray) {
                Board *b = [self registerBoard:board];
                if (b) {
                    @synchronized(_externalCategory)
                    {
                        [_externalCategory.boards addObject:b];
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"外部板データ解析失敗");
    }

}

- (void)addRecentBoard:(Board *)board
{
    Board *b = [self registerBoard:board];
    if (b) {
        @synchronized(_recentBoards)
        {
            [_recentBoards addObject:b];
        }
    }
}

- (Board *)registerBoard:(Board *)board
{
    return [self registerBoard:board canChangeHost:NO];
}

- (Board *)registerBoard:(Board *)board canChangeHost:(BOOL)canChangeHost
{
    if (board == nil) return nil;
    NSString *uniqueKey = [board boardUniqueKey];
    if (uniqueKey == nil) return board;

    @synchronized(self)
    {
        Board *val = [_boardMap objectForKey:uniqueKey];
        if (val) {
            [self commonImportThreadInfo:val source:board canChangeHost:canChangeHost];
            return val;
        }

        [_boardMap setObject:board forKey:uniqueKey];
        return board;
    }
}

- (void)commonImportThreadInfo:(Board *)target source:(Board *)source canChangeHost:(BOOL)canChangeHost
{
    if (source.boardName) {
        target.boardName = source.boardName;
    }

    if (canChangeHost) {
        if (source.host) {
            target.host = source.host;
        }
        if (source.serverDir) {
            target.serverDir = source.serverDir;
        }
    }

    //    if (target.point < source.point) {
    //        target.point = source.point;
    //    }
}
@end
