//
//  HistoryViewController.m
//  Forest
//

#import "HistoryVC.h"
#import "ResVC.h"
#import "ThemeManager.h"
#import "ThManager.h"
#import "AppDelegate.h"
#import "ThVm.h"
#import "Env.h"
#import "UpdateAllTransaction.h"
#import "TabContextMenu.h"
#import <FMDatabase.h>
#import "MySplitVC.h"

static NSString *HistoryTableName = @"history";
static NSString *COL_Thread_Url = @"thread_url";
static NSString *COL_Thread_Unique_Key = @"th_unique_key";
static NSString *COL_Last_Read_Time = @"last_read_time";

@interface SpanThList : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSInteger timeFrom;
@property (nonatomic) SpanThList *next;
@property (nonatomic) NSMutableArray *array;
@property (nonatomic) BOOL isNowSpan;
@end

@implementation SpanThList

- (id)initWithTitle:(NSString *)title withTimeFrom:(NSInteger)timestamp
{
    if (self = [super init]) {
        _title = title;
        _array = [NSMutableArray array];
        _timeFrom = timestamp;
    }

    return self;
}

- (void)insertToTop:(ThVm *)thVm
{
    NSInteger count = [self.array count];
    for (int i = 0; i < count; i++) {
        ThVm *existThVm = [self.array objectAtIndex:i];
        if (existThVm.th == thVm.th) {
            [self.array removeObjectAtIndex:i];
            break;
        }
    }
    [self.array insertObject:thVm atIndex:0];
}

- (NSUInteger)count
{
    return [self.array count];
}

- (ThVm *)objectAtIndex:(NSInteger)index
{
    return [self.array objectAtIndex:index];
}

- (BOOL)insertThIfPossible:(ThVm *)thVm
{
    NSDate *now = [NSDate date];
    NSTimeInterval nowStamp = [now timeIntervalSince1970];
    //myLog(@"lastREadTime = %ld", (long)thVm.th.lastReadTime);
    NSTimeInterval interval = nowStamp - thVm.th.lastReadTime;
    //myLog(@"interval = %f, timeFrom = %lu", interval, (long)self.timeFrom);
    if (interval <= self.timeFrom) {
        [self.array addObject:thVm];
        return YES;
    }
    return NO;
}

@end

static NSObject *_historyFileEditLockObject;
static HistoryVC *_historyViewContollerInstance;

@interface HistoryVC () {
    NSMutableSet *_historySet; //atomic
}

@property (nonatomic) NSMutableSet *historySet;        //atomic
@property (nonatomic) NSMutableArray *historyThVmList; //atomic
@property (nonatomic) NSInteger lastSortTime;          // 最後にソートした時間

@end

@implementation HistoryVC

+ (id)sharedInstance
{
    return _historyViewContollerInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"履歴";

        _historyFileEditLockObject = [[NSLock alloc] init];

        [self loadHistories];

        [self setNormalBarButtons];
    }

    _historyViewContollerInstance = self;
    return self;
}

- (void)setNormalBarButtons
{
    UIBarButtonItem *refreshBarButton = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                             target:self
                             action:@selector(refreshed:)];

    self.navigationItem.rightBarButtonItems = @[ refreshBarButton ];
    self.navigationItem.leftBarButtonItems = @[ self.editButtonItem ];
}

// The editButtonItem will invoke this method.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    [self.tableView setEditing:editing animated:YES];

    if (editing) {
        [[MainVC instance] hideTabBar];
    } else {
        [[MainVC instance] showTabBar];
    }

    [[MainVC instance] updateNavigationBarButtons];

    self.toolbar.hidden = !editing;
    self.editToolbarHeightConstraint.constant = editing ? 44 : 0;

    [self.toolbar layoutIfNeeded];
    //   [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    // myLog(@"view DidLoad in HistoryViewController");

    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.editToolbarHeightConstraint.constant = 0;

    [self.toolbar setBackgroundImage:[UIImage new]
                  forToolbarPosition:UIBarPositionAny
                          barMetrics:UIBarMetricsDefault];

    [self.toolbar setShadowImage:[UIImage new]
              forToolbarPosition:UIToolbarPositionAny];

    self.hasSections = YES; //ThListBaseVC

    @synchronized(self.tableView)
    {
        _historySet = nil;

        //[self.tableView reloadData];
        [self startRegenerateTableData];
    }
}

