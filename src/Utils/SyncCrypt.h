#import <Foundation/Foundation.h>

@interface SyncCrypt : NSObject 


@property (nonatomic, copy) NSData *keyBytes;
@property (nonatomic, copy) NSData *zeroIv;
@property (nonatomic) int cryptLevel;

- (void)setKey:(NSString *)key withCryptLevel:(int)level;

//URL
- (NSString *)encUrl:(NSString *)url;
- (NSString *)decUrl:(NSString *)text;

//タイトル
- (NSString *)encTitle:(NSString *)title url:(NSString *)url;
- (NSString *)decTitle:(NSString *)text url:(NSString *)url;

//フォルダー名
- (NSString *)encFolder:(NSString *)folderName;
- (NSString *)decFolder:(NSString *)text;

//既読番号
- (NSString *)encRead:(NSInteger)readNum url:(NSString *)url;
- (NSString *)decRead:(NSString *)text url:(NSString *)url;

//現在位置
- (NSString *)encNow:(NSInteger)readNum url:(NSString *)url;
- (NSString *)decNow:(NSString *)text url:(NSString *)url;

//レスカウント
- (NSString *)encCount:(NSInteger)readNum url:(NSString *)url;
- (NSString *)decCount:(NSString *)text url:(NSString *)url;

//書き込み番号配列
- (NSString *)encPosts:(NSArray *)posts url:(NSString *)url;
- (NSArray *)decPosts:(NSString *)postsStr url:(NSString *)url;
@end
