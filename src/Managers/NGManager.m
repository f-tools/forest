#import "CookieManager.h"
#import "Th.h"
#import "ThUpdater.h"
#import "BoardMenuParser.h"
#import "Env.h"
#import "Category.h"
#import "Board.h"
#import "BoardManager.h"
#import "NGManager.h"

static NGManager *_sharedNGManager = nil;

static NSString *_ngIDFilePath;
static NSString *_ngWordFilePath;
static NSString *_ngNameFilePath;
static NSString *_ngThreadFilePath;

static const NSInteger kNGID = 0;
static const NSInteger kNGWord = 1;
static const NSInteger kNGThread = 2;
static const NSInteger kNGName = 3;


@implementation NGItem

- (id)init
{
    if (self = [super init]) {
        _created = (NSInteger)[[NSDate date] timeIntervalSince1970];
        _transparent = NO;
        _regex = NO;
        _value = @"";
        _board = nil;
        _chain = NO;
    }

    return self;
}

- (NSString *)typeString
{
    if (self.type == kNGID) {
        return @"NG ID";
    } else if (self.type == kNGWord) {
        return @"NG Word";
    } else if (self.type == kNGThread) {
        return @"NG Thread";
    } else if (self.type == kNGName) {
        return @"NG Name";
    }
    return @"NG?";
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {

        NSNumber *createdNumber = [decoder decodeObjectForKey:@"created"];
        if (createdNumber) _created = [createdNumber integerValue];

        NSNumber *lastUsedNumber = [decoder decodeObjectForKey:@"lastUsed"];
        if (lastUsedNumber) _lastUsed = [lastUsedNumber integerValue];

        NSNumber *typeNumber = [decoder decodeObjectForKey:@"type"];
        if (typeNumber) _type = [typeNumber integerValue];

        NSNumber *transparentNumber = [decoder decodeObjectForKey:@"transparent"];
        if (transparentNumber) self.transparent = [transparentNumber boolValue];

        NSNumber *chainNumber = [decoder decodeObjectForKey:@"chain"];
        if (chainNumber) self.chain = [chainNumber boolValue];

        NSNumber *regexNumber = [decoder decodeObjectForKey:@"regex"];
        if (regexNumber) self.regex = [regexNumber boolValue];

        _value = [decoder decodeObjectForKey:@"value"];
        //_board = [decoder decodeObjectForKey:@"boardKey"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithInteger:self.created] forKey:@"created"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.lastUsed] forKey:@"lastUsed"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.type] forKey:@"type"];
    [encoder encodeObject:self.value forKey:@"value"];
    //[encoder encodeObject:self.boardKey forKey:@"boardKey"];
    [encoder encodeObject:[NSNumber numberWithBool:self.transparent] forKey:@"transparent"];
    [encoder encodeObject:[NSNumber numberWithBool:self.chain] forKey:@"chain"];
    [encoder encodeObject:[NSNumber numberWithBool:self.regex] forKey:@"regex"];
}

+ (NGItem *)ngIdItem
{
    NGItem *ngItem = [[NGItem alloc] init];
    ngItem.type = kNGID;
    ngItem.lastUsed = ngItem.created = (NSInteger)[[NSDate date] timeIntervalSince1970];
    return ngItem;
}

+ (NGItem *)ngWordItem
{
    NGItem *ngItem = [[NGItem alloc] init];
    ngItem.type = kNGWord;
    ngItem.lastUsed = ngItem.created = (NSInteger)[[NSDate date] timeIntervalSince1970];
    return ngItem;
}

+ (NGItem *)ngNameItem
{
    NGItem *ngItem = [[NGItem alloc] init];
    ngItem.type = kNGName;
    ngItem.lastUsed = ngItem.created = (NSInteger)[[NSDate date] timeIntervalSince1970];
    return ngItem;
}

+ (NGItem *)ngThreadItem
{
    NGItem *ngItem = [[NGItem alloc] init];
    ngItem.type = kNGThread;
    ngItem.lastUsed = ngItem.created = (NSInteger)[[NSDate date] timeIntervalSince1970];
    return ngItem;
}
@end

@interface NGItemsContainer : NSObject <NSCoding> {
}

@property (nonatomic) NSMutableDictionary *boardNGDictionary;          //board unique key => [NGItemsContainer]
@property (nonatomic) NSMutableDictionary *uniqueKeyToBoardDictionary; //board unique key => Board

- (void)addNGItem:(NGItem *)ngItem;
- (void)changeNGItemBoard:(NGItem *)ngItem board:(Board *)board;
- (void)removeNGItem:ngItem;

- (NSMutableArray *)ngItemsForBoard:(Board *)board;
- (NSArray *)allNGItems;
@end

@implementation NGItemsContainer

- (id)init
{
    if (self = [super init]) {
        _boardNGDictionary = [NSMutableDictionary dictionary];
        _uniqueKeyToBoardDictionary = [NSMutableDictionary dictionary];

        [_boardNGDictionary setObject:[NSMutableArray array] forKey:@"all"];
    }
    return self;
}

//セーブするときはBoardのそのままURL
- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _boardNGDictionary = [NSMutableDictionary dictionary]; // [decoder decodeObjectForKey:@"boardNGDictionary"];

        NSMutableDictionary *saveBoardDictionary = [decoder decodeObjectForKey:@"boardNGDictionary"];
        for (NSString *boardUrl in saveBoardDictionary) {

            NSArray *ngItems = [saveBoardDictionary objectForKey:boardUrl];
            NSMutableArray *newNGItems = [NSMutableArray array];
            for (NGItem *ngItem in ngItems) {
                NSInteger now = (NSInteger)[[NSDate date] timeIntervalSince1970];
                if (ngItem.regex == YES || ngItem.type != 0 || now - ngItem.lastUsed < 60 * 60 * 24 * 5) { //type:0=ID
                    [newNGItems addObject:ngItem];
                }
            }

            if ([boardUrl isEqualToString:@"all"]) {
                [_boardNGDictionary setObject:newNGItems forKey:@"all"];
            } else {
                Board *board = [[BoardManager sharedManager] registerBoard:[Board boardFromUrl:boardUrl]];
                [_boardNGDictionary setObject:newNGItems forKey:[board boardUniqueKey]];
                [_uniqueKeyToBoardDictionary setObject:board forKey:[board boardUniqueKey]];
                for (NGItem *ngItem in ngItems) {
                    ngItem.board = board;
                }
            }
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{

    NSLog(@"encodeWithCoder");
    NSMutableDictionary *saveBoardDictionary = [NSMutableDictionary dictionary];
    for (NSString *boardKey in [self.boardNGDictionary allKeys]) {

        NSMutableArray *ngItems = [self.boardNGDictionary objectForKey:boardKey];

        if ([boardKey isEqualToString:@"all"]) {

            [saveBoardDictionary setObject:ngItems forKey:@"all"];

        } else {
            Board *board = [[BoardManager sharedManager] boardForUniqueKey:boardKey];
            [saveBoardDictionary setObject:ngItems forKey:[board boardUrl]];
        }
    }

    [encoder encodeObject:saveBoardDictionary forKey:@"boardNGDictionary"];
    //[encoder encodeObject:self.ngItemsContainerForAll forKey:@"ngItemsContainerForAll"];
}

- (NSMutableArray *)ngItemsForBoard:(Board *)board
{
    NSString *key = board == nil ? @"all" : [board boardUniqueKey];

    @synchronized(self.boardNGDictionary)
    {
        NSMutableArray *ngItemArray = [self.boardNGDictionary objectForKey:key];
        if (ngItemArray) {
            return ngItemArray;
        }
    }
    return nil;
}

- (NSArray *)allNGItems
{
    NSMutableArray *allItems = [NSMutableArray array];
    for (NSString *boardKey in [self.boardNGDictionary allKeys]) {
        NSMutableArray *ngItems = [self.boardNGDictionary objectForKey:boardKey];
        [allItems addObjectsFromArray:ngItems];
    }
    return allItems;
}

- (void)addNGItem:(NGItem *)ngItem
{
    NSString *boardUniqueKey = @"all";
    if (ngItem.board) {
        boardUniqueKey = [ngItem.board boardUniqueKey];
    }

    @synchronized(self.boardNGDictionary)
    {
        NSMutableArray *ngItemArray = [self.boardNGDictionary objectForKey:boardUniqueKey];
        if (ngItemArray) {
            if ([ngItemArray containsObject:ngItem]) {
                return;
            }
        } else {
            ngItemArray = [[NSMutableArray alloc] init];
            [self.boardNGDictionary setObject:ngItemArray forKey:boardUniqueKey];

            if (ngItem.board) {
                [self.uniqueKeyToBoardDictionary setObject:ngItem.board forKey:boardUniqueKey];
            }
        }

        [ngItemArray addObject:ngItem];
    }
}

- (void)changeNGItemBoard:(NGItem *)ngItem board:(Board *)board
{
    [self removeNGItem:ngItem];
    ngItem.board = board;
    [self addNGItem:ngItem];
}

- (void)removeNGItem:(NGItem *)ngItem
{
    NSString *boardUniqueKey = @"all";
    if (ngItem.board) {
        boardUniqueKey = [ngItem.board boardUniqueKey];
    }

    @synchronized(self.boardNGDictionary)
    {
        //バグ回避
        for (NSString *boardKey in [self.boardNGDictionary allKeys]) {
            NSMutableArray *ngItems = [self.boardNGDictionary objectForKey:boardKey];
            if (ngItems) {
                [ngItems removeObject:ngItem];
            }
        }
    }
}

@end

/**
 *
 * NGManager
 *
 * NGの情報を管理する
 *
 */
@interface NGManager ()

@property (nonatomic) NGItemsContainer *ngIdItemsContainer;
@property (nonatomic) NGItemsContainer *ngWordItemsContainer;
@property (nonatomic) NGItemsContainer *ngThreadItemsContainer;
@property (nonatomic) NGItemsContainer *ngNameItemsContainer;

@end

@implementation NGManager

+ (NGManager *)sharedManager
{
    @synchronized(self)
    {
        if (!_sharedNGManager) {
            NSString *docPath = [Env documentPath];
            _ngIDFilePath = [docPath stringByAppendingPathComponent:@"NGIDData"];
            _ngWordFilePath = [docPath stringByAppendingPathComponent:@"NGWordData"];
            _ngNameFilePath = [docPath stringByAppendingPathComponent:@"NGNameData"];
            _ngThreadFilePath = [docPath stringByAppendingPathComponent:@"NGThreadData"];

            _sharedNGManager = [[self alloc] init];
        }
    }
    return _sharedNGManager;
}

//一覧取得
- (NSArray *)idNGList
{
    return [self.ngIdItemsContainer allNGItems];
}

- (NSArray *)wordNGList
{
    return [self.ngWordItemsContainer allNGItems];
}

- (NSArray *)threadNGList
{
    return [self.ngThreadItemsContainer allNGItems];
}
- (NSArray *)nameNGList
{
    return [self.ngNameItemsContainer allNGItems];
}

- (id)init
{
    if (self = [super init]) {
    
        @try {
            _ngIdItemsContainer = [NSKeyedUnarchiver unarchiveObjectWithFile:_ngIDFilePath];
        } @catch (NSException *exception) {
            NSLog(@"Unarchive ngIDFile failed.");
        }
        
        @try {
            _ngWordItemsContainer = [NSKeyedUnarchiver unarchiveObjectWithFile:_ngWordFilePath];
        } @catch (NSException *exception) {
            NSLog(@"Unarchive ngWord file failed.");
        }

        @try {
            _ngNameItemsContainer = [NSKeyedUnarchiver unarchiveObjectWithFile:_ngNameFilePath];
        } @catch (NSException *exception) {
            NSLog(@"Unarchive ngWord file failed.");
        }

        @try {
            _ngThreadItemsContainer = [NSKeyedUnarchiver unarchiveObjectWithFile:_ngThreadFilePath];
        } @catch (NSException *exception) {
            NSLog(@"Unarchive ngThread file failed.");
        }


        if (_ngIdItemsContainer == nil) {
            _ngIdItemsContainer = [[NGItemsContainer alloc] init];
        }
        if (_ngWordItemsContainer == nil) {
            _ngWordItemsContainer = [[NGItemsContainer alloc] init];
        }
        if (_ngNameItemsContainer == nil) {
            _ngNameItemsContainer = [[NGItemsContainer alloc] init];
        }
        if (_ngThreadItemsContainer == nil) {
            _ngThreadItemsContainer = [[NGItemsContainer alloc] init];
        }
    }
    return self;
}

- (void)addNGItem:(NGItem *)ngItem
{
    if (ngItem.type == kNGID) { //0:ID
        [self.ngIdItemsContainer addNGItem:ngItem];
        [self saveIDItemsAsync];
    } else if (ngItem.type == kNGWord) { // 1: word
        [self.ngWordItemsContainer addNGItem:ngItem];
        [self saveWordItemsAsync];
    } else if (ngItem.type == kNGThread) { //2: thread
        [self.ngThreadItemsContainer addNGItem:ngItem];
        [self saveThreadItemsAsync];
    } else if (ngItem.type == kNGName) {
        [self.ngNameItemsContainer addNGItem:ngItem];
        [self saveNameItemsAsync];
    }
}

- (void)changeNGItemInfo:(NGItem *)ngItem
{
    if (ngItem.type == kNGID) { //0:ID
        [self saveIDItemsAsync];
    } else if (ngItem.type == kNGWord) { // 1: word
        [self saveWordItemsAsync];
    } else if (ngItem.type == kNGThread) {
        [self saveThreadItemsAsync];
    } else if (ngItem.type == kNGName) {
        [self saveNameItemsAsync];
    }
}

- (void)changeNGItemBoard:(NGItem *)ngItem board:(Board *)board
{
    if (ngItem.type == kNGID) { //0:ID
        [self.ngIdItemsContainer changeNGItemBoard:ngItem board:board];
        [self saveIDItemsAsync];
    } else if (ngItem.type == kNGWord) { // 1: word
        [self.ngWordItemsContainer changeNGItemBoard:ngItem board:board];
        [self saveWordItemsAsync];
    } else if (ngItem.type == kNGThread) { // 2: thread
        [self.ngThreadItemsContainer changeNGItemBoard:ngItem board:board];
        [self saveThreadItemsAsync];
    } else if (ngItem.type == kNGName) { // 3: name
        [self.ngNameItemsContainer changeNGItemBoard:ngItem board:board];
        [self saveNameItemsAsync];
    }
}

- (void)removeNGItem:(NGItem *)ngItem
{
    if (ngItem.type == kNGID) {
        [self.ngIdItemsContainer removeNGItem:ngItem];
        [self saveIDItemsAsync];
    } else if (ngItem.type == kNGWord) {
        [self.ngWordItemsContainer removeNGItem:ngItem];
        [self saveWordItemsAsync];
    } else if (ngItem.type == kNGThread) {
        [self.ngThreadItemsContainer removeNGItem:ngItem];
        [self saveThreadItemsAsync];
    } else if (ngItem.type == kNGName) {
        [self.ngNameItemsContainer removeNGItem:ngItem];
        [self saveNameItemsAsync];
    }
}

- (void)saveIDItemsAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

      // NSString* infoFilePath = [th infoFilePath:YES];
      BOOL successful = [NSKeyedArchiver archiveRootObject:self.ngIdItemsContainer toFile:_ngIDFilePath];

      if (successful) {
          myLog(@"%@", @"ngIdItemsContainerの保存に成功しました。");
      }

    });
}