- (void)onThemeChanged
{
    [super onThemeChanged];
    self.toolbar.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)onContextMenuTap
{
    TabContextMenu *menu = [[TabContextMenu alloc] init];
    menu.isHistoryContext = YES;
    [menu build];
    [[MySplitVC instance] openActionMenu:menu];
}

// @override
- (void)onTabSelected:(UITabBarItem *)tabItem tapTwice:(BOOL)tapTwice
{
    if (tapTwice) {
    }
}

- (FMDatabase *)openHistoryDatabase
{
    FMDatabase *db = [FMDatabase databaseWithPath:[[Env documentPath]
                                                      stringByAppendingPathComponent:@"history3.db"]];

    if (db == nil) return nil;

    [db open];
    return db;
}

// モデルのみロード(Viewの生成無し)
- (void)loadHistories
{
    FMDatabase *db = [self openHistoryDatabase];
    if (db == nil) return;

    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT, %@ TEXT, %@ TEXT unique, %@ INTEGER);", HistoryTableName, COL_Thread_Unique_Key, COL_Thread_Url, COL_Last_Read_Time];

    [db executeUpdate:sql];

    sql = [NSString stringWithFormat:@"CREATE UNIQUE INDEX date_index ON %@(%@);", HistoryTableName, COL_Last_Read_Time];
    [db executeUpdate:sql];

    sql = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ order by %@ desc limit 200;", COL_Thread_Url, COL_Last_Read_Time, HistoryTableName, COL_Last_Read_Time];

    FMResultSet *results = [db executeQuery:sql];
    NSMutableArray *thVmList = [[NSMutableArray alloc] initWithCapacity:0];
    NSInteger count = 0;
    while ([results next]) {
        count++;
        if (count > 200) {
            break;
        }
        NSString *thUrl = [results stringForColumnIndex:0];
        Th *th = [Th thFromUrl:thUrl];
        th = [[ThManager sharedManager] registerTh:th canLoadFile:YES];
        if (th) {
            [thVmList addObject:[self genThVm:th]];
        }
    }

    myLog(@"db closed");
    [db close];

    self.historyThVmList = [self sortHistories:thVmList];
}

- (NSMutableArray *)getThVmList
{
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (SpanThList *span in self.historyThVmList) {
        [mutableArray addObjectsFromArray:span.array];
    }
    return mutableArray;
}

- (UITableView *)thisTableView
{
    return self.tableView;
}

- (BOOL)canUpdateAll
{
    return YES;
}

- (NSString *)getUpdateAllLabel
{
    return @"巡回";
}

- (void)updateAll
{
    NSMutableArray *allThList = [NSMutableArray array];
    for (ThVm *thVm in [self getThVmList]) {
        [allThList addObject:thVm.th];
    }

    UpdateAllTransaction *allTrans = [[UpdateAllTransaction alloc] init];
    BOOL success = [allTrans startTransaction];
    if (success) {
        [allTrans updateAll:allThList];
    }
}

- (void)refreshed:(id)sender
{
    [self updateAll];
}

- (void)reloadTableDataWhenVisible
{
    @synchronized(self.tableView)
    {
        if ([self isViewVisible]) {
            [self.tableView reloadData];
            self.shouldReloadTableViewWhenViewWillAppear = NO;
        } else {
            self.shouldReloadTableViewWhenViewWillAppear = YES;
        }
    }
    //[self startParseForThVmList];
}

- (void)addHistory:(Th *)th
{ // Async
    if ([self isViewVisible]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self _addHistory:th];
        });
    } else {
        [self _addHistory:th];
    }
}

- (void)_addHistory:(Th *)th
{ // Async
    SpanThList *firstSection = [self.historyThVmList objectAtIndex:0];

    [firstSection insertToTop:[self genThVm:th]];
    [self resortThVmList];

    FMDatabase *db = [self openHistoryDatabase];
    if (db == nil) return;

    NSString *sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@, %@, %@) VALUES (?,?,?);",
                                               HistoryTableName, COL_Thread_Url, COL_Thread_Unique_Key, COL_Last_Read_Time];
    //NSLog(@"sql + %@", sql);

    NSInteger nowTime = (NSInteger)[[NSDate date] timeIntervalSince1970];

    [db executeUpdate:sql, [th threadUrl], [th threadUniqueKey], [NSNumber numberWithInteger:nowTime]];
    // int lastId = [db lastInsertRowId];
    [db close];
}

