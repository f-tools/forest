//
//  ThListViewController.m
//  Forest
//

#import "ThListVC.h"
#import "ThemeManager.h"
#import "MainVC.h"
#import "ThManager.h"
#import "Env.h"
#import "ThreadListParser.h"
#import "MyNavigationVC.h"
#import "ResVC.h"
#import "MySplitVC.h"
#import "AppDelegate.h"
#import "ThTableViewCell.h"
#import "ThVm.h"
#import "ThListTransaction.h"
#import "Views.h"
#import "TextUtils.h"
#import "BoardActionMenu.h"
#import "NGManager.h"

@interface ThListVC ()

@property (nonatomic, copy) NSArray *thList;
@property (nonatomic) NSMutableArray *thVmList;
@property (nonatomic) NSMutableArray *allThVmList;

@property (nonatomic) UIBarButtonItem *selectedSortButton;

@property (nonatomic) NSInteger normalButtonMode; //0:通常 1:既得
@property (nonatomic) NSInteger speedButtonMode;  //0:勢い 1:総数
@property (nonatomic) NSInteger unreadButtonMode; //0:未読 1:お気に入り

@property (nonatomic) BOOL isSearchMode;

@end

@implementation ThListVC

static NSString *const kSelectedSortModeKey = @"selectedSortMode";
static NSString *const kNormalButtonModeKey = @"normalButtonMode";
static NSString *const kSpeedButtonModeKey = @"speedButtonMode";
static NSString *const kUnreadButtonModeKey = @"unreadButtonMode";

static const NSInteger kSelectedModeNormal = 0;
static const NSInteger kSelectedModeSpeed = 1;
static const NSInteger kSelectedModeUnread = 2;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"スレ一覧";
    }
    return self;
}

- (UIView *)getToolbar
{
    return self.mainToolbar;
}

- (void)dealloc
{
    NSLog(@"dealloc thListVC");
    self.allThVmList = nil;
    self.thVmList = nil;
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.thList = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadListPageTintColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadListPageTintColor];

    // 選択していたソートタブの復元
    NSInteger selectedMode = [Env getConfIntegerForKey:kSelectedSortModeKey withDefault:kSelectedModeNormal];
    self.normalButtonMode = [Env getConfIntegerForKey:kNormalButtonModeKey withDefault:0];
    self.speedButtonMode = [Env getConfIntegerForKey:kSpeedButtonModeKey withDefault:0];
    self.unreadButtonMode = [Env getConfIntegerForKey:kUnreadButtonModeKey withDefault:0];

    if (selectedMode == kSelectedModeSpeed) {
        [self changeSortButton:self.speedOrderButton];
    } else if (selectedMode == kSelectedModeUnread) {
        [self changeSortButton:self.unreadOnlyButton];
    } else {
        [self changeSortButton:self.normalOrderButton];
    }

    [self refreshUnreadButtonText];
    [self refreshNormalButtonText];
    [self refreshSpeedButtonText];

    if ([MySplitVC instance].isTabletMode) {
        NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self.mainToolbar items]];
        [items removeObject:self.moreButton];
        [self.mainToolbar setItems:items];
    }

    UIBarButtonItem *searchButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(onSearchBarButton:)];

    self.navigationItem.rightBarButtonItem = searchButtonItem;

    self.moreButton.tintColor = [UIColor grayColor];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.hasSections = NO;

    [self.mainToolbar setBackgroundImage:[UIImage new]
                      forToolbarPosition:UIBarPositionAny
                              barMetrics:UIBarMetricsDefault];

    [self.mainToolbar setShadowImage:[UIImage new]
                  forToolbarPosition:UIToolbarPositionAny];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

//タブレットモードのメニューボタン押したとき
- (void)onContextMenuTap
{
    [self onMoreButtonTap:nil];
}

- (void)refreshed:(id)sender
{
    [self updateAll];
}

- (void)onSearchBarButton:(id)sender
{
    self.isSearchMode = YES;
    UIBarButtonItem *addNewButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelBarButton:)];

    self.navigationItem.rightBarButtonItem = addNewButton;

    UISearchBar *searchBar = [[UISearchBar alloc] init];
    self.navigationItem.titleView.frame = CGRectMake(0, 0, 320, 44);

    searchBar.delegate = self;

    self.navigationItem.titleView = searchBar;

    if ([MySplitVC instance].isTabletMode) {
        [[MainVC instance] updateNavigationBarButtons];
    }

    
    [searchBar setNeedsDisplay];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [NSThread sleepForTimeInterval:0.1];
      dispatch_sync(dispatch_get_main_queue(), ^{

        [Views customKeyboardOnSearchBar:searchBar withKeyboardAppearance:[[ThemeManager sharedManager] useBlackKeyboard] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceDefault];

        [searchBar becomeFirstResponder];

      });
    });
}

- (void)onCancelBarButton:(id)sender
{
    [self closeSearchMode];
}

