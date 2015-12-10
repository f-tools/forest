#import <Foundation/Foundation.h>
#import <AssetsLibrary/ALAsset.h>
#import "Board.h"
#import "BoardManager.h"
#import "Th.h"
#import "Category.h"
#import "ResVm.h"

@interface ImageUploadEntry : NSObject 

@property (nonatomic, copy) NSString *imageKey;      //iqFwf8.jpg
@property (nonatomic, copy) NSString *webUrl;        //アップロードした画像のURL
@property (nonatomic, copy) NSString *deleteUrl;     //画像の消去URL
@property (nonatomic, copy) NSString *sdWebImageUrl; //SDWebImageのキャッシュ内識別URL

@property (nonatomic) NSInteger uploadedTime; //ローカルの画像パス
@property (nonatomic) BOOL isUploading;       // アップロード中
@property (nonatomic) BOOL isDeleted;         //　削除済み
@property (nonatomic) BOOL isWaiting;         //アップロード待機
@property (nonatomic) ALAsset *asset;
@property (nonatomic) NSInteger rowId;
@property (nonatomic) NSInteger tag;
@property (nonatomic, copy) NSString *deleteResultMessage;

@property (copy, nonatomic) void (^completion)(ImageUploadEntry *entry);

@end


@interface ImageUploadManager : NSObject {
}

+ (ImageUploadManager *)sharedManager;
- (void)addRequests:(NSArray *)assets;
- (void)deleteImage:(ImageUploadEntry *)entry completion:(void (^)(BOOL))completionBlock;

- (NSMutableArray *)historyEntries;

@end