- (void)saveWordItemsAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

      // NSString* infoFilePath = [th infoFilePath:YES];
      BOOL successful = [NSKeyedArchiver archiveRootObject:self.ngWordItemsContainer toFile:_ngWordFilePath];

      if (successful) {
          myLog(@"%@", @"ngWordItemsContainerの保存に成功しました。");
      }

    });
}

- (void)saveNameItemsAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

      // NSString* infoFilePath = [th infoFilePath:YES];
      BOOL successful = [NSKeyedArchiver archiveRootObject:self.ngNameItemsContainer toFile:_ngNameFilePath];
      if (successful) {
          myLog(@"%@", @"ngNameItemsContainerの保存に成功しました。");
      }

    });
}

- (void)saveThreadItemsAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

      // NSString* infoFilePath = [th infoFilePath:YES];
      BOOL successful = [NSKeyedArchiver archiveRootObject:self.ngThreadItemsContainer toFile:_ngThreadFilePath];

      if (successful) {
          myLog(@"%@", @"ngWordItemsContainerの保存に成功しました。");
      }

    });
}

//- (ThreadNGInspector*) createThreadNGInspectorForBoard:(Board*)board;
- (ThreadNGInspector *)createThreadNGInspectorForBoard:(Board *)board
{
    ThreadNGInspector *inspector = [[ThreadNGInspector alloc] init];

    // ------------------------------  ID  ----------------------------------//
    //板別
    NSMutableArray *ngItems = [self.ngThreadItemsContainer ngItemsForBoard:board];
    if (ngItems) {
        for (NGItem *ngItem in ngItems) {
            [inspector.ngThreadItems addObject:ngItem];
        }
    }

    //全体
    ngItems = [self.ngThreadItemsContainer ngItemsForBoard:nil];
    ;
    if (ngItems) {
        for (NGItem *ngItem in ngItems) {
            [inspector.ngThreadItems addObject:ngItem];
        }
    }

    return inspector;
}
- (ResNGInspector *)createResNGInspectorForTh:(Th *)th
{
    ResNGInspector *inspector = [[ResNGInspector alloc] init];

    // ------------------------------  ID  ----------------------------------//
    //板別
    NSMutableArray *ngItems = [self.ngIdItemsContainer ngItemsForBoard:th.board];
    if (ngItems) {
        for (NGItem *ngItem in ngItems) {
            [inspector.ngIdItems addObject:ngItem];
        }
    }

    //全体
    ngItems = [self.ngIdItemsContainer ngItemsForBoard:nil];
    ;
    if (ngItems) {
        for (NGItem *ngItem in ngItems) {
            [inspector.ngIdItems addObject:ngItem];
        }
    }

    // ------------------------------  Word  ----------------------------------//
    //板別
    ngItems = [self.ngWordItemsContainer ngItemsForBoard:th.board];
    if (ngItems) {
        for (NGItem *ngItem in ngItems) {
            [inspector.ngWordItems addObject:ngItem];
        }
    }

    //全体
    ngItems = [self.ngWordItemsContainer ngItemsForBoard:nil];
    ;
    if (ngItems) {
        for (NGItem *ngItem in ngItems) {
            [inspector.ngWordItems addObject:ngItem];
        }
    }

    // ------------------------------  Name  ----------------------------------//
    //板別
    ngItems = [self.ngNameItemsContainer ngItemsForBoard:th.board];
    if (ngItems) {
        for (NGItem *ngItem in ngItems) {
            [inspector.ngNameItems addObject:ngItem];
        }
    }

    //全体
    ngItems = [self.ngNameItemsContainer ngItemsForBoard:nil];
    ;
    if (ngItems) {
        for (NGItem *ngItem in ngItems) {
            [inspector.ngNameItems addObject:ngItem];
        }
    }

    return inspector;
}