- (void)removeHistoryThVms:(Th *)th
{
}

- (void)removeHistory:(Th *)th
{
    [self resortThVmList:YES];
    //[self removeFromHistoryFileAsync:th  allSet:self.historySet];

    FMDatabase *db = [self openHistoryDatabase];
    if (db == nil) return;

    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", HistoryTableName, COL_Thread_Unique_Key];

    [db executeUpdate:sql, [th threadUniqueKey]];
    [db close];
}

- (BOOL)resortThVmList
{
    return [self resortThVmList:NO];
}

- (void)applySyncThList:(NSArray *)historyThList
{
    SpanThList *firstSection = [self.historyThVmList objectAtIndex:0];
    for (Th *th in historyThList) {
        [firstSection insertToTop:[self genThVm:th]];
    }

    [self resortThVmList:YES];
}

- (BOOL)resortThVmList:(BOOL)force
{
    if (self.tableView) {
        @synchronized(self.tableView)
        {
            self.historyThVmList = [self sortHistories:[self getThVmList]];
            //self.lastSortTime = nowTime;
            //[self.tableView reloadData];
            //[self reloadTableDataWhenVisible];
            [self startRegenerateTableDataIfVisible];
        }
        return YES;
    }

    return NO;
}

//履歴並び替え
// 0: 15分以内
// 1:１時間以内
// 2: 6時間以内
// 3: 今日
// 4: 今週
// 5: 今月
// 6: 先月より前

- (NSMutableArray *)sortHistories:(NSArray *)sourceThVmList
{

    NSArray *sortedThVmArray = [sourceThVmList sortedArrayUsingSelector:@selector(compareLastReadTime:)];

    // NSDate* now = [NSDate date];
    // double nowStamp = [now timeIntervalSince1970];

    SpanThList *firstArray = nil;
    SpanThList *array = [[SpanThList alloc] initWithTitle:@"今" withTimeFrom:3 * 60];
    firstArray = array;
    array.isNowSpan = YES;

    array = array.next = [[SpanThList alloc] initWithTitle:@"3分前" withTimeFrom:5 * 60];
    array = array.next = [[SpanThList alloc] initWithTitle:@"5分前" withTimeFrom:10 * 60];
    array = array.next = [[SpanThList alloc] initWithTitle:@"10分前" withTimeFrom:30 * 60];
    array = array.next = [[SpanThList alloc] initWithTitle:@"30分前" withTimeFrom:60 * 60];
    array = array.next = [[SpanThList alloc] initWithTitle:@"1時間前" withTimeFrom:6 * 60 * 60];
    array = array.next = [[SpanThList alloc] initWithTitle:@"6時間前" withTimeFrom:12 * 60 * 60];
    array = array.next = [[SpanThList alloc] initWithTitle:@"12時間前" withTimeFrom:24 * 60 * 60];
    array = array.next = [[SpanThList alloc] initWithTitle:@"昨日" withTimeFrom:2 * 24 * 60 * 60];
    array = array.next = [[SpanThList alloc] initWithTitle:@"2日前" withTimeFrom:3 * 24 * 60 * 60];
    array = array.next = [[SpanThList alloc] initWithTitle:@"3日前" withTimeFrom:7 * 24 * 60 * 60];
    array = array.next = [[SpanThList alloc] initWithTitle:@"先週" withTimeFrom:4 * 7 * 24 * 60 * 60];
    array.next = [[SpanThList alloc] initWithTitle:@"一月前" withTimeFrom:2371824030];

    NSMutableSet *duplicateStringSet = [NSMutableSet set];
    SpanThList *firstThList = firstArray;
    int i = 0;
    for (ThVm *thVm in sortedThVmArray) {
        if ([duplicateStringSet member:[thVm.th threadUniqueKey]]) {
            continue;
        }
        if (i++ > 1000) {
            // [histories removeObject:th];
            continue;
        }

        [duplicateStringSet addObject:[thVm.th threadUniqueKey]];

        while (firstThList) {
            if ([firstThList insertThIfPossible:thVm]) {
                break;
            }

            firstThList = firstThList.next;
        }
    }

    NSMutableArray *returnArray = [NSMutableArray array];
    SpanThList *targetArray = firstArray;
    while (targetArray) {
        if (targetArray == firstArray || [targetArray count] > 0) {
            [returnArray addObject:targetArray];
        }
        targetArray = targetArray.next;
    }

    return returnArray;
}

