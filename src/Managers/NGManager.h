#import <Foundation/Foundation.h>
#import "Board.h"
#import "Th.h"
#import "Res.h"

#import "Category.h"

@interface NGItem : NSObject <NSCoding>

@property (nonatomic) NSInteger created;
@property (nonatomic) NSInteger lastUsed;
@property (nonatomic) NSInteger type;

@property (nonatomic) BOOL transparent;
@property (nonatomic) BOOL chain;
@property (nonatomic) BOOL regex;
@property (nonatomic) NSString *value;
@property (nonatomic) NSString *boardKey;
@property (nonatomic) Board *board;

+ (NGItem *)ngIdItem;
+ (NGItem *)ngWordItem;
+ (NGItem *)ngThreadItem;
+ (NGItem *)ngNameItem;

- (NSString *)typeString;

@end

@class NGItemsContainer;

@interface ResNGInspector : NSObject

@property (nonatomic) NSMutableArray *ngIdItems;
@property (nonatomic) NSMutableArray *ngWordItems;
@property (nonatomic) NSMutableArray *ngNameItems;

- (NGItem *)inspectRes:(Res *)res;
- (NGItem *)inspectID:(Res *)res;
- (NGItem *)inspectWord:(Res *)res;
- (NGItem *)inspectName:(Res *)res;
@end

@interface ThreadNGInspector : NSObject

@property (nonatomic) NSMutableArray *ngThreadItems;

- (NGItem *)inspectThread:(Th *)th;

@end




@interface NGManager : NSObject


+ (NGManager *)sharedManager;

- (id)init;

- (ResNGInspector *)createResNGInspectorForTh:(Th *)th;
- (ThreadNGInspector *)createThreadNGInspectorForBoard:(Board *)board;

- (void)addNGItem:(NGItem *)ngItem;
- (void)removeNGItem:(NGItem *)ngItem;
- (void)changeNGItemBoard:(NGItem *)ngItem board:(Board *)board;
- (void)changeNGItemInfo:(NGItem *)ngItem;

- (NSArray *)idNGList;
- (NSArray *)wordNGList;
- (NSArray *)nameNGList;
- (NSArray *)threadNGList;

@end
