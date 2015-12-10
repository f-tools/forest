//
//  ThListTransaction.h
//  Forest
//

#import "Transaction.h"
#import "Board.h"
#import "ThListVC.h"


@interface ThListTransaction : Transaction

@property(nonatomic) Board* board;

//これが設定されていたときには、完了時、スレ一覧を
//このThListVCに渡す。
@property (nonatomic) ThListVC* thListVC;

@property (nonatomic) BOOL isNextSearch;
@property (nonatomic) Th* th;

@property (nonatomic) CGFloat downloadProgress;
@property (nonatomic) NSMutableData* receivedData;

@property (nonatomic) NSHTTPURLResponse* response;

- (BOOL) startOpenThListTransaction: (Board*)board;


@end