- (ThVm *)thVmForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < [self.historyThVmList count]) {
        SpanThList *spanThList = [self.historyThVmList objectAtIndex:indexPath.section];
        if (indexPath.row < [spanThList count]) {
            return [spanThList objectAtIndex:indexPath.row];
        }
    }
    return nil;
}


#pragma -- mark ThListSection

- (NSMutableArray *)sectionList
{
    return self.historyThVmList;
}

- (NSString *)sectionTitle:(NSObject *)sectionObject
{
    SpanThList *spanThList = (SpanThList *)sectionObject;
    return spanThList.title;
}

- (NSMutableArray *)thVmListInSection:(NSObject *)sectionObject
{
    SpanThList *spanThList = (SpanThList *)sectionObject;
    return spanThList.array;
}

- (IBAction)onPurgeToolButton:(id)sender
{

    NSMutableArray *cellIndicesToBeDeleted = [[NSMutableArray alloc] init];

    NSMutableDictionary *removeRowsDict = [NSMutableDictionary dictionary];

    @synchronized(self)
    {
        NSArray *indexPathes = [self.tableView indexPathsForSelectedRows];
        for (NSIndexPath *indexPath in indexPathes) {
            //SpanThList* folder = [self.historyThVmList objectAtIndex:indexPath.section];
            ThVm *thVm = [self thVmForRowAtIndexPath:indexPath];
            if (thVm) {
                thVm.th.lastReadTime = 0;
                thVm.th.read = 0;
                thVm.th.localCount = 0;
                thVm.th.count = 0;
                // [self removeFromHistoryFileAsync:  allSet:self.historySet];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                   //                    [self _addToHistoryFileAsync:thVm.th addMode:NO canFlushOut:NO];
                               });

                [[ThManager sharedManager] deleteThDataAsync:thVm.th];

                NSMutableArray *removeRows = [removeRowsDict objectForKey:[NSNumber numberWithInteger:indexPath.section]];
                if (removeRows) {
                    [removeRows addObject:[NSNumber numberWithInteger:indexPath.row]];
                } else {
                    NSMutableArray *rows = [NSMutableArray array];
                    [rows addObject:[NSNumber numberWithInteger:indexPath.row]];
                    [removeRowsDict setObject:rows forKey:[NSNumber numberWithInteger:indexPath.section]];
                }
            }
        }

        int i = 0;
        for (SpanThList *spanThList in self.historyThVmList) {
            NSArray *removeRows = [removeRowsDict objectForKey:[NSNumber numberWithInteger:i]];
            if (removeRows) {
                NSMutableIndexSet *removeIndexSet = [NSMutableIndexSet indexSet];
                for (NSNumber *number in removeRows) {
                    if (spanThList.count > number.integerValue) {
                        [removeIndexSet addIndex:number.integerValue];

                        NSIndexPath *p = [NSIndexPath indexPathForRow:number.integerValue inSection:i];
                        [cellIndicesToBeDeleted addObject:p];
                    }
                }
                if (removeIndexSet.count > 0)
                    [spanThList.array removeObjectsAtIndexes:removeIndexSet];
            }
            i++;
        }

        [self.tableView deleteRowsAtIndexPaths:cellIndicesToBeDeleted
                              withRowAnimation:UITableViewRowAnimationLeft];

        //[self saveFavoritesAsync];

        //[self resortThVmList:YES];
        //[self flushOut];
    }
}

- (IBAction)onDoneToolButtonAction:(id)sender
{
    [self setEditing:NO animated:YES];
}

- (IBAction)onSelectAllButtonAction:(id)sender
{
    for (NSInteger s = 0; s < self.tableView.numberOfSections; s++) {
        for (NSInteger r = 0; r < [self.tableView numberOfRowsInSection:s]; r++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:r inSection:s];

            ThVm *thVm = [self thVmForRowAtIndexPath:indexPath];
            if (thVm && thVm.th.isFav) { // お気に入りの場合は除外
                continue;
            }

            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionNone];
        }
    }
}
@end