// @ret 閉じたかどうか
- (BOOL)closeSearchMode
{
    if (self.isSearchMode == NO) return NO;

    self.isSearchMode = NO;
    UIBarButtonItem *addNewButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                  target:self
                                                                                  action:@selector(onSearchBarButton:)];

    self.navigationItem.rightBarButtonItem = addNewButton;

    //[searchBar resignFirstResponder];

    self.navigationItem.titleView = nil;
    self.navigationItem.title = self.title;
    if ([MySplitVC instance].isTabletMode) {
        [[MainVC instance] updateNavigationBarButtons];
    }

    [self createThVmList];
    [self startRegenerateTableData];

    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.currentCellTag++;

    NSMutableArray *newThVmList = [NSMutableArray array];
    for (Th *th in self.thList) {
        if (th.title && [TextUtils ambiguitySearchText:th.title searchKey:searchText]) {
            ThVm *thVm = [[ThVm alloc] initWithTh:th];
            [newThVmList addObject:thVm];
        }
    }

    self.thVmList = newThVmList;
    [self startRegenerateTableData];
    [self tableViewScrollToTopAnimated:NO];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self closeSearchMode];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //キーボードを隠す
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([MySplitVC instance].isTabletMode == NO) {
        [[MyNavigationVC instance] setNavigationBarHidden:NO animated:NO];
    }

    if (self.isSearchMode == NO) {
        [self sortBySelectedSortButton];
    }
}

- (void)onThemeChanged
{
    [super onThemeChanged];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView layoutIfNeeded];
    [self.tableView setNeedsDisplay];

    self.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadListPageTintColor];
    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeUnderneathBackgroundColor];

    UIImage *backgroundImage = [[ThemeManager sharedManager] backgroundImageForKey:ThemeThreadListPageBackgroundImage];
    self.backgroundImageView.image = backgroundImage;
    self.backgroundImageView.contentMode = UIViewContentModeTop;
    self.backgroundImageView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadListPageBackgroundColor];
    [self.mainToolbar setBackgroundColor:[[ThemeManager sharedManager] colorForKey:ThemeThreadListPageToolBarBackgroundColor]];
    self.toolbarBorder.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];

    [self.tableView setSeparatorColor:[[ThemeManager sharedManager] colorForKey:ThemeThreadRowSeparatorColor]];
}

- (void)refreshNormalButtonText
{
    NSString *buttonText = nil;
    if (self.normalButtonMode == 0) {
        buttonText = @"通常";
    } else if (self.normalButtonMode == 1) {
        buttonText = @"既得";
    }
    [self.normalOrderButton setTitle:buttonText];
}
- (void)refreshSpeedButtonText
{
    NSString *buttonText = nil;
    if (self.speedButtonMode == 0) {
        buttonText = @"勢い";
    } else {
        buttonText = @"総数";
    }
    [self.speedOrderButton setTitle:buttonText];
}

- (void)refreshUnreadButtonText
{
    NSString *buttonText = nil;
    if (self.unreadButtonMode == 0) {
        buttonText = @"未読";
    } else {
        buttonText = @"★付";
    }
    [self.unreadOnlyButton setTitle:buttonText];
}

- (void)changeSortButton:(UIBarButtonItem *)button
{
    NSArray *buttonArray = @[ self.normalOrderButton, self.speedOrderButton, self.unreadOnlyButton ];

    self.selectedSortButton = button;

    //未読ボタンはテキスト可変
    if (self.selectedSortButton == self.unreadOnlyButton) {
        [self refreshUnreadButtonText];
    } else if (self.selectedSortButton == self.normalOrderButton) {
        [self refreshNormalButtonText];
    } else if (self.selectedSortButton == self.speedOrderButton) {
        [self refreshSpeedButtonText];
    }

    for (UIBarButtonItem *b in buttonArray) {
        if (b == button) {
            b.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];
        } else {
            b.tintColor = [UIColor grayColor];
        }
    }
}

- (NSArray *)getThVmList
{
    return [NSArray arrayWithArray:self.thVmList];
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
    return @"更新";
}

- (void)updateAll
{
    ThListTransaction *thListTransaction = [[ThListTransaction alloc] init];
    thListTransaction.thListVC = self;
    [thListTransaction startOpenThListTransaction:self.board];
    [self tableViewScrollToTopAnimated:NO];
}

- (void)notifyThListUpdated:(NSArray *)list
{
    self.thList = list;
    [self createThVmList];
    [self startRegenerateTableData];
}

- (void)setThList:(NSArray *)list withBoard:(Board *)board
{
    self.board = board;
    self.thList = list;
    self.title = board.boardName;
    [self createThVmList];
}

