//
//  BoardViewController.m
//  Forest
//

#import "BoardVC.h"
#import "BoardManager.h"
#import "ThemeManager.h"
#import "ThListVC.h"
#import "MyNavigationVC.h"
#import "MainVC.h"
#import "BaseTableVC.h"
#import "AppDelegate.h"
#import "ThListTransaction.h"
#import "SearchWebViewController.h"
#import "TabContextMenu.h"
#import "BoardActionMenu.h"
#import "AddExternalBoardVC.h"
#import "MySplitVC.h"

@implementation BoardSelectNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"戻る"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(backPressed:)];

    BoardVC *boardVC = [[BoardVC alloc] initWithNibName:@"BoardVC" bundle:nil];
    self.boardVC = boardVC;

    UIBarButtonItem *allButton = [[UIBarButtonItem alloc] initWithTitle:@"全体化"
                                                                  style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(setAll:)];

    boardVC.selectBoardMode = YES;
    boardVC.navigationItem.leftBarButtonItem = backButton;
    boardVC.navigationItem.rightBarButtonItem = allButton;
    [self pushViewController:boardVC animated:YES];
}

- (void)backPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setAll:(id)sender
{
    if (self.boardVC.completionBlock) {
        self.boardVC.completionBlock(nil);
    }
    self.boardVC.completionBlock = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

@class BoardLeftViewController;
@class BoardRightViewController;

// -----------------------------------------------
//              右側のグループ選択TableView
// -----------------------------------------------
@interface BoardRightViewController : BaseTableVC

@property (nonatomic) BoardVC *boardVC;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) UINavigationController *navigationController;
@property (nonatomic) ThListVC *ctrl;

- (void)setBoards:(NSArray *)categories withName:(NSString *)name;

@end

@implementation BoardRightViewController

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                             action:@selector(fuga:)];
    longPressGestureRecognizer.minimumPressDuration = 0.7;
    [self.tableView addGestureRecognizer:longPressGestureRecognizer];
}

- (void)fuga:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (self.tableView && self.tableView.isEditing) return;

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {

        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];

        BoardActionMenu *boardActionMenu = [[BoardActionMenu alloc] init];
        boardActionMenu.board = [self.itemArray objectAtIndex:indexPath.row];
        boardActionMenu.boardVC = self.boardVC;
        [boardActionMenu build];

        [[MySplitVC instance] openActionMenu:boardActionMenu];
    }
}

- (void)setBoards:(NSArray *)categories withName:(NSString *)name
{
    self.name = name;
    self.itemArray = categories;
}

- (NSString *)itemTitle:(NSObject *)item
{
    Board *board = (Board *)item;

    return board.boardName;
}

- (void)didSelectAtItem:(NSObject *)item
{
    if (self.boardVC.selectBoardMode) {
        if (self.boardVC.completionBlock) {
            self.boardVC.completionBlock((Board *)item);
        }
        self.boardVC.completionBlock = nil;
        [self.boardVC.navigationController dismissViewControllerAnimated:YES completion:nil];

    } else {

        ThListTransaction *thListTransaction = [[ThListTransaction alloc] init];
        [thListTransaction startOpenThListTransaction:(Board *)item];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.name;
}

@end

// -----------------------------------------------
//              左側のグループ選択TableView
// -----------------------------------------------
@interface BoardLeftViewController : BaseTableVC {
}

@property (nonatomic) UINavigationController *navigationController;

@property (nonatomic) BoardRightViewController *rightViewController;

@property (nonatomic) BoardVC *boardVC;
@property (nonatomic) ArkCategory *selectedCategory;

- (void)selectCategory:(ArkCategory *)category;
- (void)setCategories:(NSArray *)categories;

@end

@implementation BoardLeftViewController

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

- (void)setCategories:(NSArray *)categories
{
    self.itemArray = categories;
    [self.tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"カテゴリ一覧";
}

- (NSString *)itemTitle:(NSObject *)item
{
    ArkCategory *category = (ArkCategory *)item;

    return category.name;
}

- (void)selectCategory:(ArkCategory *)category
{
    self.selectedCategory = category;
    [self.rightViewController setBoards:category.boards withName:category.name];

    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:0];
    [self.rightViewController.tableView reloadSections:sections
                                      withRowAnimation:UITableViewRowAnimationRight];

    [self.rightViewController.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

- (void)didSelectAtItem:(NSObject *)item
{
    ArkCategory *category = (ArkCategory *)item;
    [self selectCategory:category];
}
@end

// -----------------------------------------------
//              BoardViewController
// -----------------------------------------------

@interface BoardVC ()
@property (nonatomic) BOOL isToolbarShown;
@property (nonatomic) BOOL isAlertShown;
@property (nonatomic) GestureManager *gesture;
@property (nonatomic) BOOL leftTableGesture;

@end

@implementation BoardVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"板一覧";

        UIBarButtonItem *refreshBarButton = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                 target:self
                                 action:@selector(refreshed:)];

        UIBarButtonItem *addExternalBarButton = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                 target:self
                                 action:@selector(onTapExternalButton:)];

        UIBarButtonItem *searchBarButton = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                 target:self
                                 action:@selector(onSearch:)];

        self.navigationItem.leftBarButtonItems = @[ refreshBarButton, addExternalBarButton ];
        self.navigationItem.rightBarButtonItems = @[ searchBarButton ];
    }

    return self;
}

