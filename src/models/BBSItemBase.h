
#import <Foundation/Foundation.h>

typedef enum {
    BBS_2CH,
    BBS_SHITARABA,
    BBS_PINK,
    BBS_MACHI,
    BBS_EXTERNAL
} BBSType;

typedef enum {
    BBSST_2CH_COMP,  // 2ch互換 (test/read.cgi, SHIFT_JIS)
    BBSST_SHITARABA, // EUC-JP
    BBSST_MACHI      //SHIFT_JIS
} BBSSubType;

//
// 板とスレッド共通のクラス
//
@interface BBSItemBase : NSObject <NSCoding> {

    NSString *_host;
    NSString *_url;
    NSString *_boardKey;
    NSString *_serverDir;
    NSString *_lastModified;
}

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, copy) NSString *boardKey;
@property (nonatomic, copy) NSString *lastModified;
@property (nonatomic, copy) NSString *serverDir;

- (BOOL)is2ch;
- (BOOL)isPink;
- (BOOL)isShitaraba;
- (BOOL)isMachiBBS;
- (BBSSubType)getBBSSubType;
- (NSString *)getBoardFolderPath:(BOOL)create;

- (void)refreshBoardInfo;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

- (NSStringEncoding)boardEncoding;
+ (NSStringEncoding)boardEncodingWithBBSSubType:(BBSSubType)subType;
- (NSString *)boardUniqueKey;

- (NSString *)getPostUrl;

- (int)getPostResult:(NSString *)returnedBody;
- (NSString *)createPostData:(BOOL)newTh name:(NSString *)name mail:(NSString *)mail text:(NSString *)text subjectOrKey:(NSString *)subjectOrKey;
@end