- (void)createThVmList
{ 
    self.thVmList = [NSMutableArray array];
    self.allThVmList = [NSMutableArray array];
    ThreadNGInspector *inspector = [[NGManager sharedManager] createThreadNGInspectorForBoard:self.board];

    for (Th *th in self.thList) {
        NGItem *ngItem = [inspector inspectThread:th];
        if (ngItem == nil) {
            ThVm *thVm = [[ThVm alloc] initWithTh:th]; //[self genThVm:newTh];

            [self.thVmList addObject:thVm];
        }
    }

    self.allThVmList = self.thVmList;
    [self sortBySelectedSortButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (ThVm *)thVmForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThVm *thVm = [self.thVmList objectAtIndex:indexPath.row];
    return thVm;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.thVmList == nil ? 0 : [self.thVmList count];
}

- (IBAction)onMoreButtonTap:(id)sender
{
    BoardActionMenu *boardActionMenu = [[BoardActionMenu alloc] init];
    boardActionMenu.hideFavBoard = YES;
    boardActionMenu.board = self.board;
    [boardActionMenu build];

    [[MySplitVC instance] openActionMenu:boardActionMenu];
}

- (IBAction)onMoreButtonAction:(id)sender
{
}

- (void)sortBySelectedSortButton
{
    if (self.selectedSortButton == nil) {
        self.selectedSortButton = self.normalOrderButton;
    }

    if (self.selectedSortButton == self.normalOrderButton) {
        NSMutableArray *newThVmList = [NSMutableArray array];
        NSMutableArray *excludedThVmList = [NSMutableArray array];
        for (ThVm *thVm in self.allThVmList) {
            if (self.normalButtonMode == 0) { //通常
                [newThVmList addObject:thVm];
            } else {
                //既読上部
                if (thVm.th.lastReadTime > 0) {
                    [newThVmList addObject:thVm];
                } else {
                    [excludedThVmList addObject:thVm];
                }
            }
        }
        [newThVmList addObjectsFromArray:excludedThVmList];

        self.thVmList = newThVmList;

    } else if (self.selectedSortButton == self.speedOrderButton) {
        NSArray *sortedThList = nil;
        if (self.speedButtonMode == 0) { //勢い
            sortedThList = [self.allThVmList sortedArrayUsingSelector:@selector(compareSpeed:)];
        } else { //カウント
            sortedThList = [self.allThVmList sortedArrayUsingSelector:@selector(compareCount:)];
        }
        self.thVmList = [NSMutableArray arrayWithArray:sortedThList];

    } else if (self.selectedSortButton == self.unreadOnlyButton) {
        NSMutableArray *newThVmList = [NSMutableArray array];
        NSMutableArray *excludedThVmList = [NSMutableArray array];
        for (ThVm *thVm in self.allThVmList) {
            if (self.unreadButtonMode == 0) { //未読上部
                if (thVm.th.lastReadTime > 0 && thVm.th.read < thVm.th.count) {
                    [newThVmList addObject:thVm];
                } else {
                    [excludedThVmList addObject:thVm];
                }
            } else { // お気に入り上部
                if (thVm.th.isFav) {
                    [newThVmList addObject:thVm];
                } else {
                    [excludedThVmList addObject:thVm];
                }
            }
        }

        [newThVmList addObjectsFromArray:excludedThVmList];

        self.thVmList = newThVmList;
    }
}

- (void)saveSelectedSortButton:(NSInteger)index
{
    [Env setConfInteger:index forKey: kSelectedSortModeKey];
}

- (IBAction)onNormalButtonAction:(id)sender
{
    if (self.selectedSortButton == self.normalOrderButton) {
        if (self.normalButtonMode == 0) {
            self.normalButtonMode = 1;
        } else {
            self.normalButtonMode = 0;
        }
        [Env setConfInteger:self.normalButtonMode forKey:kNormalButtonModeKey];
    }

    [self changeSortButton:self.normalOrderButton];

    [self sortBySelectedSortButton];
    [self startRegenerateTableData];
    [self tableViewScrollToTopAnimated:NO];

    [self saveSelectedSortButton:kSelectedModeNormal];
}

- (IBAction)onSpeedButtonAction:(id)sender
{
    if (self.selectedSortButton == self.speedOrderButton) {
        if (self.speedButtonMode == 0) {
            self.speedButtonMode = 1;
        } else {
            self.speedButtonMode = 0;
        }

        [Env setConfInteger:self.speedButtonMode forKey:kSpeedButtonModeKey];
    }

    [self changeSortButton:self.speedOrderButton];

    [self sortBySelectedSortButton];
    [self startRegenerateTableData];
    [self tableViewScrollToTopAnimated:NO];

    [self saveSelectedSortButton:kSelectedModeSpeed];
}

- (IBAction)onUnreadOnlyButtonAction:(id)sender
{
    if (self.selectedSortButton == self.unreadOnlyButton) {
        if (self.unreadButtonMode == 0) {
            self.unreadButtonMode = 1;
        } else {
            self.unreadButtonMode = 0;
        }
        [Env setConfInteger:self.unreadButtonMode forKey:kUnreadButtonModeKey];
    }

    [self changeSortButton:self.unreadOnlyButton];
    [self sortBySelectedSortButton];
    [self startRegenerateTableData];
    [self tableViewScrollToTopAnimated:NO];

    [self saveSelectedSortButton:kSelectedModeUnread];
}

- (IBAction)onRefreshBarButtonItemAction:(id)sender
{
    [self updateAll];
}

@end