- (void)viewDidAppear:(BOOL)animated
{

    //板一覧の読み込み
    NSArray *categories = [[BoardManager sharedManager] categories];

    if (categories && [categories count] > 3) {

    } else {
        if (self.isAlertShown == NO) {
            self.isAlertShown = YES;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"板一覧の更新(左上アイコン)" message:@"左上の更新アイコンを押すと板一覧を更新します。板が移転した場合にも利用してください。 \nPlease push refresh button in the upper left to update the board list." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)onContextMenuTap
{
    TabContextMenu *menu = [[TabContextMenu alloc] init];
    menu.isBoardContext = YES;
    [menu build];
    [[MySplitVC instance] openActionMenu:menu];
}

// @override
- (void)onTabSelected:(UITabBarItem *)tabItem tapTwice:(BOOL)tapTwice
{

    if (tapTwice) {
        ArkCategory *favCategory = [[BoardManager sharedManager] favoriteCategory];
        ArkCategory *externalCategory = [[BoardManager sharedManager] externalCategory];

        //「お気に入り・外部版」を切り替え
        if (self.leftViewController.selectedCategory == favCategory) {
            [self.leftViewController selectCategory:externalCategory];
        } else {
            [self.leftViewController selectCategory:favCategory];
        }
    }
}


- (void)viewDidLayoutSubviews
{
}

- (void)viewDidLoad
{

    [super viewDidLoad];

    self.gesture = [[GestureManager alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowEvent:)
                                                 name:MYO_WINDOW_EVENT_NOTIFICATION
                                               object:[[[UIApplication sharedApplication] delegate] window]];

    if (self.selectBoardMode) {
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
    }

    self.isToolbarShown = YES;


    self.leftViewController = [[BoardLeftViewController alloc] init];
    self.rightViewController = [[BoardRightViewController alloc] init];

    [self applyTheme];

    [self.leftTableContainer addSubview:self.leftViewController.view];
    [self addChildViewController:self.leftViewController];
    UIView *leftTableView = self.leftViewController.view;
    self.leftTableContainer.translatesAutoresizingMaskIntoConstraints = NO;
    leftTableView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.rightTableContainer addSubview:self.rightViewController.view];
    UIView *rightTableView = self.rightViewController.view;
    rightTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightTableContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:self.rightViewController];

    self.leftViewController.rightViewController = self.rightViewController;

    NSDictionary *views = NSDictionaryOfVariableBindings(leftTableView);

    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[leftTableView]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views];
    [self.leftTableContainer addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftTableView]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.leftTableContainer addConstraints:constraints];

    views = NSDictionaryOfVariableBindings(rightTableView);

    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[rightTableView]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.rightTableContainer addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rightTableView]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.rightTableContainer addConstraints:constraints];

    self.leftViewController.boardVC = self;
    self.rightViewController.boardVC = self;

    //板一覧の読み込み
    NSArray *categories = [[BoardManager sharedManager] categories];
    if (categories && [categories count] > 3) {
        myLog(@"categories count = %lu", [categories count]);
    } else {
        // [[BoardManager sharedManager] fetchBBSMenuAsync];
        //categories = [[BoardManager sharedManager] categories];
    }

    if (categories != nil) {
        myLog(@"self.leftViewController %@", self.leftViewController);
        [self.leftViewController setCategories:categories];
    }

    // デフォルトの通知センターを取得する
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(onThemeChanged:) name:@"themeChanged" object:nil];

    [self reloadTable];

}
- (void)applyTheme
{

    [self.view setBackgroundColor:[[ThemeManager sharedManager] colorForKey:ThemeBoardViewBackgroundColor]];

    self.leftViewController.desiredTableViewBackgroundColor = [UIColor clearColor];
    self.rightViewController.desiredTableViewBackgroundColor = [UIColor clearColor];

    self.leftViewController.desiredSectionBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeBoardSectionBackgroundColor];
    self.rightViewController.desiredSectionBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeBoardSectionBackgroundColor];
    self.leftViewController.overrideTableViewCellBackgroundColor = [UIColor clearColor];
    self.rightViewController.overrideTableViewCellBackgroundColor = [UIColor clearColor];

    [self.rightTableContainer setBackgroundColor:[UIColor clearColor]];
    [self.leftTableContainer setBackgroundColor:[UIColor clearColor]];

    [[ThemeManager sharedManager] changeTableViewStyle:self.rightViewController.tableView];
    [[ThemeManager sharedManager] changeTableViewStyle:self.leftViewController.tableView];
    [self.rightViewController.tableView setSeparatorColor:[[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor]];
    [self.leftViewController.tableView setSeparatorColor:[[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor]];

    [self.rightTableContainer setNeedsDisplay];
    [self.leftTableContainer setNeedsDisplay];

    [self reloadTable];
}

- (void)reloadTable
{
    NSArray *categories = [[BoardManager sharedManager] categories];

    if (categories != nil) {
        [self.leftViewController setCategories:categories];

        if ([categories count] > 0) {
            ArkCategory *firstCategory = [categories objectAtIndex:0];
            [self.leftViewController selectCategory:firstCategory];
        } else {
            [self.rightViewController setBoards:[NSArray array] withName:@""];
            [self.rightViewController.tableView reloadData];
        }
    }
}

- (void)refreshed:(id)sender
{
    [[BoardManager sharedManager] fetchBBSMenuAsync];

    [self reloadTable];
}

- (void)onTapExternalButton:(id)sender
{
    AddExternalBoardVC *vc = [[AddExternalBoardVC alloc] init];
    vc.onAddBoardCompleted = ^(BOOL success) {

      [self reloadTable];

    };
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}
// 通知と値を受けるhogeメソッド
- (void)onThemeChanged:(NSNotification *)center
{
    [self applyTheme];
}

- (void)didBoardsChanged
{ //板一覧が少しでも変化したら再描画を促すために通知する。
    NSArray *categories =
        [[BoardManager sharedManager] categories];

    [self.leftViewController setCategories:categories];

    [self.leftViewController.tableView reloadData];

    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:0];
    [self.leftViewController.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onSearch:(id)sender
{

    SearchWebViewController *searchWebViewController = [[SearchWebViewController alloc] init];
    searchWebViewController.searchUrl = @"http://ff2ch.syoboi.jp"; //self.searchTextView.text;
    
    if ([MySplitVC instance].isTabletMode) {
     
        [[MainVC instance] showThListVC:searchWebViewController];
    } else {
        [[MyNavigationVC instance] pushMyViewController:searchWebViewController];
    }
}

- (NSArray *)getGestureItems
{
    __weak BoardVC *weakSelf = self;

    NSMutableArray *gestureItems = [NSMutableArray array];

    GestureEntry *gestureItem = [[GestureEntry alloc] init];
    gestureItem.nameGetter = ^{
      return @"進む";
    };
    gestureItem.directions = [[NSArray alloc] initWithObjects:DIRECTION_LEFT, nil];
    //    gestureItem.isEnabled = ^{ return (weakSelf.nextViewController != nil); };
    gestureItem.completionBlock = ^{
      if (weakSelf) {
          MyNavigationVC *myNavigationViewController = [MyNavigationVC instance];
          [myNavigationViewController pushNexViewController];
      }
    };
    [gestureItems addObject:gestureItem];

    gestureItem = [[GestureEntry alloc] init];
    gestureItem.nameGetter = ^{
      return @"最後に";
    };
    gestureItem.isEnabled = ^{
      return YES;
    };
    gestureItem.directions = [[NSArray alloc] initWithObjects:DIRECTION_RIGHT, DIRECTION_UP, nil];
    gestureItem.completionBlock = ^{
      UITableView *tableView = weakSelf.leftTableGesture ? weakSelf.leftViewController.tableView : weakSelf.rightViewController.tableView;
      tableView.contentOffset = CGPointMake(0, tableView.contentSize.height - tableView.bounds.size.height);
    };
    [gestureItems addObject:gestureItem];

    gestureItem = [[GestureEntry alloc] init];
    gestureItem.nameGetter = ^{
      return @"最初に";
    };
    gestureItem.isEnabled = ^{
      return YES;
    };
    gestureItem.directions = [[NSArray alloc] initWithObjects:DIRECTION_RIGHT, DIRECTION_DOWN, nil];
    gestureItem.completionBlock = ^{
      UITableView *tableView = weakSelf.leftTableGesture ? weakSelf.leftViewController.tableView : weakSelf.rightViewController.tableView;
      tableView.contentOffset = CGPointMake(0, 0);
    };
    [gestureItems addObject:gestureItem];

    return gestureItems;
}

- (void)windowEvent:(NSNotification *)notification
{
    if (![self isViewVisible] || self.selectBoardMode) {
        return;
    }

    UIEvent *event = (id)notification.userInfo;
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self.view];
    
    
    switch (touch.phase) {
    case UITouchPhaseBegan: {

        CGPoint leftPos = [touch locationInView:self.leftViewController.tableView];
        BOOL inLeftTable = (CGRectContainsPoint(self.leftViewController.tableView.bounds, leftPos));

        CGPoint rightPos = [touch locationInView:self.rightViewController.tableView];
        BOOL inRightTable = (CGRectContainsPoint(self.rightViewController.tableView.bounds, rightPos));

        self.leftTableGesture = inLeftTable;

        [self.gesture touchesBegan:pos withEvent:event];
        if (inLeftTable == NO && inRightTable == NO) {
            [self.gesture cancel];
        }
        break;
    }
    case UITouchPhaseMoved: {
        BOOL beforeGestureEnabled = [self.gesture isGestureStarted];
        [self.gesture touchesMoved:pos withEvent:event];
        if ([self isViewVisible] && [self.gesture isGestureStarted]) {
            GestureEntry *showingGestureItem = nil;

            if (beforeGestureEnabled == NO) { // ジェスチャーが有効になった瞬間にセル選択を解除
                NSArray *indexPathList = [self.leftViewController.tableView indexPathsForVisibleRows];
                for (NSIndexPath *indexPath in indexPathList) {
                    [self.leftViewController.tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
                indexPathList = [self.rightViewController.tableView indexPathsForVisibleRows];
                for (NSIndexPath *indexPath in indexPathList) {
                    [self.rightViewController.tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
            }

            NSArray *gestureItems = [self getGestureItems];
            for (GestureEntry *gestureItem in gestureItems) {
                if ([self.gesture isGesture:gestureItem.directions]) {
                    if (gestureItem.isEnabled == nil || gestureItem.isEnabled()) {
                        showingGestureItem = gestureItem;
                        break;
                    }
                }
            }
            AppDelegate *app = [UIApplication sharedApplication].delegate;
            [app.window showGestureInfo:showingGestureItem];
        }
    } break;

    case UITouchPhaseEnded: {
        [self.gesture touchesEnded:pos withEvent:event];

        if ([self isViewVisible] && [self.gesture isGestureStarted]) {
            NSArray *gestureItems = [self getGestureItems];
            for (GestureEntry *gestureItem in gestureItems) {
                if ([self.gesture isGesture:gestureItem.directions]) {
                    if (gestureItem.isEnabled == nil || gestureItem.isEnabled()) {
                        if (gestureItem.completionBlock) {
                            gestureItem.completionBlock();
                        }
                    }
                }
            }
        }
        AppDelegate *app = [UIApplication sharedApplication].delegate;
        [app.window dismissGestureInfo];
    } break;

    case UITouchPhaseCancelled: {
        [self.gesture touchesEnded:pos withEvent:event];
        AppDelegate *app = [UIApplication sharedApplication].delegate;
        [app.window dismissGestureInfo];
    } break;
    default:
        break;
    }
}
@end