@end

@implementation ThreadNGInspector

- (id)init
{
    if (self = [super init]) {
        self.ngThreadItems = [NSMutableArray array];
    }
    return self;
}

- (NGItem *)inspectThread:(Th *)th
{
    for (NGItem *ngItem in self.ngThreadItems) {
        if (ngItem && [self inspectText:th.title ngItem:ngItem]) {
            return ngItem;
        }
    }

    return nil;
}

- (BOOL)inspectText:(NSString *)text ngItem:(NGItem *)ngItem
{
    NSRange range;
    if (ngItem.regex) {
        range = [text rangeOfString:ngItem.value options:NSRegularExpressionSearch];
    } else {
        range = [text rangeOfString:ngItem.value];
    }

    if (range.location != NSNotFound) {
        ngItem.lastUsed = (NSInteger)[[NSDate date] timeIntervalSince1970];
        return YES;
    }

    return NO;
}

@end

@implementation ResNGInspector

- (id)init
{
    if (self = [super init]) {
        self.ngIdItems = [NSMutableArray array];
        self.ngWordItems = [NSMutableArray array];
        self.ngNameItems = [NSMutableArray array];
    }
    return self;
}

- (NGItem *)inspectRes:(Res *)res
{
    NGItem *ngItem = [self inspectID:res];
    if (ngItem) return ngItem;
    ngItem = [self inspectWord:res];
    if (ngItem) return ngItem;
    ngItem = [self inspectName:res];
    if (ngItem) return ngItem;

    return nil;
}

