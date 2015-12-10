

#import <Foundation/Foundation.h>
#import "Board.h"
#import "Res.h"
#import "BBSItemBase.h"
@class NGItem;
@class ResNGInspector;

typedef enum {
    POST_RESULT_SUCCESS,
    POST_RESULT_FAIL,
    POST_RESULT_CONFIRM,
} PostResultType;

@class Th;

@protocol ThreadUpdatingChangedHandler
@optional
- (void)onUpdateStarting:(Th *)th;                                 //更新開始前
- (void)onUpdateStarted:(Th *)th;                                  //更新開始直後
- (void)onUpdateProgressChanged:(Th *)th progress:(float)progress; //読み込み更新
- (void)onUpdateEnd:(Th *)th;                                      //更新終了後
@required
@end

@interface Th : BBSItemBase

@property (nonatomic) BOOL isUpdating;
@property (nonatomic) BOOL shouldResAdded;
@property (nonatomic) BOOL isWaiting;
@property (nonatomic) BOOL showDate;
@property (nonatomic) BOOL showBoardName;

@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSUInteger number;
@property (nonatomic) BOOL isDown;
@property (nonatomic) NSMutableArray *responses;
@property (nonatomic) NSMutableDictionary *resListById;
@property (nonatomic) unsigned long long lastReadTime;
@property (nonatomic) NSInteger reachedLastReading;

@property (nonatomic, copy) NSString *lastPostText;
@property (nonatomic) NSMutableSet *myResNumSet;

@property (nonatomic) unsigned long long datSize;

@property (nonatomic) Board *board;

@property (nonatomic) unsigned long long key;
@property (nonatomic) NSUInteger localCount;
@property (nonatomic) NSUInteger count;
@property (nonatomic) NSUInteger reading;
@property (nonatomic) NSUInteger read;
@property (nonatomic) BOOL isFav;

@property (nonatomic) NSUInteger tempHighlightResNumber;

@property (nonatomic) float speed;
@property (nonatomic) ResNGInspector *resNGInspector;

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

- (NSComparisonResult)compareCreated:(Th *)th;

- (NSComparisonResult)comparelastReadTime:(Th *)th;
- (NSComparisonResult)compareSpeed:(Th *)th;
- (NSComparisonResult)compareCount:(Th *)th;
- (NSComparisonResult)compareNumber:(Th *)th;

- (id)init;
- (NSString *)description;
+ (Th *)thFromUrl:(NSString *)url;

// 板一覧からの情報で更新して板を返す
// スクロール中などの呼び出し回数が多くなるような場所では使わない。
//- (Board*)getBoardWithUpdate;

- (BOOL)isOver1000;

- (NSString *)datUrl;
- (NSInteger)unreadCount;

- (NSString *)threadUniqueKey;

- (NSString *)threadUrl;

- (float)calcSpeed;
- (void)calcSpeedIfNot;

- (NSString *)datFilePath:(BOOL)create;
- (NSString *)datFilePath; //create = YES 無いときは生成
- (NSString *)infoFilePath:(BOOL)create;
- (NSString *)infoFilePath; //create = YES 無いときは生成

- (BOOL)hasInfoFile; //infoファイルがあるかどうか

- (BOOL)canAppendDatFileWithInt:(NSInteger)responseCode;

- (Res *)resAtNumber:(NSInteger)number;
@end
