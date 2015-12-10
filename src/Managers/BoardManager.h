
#import <Foundation/Foundation.h>
#import "Board.h"
#import "Th.h"
#import "DatParser.h"
#import "Category.h"

@protocol BoardMovedHandler
@optional
//板移転
- (void)didBoardMoved:(Board *)board
           beforeHost:(NSString *)beforeHost
            afterHost:(NSString *)afterHost;

- (void)didBoardNameChanged:(Board *)board prevName:(NSString *)prevName; //板名の更新
@required
- (void)didBoardsChanged; //板一覧が少しでも変化したら再描画を促すために通知する。

@end

@class ArkCategory;

@interface BoardManager : BaseScanner

//板移転検出後の通知用イベントハンドラ
@property (nonatomic) NSMutableArray *onNotifyBoardMovedHandlers;

+ (BoardManager *)sharedManager;

- (id)init;

- (Board *)registerBoard:(Board *)board;

- (void)addBoardLoadedHandler:(id<BoardMovedHandler>)handler;

- (Board *)boardForTh:(Th *)th;
- (BOOL)updateBoardInfoForTh:(Th *)th;
- (Board *)boardForUniqueKey:(NSString *)boardUniqueKey;

// 板メニューを取得し、static変数に格納し、ファイルに保存する。
- (void)fetchBBSMenuAsync;

// 板一覧の更新により受け取ったカテゴリ一覧から内部情報を更新します。
- (void)updateBoardsWithUpdate:(NSArray *)categories;

- (NSMutableArray *)categories;
- (ArkCategory *)favoriteCategory;
- (ArkCategory *)externalCategory;

// 非同期保存
- (void)saveBoardsAsync;
- (void)saveRecentBoardsAsync;
- (void)saveExternalBoardsAsync;

- (void)loadBoards;
- (void)loadRecentBoards;
- (void)loadExternalBoards;

- (void)addFavBoard:(Board *)board;
- (void)removeFavBoard:(Board *)board;

- (void)addExternalBoard:(Board *)board;
- (void)removeExternalBoard:(Board *)board;
- (BOOL)containsExternalBoard:(Board *)board;

@end