- (BOOL)inspectText:(NSString *)text ngItem:(NGItem *)ngItem
{
    NSRange range;
    if (ngItem.regex) {
        range = [text rangeOfString:ngItem.value options:NSRegularExpressionSearch];
    } else {
        range = [text rangeOfString:ngItem.value];
    }

    if (range.location != NSNotFound) {
        ngItem.lastUsed = (NSInteger)[[NSDate date] timeIntervalSince1970];
        return YES;
    }

    return NO;
}

- (NGItem *)inspectWord:(Res *)res
{
    NSString *naturalText = [res naturalText];
    for (NGItem *ngItem in self.ngWordItems) {
        if (ngItem && [self inspectText:naturalText ngItem:ngItem]) {
            return ngItem;
        }
    }
    return nil;
}

- (NGItem *)inspectName:(Res *)res
{
    if (res.name && [res.name length] > 0) {
        for (NGItem *ngItem in self.ngNameItems) {
            if (ngItem && [self inspectText:res.name ngItem:ngItem]) {
                return ngItem;
            }
        }
    }
    return nil;
}

- (NGItem *)inspectID:(Res *)res
{
    if (res.ID && [res.ID length] > 3) {
        for (NGItem *ngItem in self.ngIdItems) {
            if (ngItem && [self inspectText:res.ID ngItem:ngItem]) {
                return ngItem;
            }
        }
    }

    return nil;
}
@end
