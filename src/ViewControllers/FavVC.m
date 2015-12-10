#import "FavVC.h"
#import "Env.h"
#import "ThManager.h"
#import "ThemeManager.h"
#import "AppDelegate.h"
#import "SyncManager.h"
#import "MyNavigationVC.h"
#import "HistoryVC.h"
#import "Th+ParseAdditions.h"
#import "ThUpdater.h"
#import "ResVC.h"
#import "Transaction.h"
#import "BaseTableVC.h"
#import "Views.h"

#import "BaseModalNavigationVC.h"
#import "UpdateAllTransaction.h"
#import "TabContextMenu.h"
#import "AddExternalBoardVC.h"
#import "MySplitVC.h"

@interface FavFolderEditNavigationController : BaseModalNavigationVC

@end

@implementation FavFolderEditNavigationController

@end


@interface TextEditViewController : UIViewController <UITextViewDelegate> {
}
@property (nonatomic) FavFolder *favFolder;
@property (weak, nonatomic) UITextView *textView;

@property (nonatomic) NSLayoutConstraint *textViewBottomConstraint;
@end

@implementation TextEditViewController

- (void)viewWillDisappear:(BOOL)animated
{
    self.favFolder.name = self.textView.text;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.textView.text = self.favFolder.name;
    self.textView.editable = YES;
    [self.textView becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [self.view convertRect:[[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.textViewBottomConstraint.constant = -keyboardFrame.size.height-2;
    [UIView animateWithDuration:duration
                     animations:^{
                       [self.view layoutIfNeeded];
                       [self.textView layoutIfNeeded];
                     }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.textViewBottomConstraint.constant = 0;
    [UIView animateWithDuration:duration
                     animations:^{
                       [self.view layoutIfNeeded];
                     }];
}

- (void)loadView
{
    [super loadView];

    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.textView = textView;

    [textView setFont:[UIFont systemFontOfSize:16]];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    textView.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    [self.view addSubview:textView];

    //textView.keyboardAppearance = UIKeyboardAppearanceDark;
    textView.keyboardAppearance = [[ThemeManager sharedManager] useBlackKeyboard] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceDefault;

    [Views _constraintParentFit:textView withParentView:textView.superview];
    self.textViewBottomConstraint = [Views findConstraint:textView.superview forAttribute:NSLayoutAttributeBottom];
}


@end



@interface FavFolderEditViewController : BaseTableVC


@property (nonatomic) NSMutableArray *favFolders;

@end

@implementation FavFolderEditViewController

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    FavVC *favVC = [FavVC sharedInstance];
    self.favFolders = favVC.favFolders;

    [self rebuildItemArray];

    self.title = @"フォルダ編集";
    self.tableView.allowsSelectionDuringEditing = YES;
    [self setEditing:YES];

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(backPressed:)];

    self.navigationItem.leftBarButtonItem = backButton;

    UIBarButtonItem *addNewButton = [[UIBarButtonItem alloc] initWithTitle:@"フォルダ追加"
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(newFolderPressed:)];

    self.navigationItem.rightBarButtonItem = addNewButton;
}

// top folderの除去
- (void)rebuildItemArray
{
    NSMutableArray *array = [NSMutableArray array];
    BOOL first = YES;
    for (FavFolder *folder in self.favFolders) {
        if (first) {
            first = NO;
        } else {
            [array addObject:folder];
        }
    }
    self.itemArray = array;
}

- (void)newFolderPressed:(id)sender
{

    FavFolder *favFolder = [[FavFolder alloc] init];
    favFolder.name = [@"Folder " stringByAppendingFormat:@"%tu", [self.favFolders count]];
    [self.favFolders addObject:favFolder];
    [self rebuildItemArray];
    [self.tableView reloadData];
}

- (void)backPressed:(id)sender
{
    [[FavVC sharedInstance] saveFavoritesAsync];
    [[FavVC sharedInstance] notifyEditFavFolders];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.favFolders removeObjectAtIndex:indexPath.row + 1];
        [self rebuildItemArray];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationMiddle];
        [tableView endUpdates];

        [tableView reloadData];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath
{
    FavFolder *folder = (FavFolder *)[self.favFolders objectAtIndex:fromIndexPath.row + 1];
    [self.favFolders removeObjectAtIndex:fromIndexPath.row + 1];
    [self.favFolders insertObject:folder atIndex:toIndexPath.row + 1];
    [self rebuildItemArray];
    // [self saveFavoritesAsync];
}


- (NSString *)itemTitle:(NSObject *)item
{
    FavFolder *favFolder = (FavFolder *)item; //[self.favFolders objectAtIndex:indexPath.row+1];
    return favFolder.name;
    //return @"title";
}


- (void)didSelectAtItem:(NSObject *)item
{
    FavFolder *favFolder = (FavFolder *)item;

    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];

    TextEditViewController *textEditCon = [[TextEditViewController alloc] init];
    textEditCon.favFolder = favFolder;
    // [textEditCon.view addSubview:uiView];

    [self.navigationController pushViewController:textEditCon animated:YES];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    //  Pass the selected object to the new view controller.
}

@end

@implementation FavFolder

- (id)init
{
    if (self = [super init]) {
        _thVmList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    [copy setName:self.name];
    //[copy setId:[self id]];
    // [copy setTitle:[self title]];
    return copy;
}

- (BOOL)containsForTh:(Th *)th
{
    for (Th *favTh in self.thVmList) {
        if (favTh == th) {
            return YES;
        }
    }
    return NO;
}

@end

@interface FavVC ()

@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) BOOL isViewDidLoaded;
@property (nonatomic) NSObject *favFoldersLockObj;

@property (nonatomic) UIBarButtonItem *refreshBarButton;
@property (nonatomic) UIBarButtonItem *folderBarButton; // for editing

@property (nonatomic) NSMutableDictionary *folderDictionary;
@end

static NSObject *_favoriteFileEditLockObject;
static FavVC *_favViewContollerInstance;

@implementation FavVC

@synthesize favFolders = _favFolders;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"お気に入り";

        _favFoldersLockObj = [[NSObject alloc] init];
        _favViewContollerInstance = self;

        self.refreshBarButton = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                 target:self
                                 action:@selector(refreshed:)];

        self.folderBarButton = [[UIBarButtonItem alloc]
            initWithTitle:@"フォルダ編集"
                    style:UIBarButtonItemStylePlain
                   target:self
                   action:@selector(touchedFavFolderEditButton:)];

        self.navigationItem.rightBarButtonItems = @[self.refreshBarButton];
        self.navigationItem.leftBarButtonItems = @[self.editButtonItem];

        [self favFolders]; //☆解除
    }

    return self;
}

+ (id)sharedInstance
{
    return _favViewContollerInstance;
}

//- (void ) viewWillAppear:(BOOL)animated {
//   [super viewWillAppear:animated];
//}
//
//- (void ) viewDidAppear:(BOOL)animated {
//   [super viewDidAppear:animated];
//}

- (BOOL)canEditing
{
    return YES;
}

- (NSMutableArray *)favFolders
{
    @synchronized(_favFoldersLockObj)
    {
        if (_favFolders == nil) {
            [self loadFavorites];
        }
    }

    return _favFolders;
}

- (void)setFavFolders:(NSMutableArray *)favFolders
{
    _favFolders = favFolders;
}

- (void)onContextMenuTap
{
    TabContextMenu *menu = [[TabContextMenu alloc] init];
    menu.isFavContext = YES;
    [menu build];
    [[MySplitVC instance] openActionMenu:menu];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    myLog(@"viewWillAppear in favVC");
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    super.hasSections = YES; //ThListBaseVC

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.editToolbarHeightConstraint.constant = 0;

    [self.toolbar setBackgroundImage:[UIImage new]
                  forToolbarPosition:UIBarPositionAny
                          barMetrics:UIBarMetricsDefault];

    [self.toolbar setShadowImage:[UIImage new]
              forToolbarPosition:UIToolbarPositionAny];

    [self favFolders]; //初期化呼び出し

    [self startRegenerateTableData];

    self.isViewDidLoaded = YES;
}

- (void)touched:(id)sender
{
}

- (void)touchedFavFolderEditButton:(id)sender
{
    FavFolderEditNavigationController *navCon = [[FavFolderEditNavigationController alloc] init];

    FavFolderEditViewController *favEditCon = [[FavFolderEditViewController alloc] init];
    [navCon pushViewController:favEditCon animated:YES];

    [[MySplitVC instance] presentViewController:navCon
                                            animated:YES
                                          completion:^{

                                          }];
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
    //[[ThManager sharedManager] updateAll:allThList];
}

- (void)refreshTabBadge
{
    NSInteger newCount = 0;
    NSMutableDictionary *thKeyDict = [NSMutableDictionary dictionary];
    for (FavFolder *folder in self.favFolders) {
        for (ThVm *thVm in folder.thVmList) {
            if (thVm.th) {
                if ([thVm.th unreadCount] <= 0 || thVm.th.lastReadTime == 0) {
                    continue;
                }
                if ([thKeyDict objectForKey:thVm.th]) {
                    continue;
                }
                [thKeyDict setObject:thVm forKey:[thVm.th threadUniqueKey]];
                newCount++;
            }
        }
    }
    if (newCount > 0) {
        [[MainVC instance] setFavTabBarBadge:[NSString stringWithFormat:@"%zd", newCount]];
    } else {
        [[MainVC instance] setFavTabBarBadge:nil];
    }
}

- (void)refreshed:(id)sender
{
    [self updateAll];
}

- (void)onThemeChanged
{
    [super onThemeChanged];
    self.toolbar.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
    //   self.shouldReloadTable = YES;
    //
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    [self.tableView setEditing:editing animated:YES];

    if (editing) {
        self.navigationItem.rightBarButtonItem = self.folderBarButton;
        self.navigationItem.rightBarButtonItems = @[ self.folderBarButton ];

        [[MainVC instance] hideTabBar];
    } else {
        self.navigationItem.rightBarButtonItems = @[ self.refreshBarButton ];
        [[MainVC instance] showTabBar];
    }

    [[MainVC instance] updateNavigationBarButtons];

    self.toolbar.hidden = !editing;
    self.editToolbarHeightConstraint.constant = editing ? 44 : 0;

    [self.toolbar layoutIfNeeded];
    [self.tableView layoutIfNeeded];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    FavFolder *folder = (FavFolder *)[self.favFolders objectAtIndex:fromIndexPath.section];
    ThVm *thVm = [folder.thVmList objectAtIndex:fromIndexPath.row];

    [folder.thVmList removeObjectAtIndex:fromIndexPath.row];

    FavFolder *addFolder = (FavFolder *)[self.favFolders objectAtIndex:toIndexPath.section];
    [addFolder.thVmList insertObject:thVm atIndex:toIndexPath.row];

    [self rebuildDictionary];
    [self startRegenerateTableDataIfVisible];
    [self saveFavoritesAsync];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    FavFolder *folder = [self.favFolders objectAtIndex:section];
    return [folder.thVmList count];
}

- (void)notifyEditFavFolders
{

    [self startRegenerateTableDataIfVisible];
}


// お気に入り管理
// Top
// - フォルダ1
// - フォルダ2
// 並び替えを考慮
//
//
- (void)addTh:(Th *)th
{
    th.isFav = YES;
    if ([self.favFolders count] > 0) {
        @synchronized(self.tableView)
        {
            FavFolder *folder = [self.favFolders objectAtIndex:0];
            ThVm *thVm = [[ThVm alloc] initWithTh:th];

            [folder.thVmList addObject:thVm];

            if (self.isViewDidLoaded) {
                [self.tableView reloadData];
            }
        }
    } else {
        //フォルダ作成
    }

    [self saveFavoritesAsync];
}

- (FavFolder *)getIdenticalFavFolder:(FavFolder *)folder
{
    FavFolder *targetFolder = nil;
    for (FavFolder *favFolder in self.favFolders) {
        if (favFolder.isTopFolder && folder.isTopFolder) {
            targetFolder = folder;
            break;
        } else if (favFolder == folder || [favFolder.name isEqualToString:folder.name]) {
            targetFolder = folder;
            break;
        }
    }

    return targetFolder;
}

- (void)addThread:(Th *)th forFolder:(FavFolder *)folder
{
    th.isFav = YES;
    FavFolder *targetFolder = [self getIdenticalFavFolder:folder];
    if (targetFolder) {
        NSArray *alternate = [NSArray arrayWithArray:targetFolder.thVmList];
        for (ThVm *thVm in alternate) {
            if (thVm.th == th) {
                return;
            }
        }

        BOOL added = [self putDictionaryWithTh:th forFolder:targetFolder];
        if (added) {
            ThVm *thVm = [[ThVm alloc] initWithTh:th];
            [targetFolder.thVmList addObject:thVm];

            [self saveFavoritesAsync];
            [self startRegenerateTableData];
        }
    }
}

- (void)addNextThread:(Th *)th base:(Th *)base
{
    // myLog(@"th = %@", th.title);
    // myLog(@"base = %@", base.title);
    BOOL hit = NO;

    if ([self.favFolders count] > 0) {

        for (FavFolder *folder in self.favFolders) {
            int index = 0;
            for (ThVm *thVm in folder.thVmList) {
                index++;
                if (thVm.th == base) {
                    myLog(@"in fav addTh title = %@", th.title);

                    BOOL added = [self putDictionaryWithTh:th forFolder:folder];
                    if (added) {
                        ThVm *thVm = [[ThVm alloc] initWithTh:th];
                        [folder.thVmList insertObject:thVm atIndex:index];
                        hit = YES;
                    }
                    break;
                }
            }
        }

    } else {
        //フォルダ作成
    }

    if (hit) {
        th.isFav = YES;
        [self saveFavoritesAsync];
        [self startRegenerateTableData];
    }
}

- (void)removeThread:(Th *)th forFolder:(FavFolder *)folder
{
    FavFolder *targetFolder = [self getIdenticalFavFolder:folder];
    if (targetFolder) {
        BOOL hit = NO;
        NSArray *alternate = [NSArray arrayWithArray:targetFolder.thVmList];
        for (ThVm *thVm in alternate) {
            if (thVm.th == th) {
                [folder.thVmList removeObject:thVm];
                [self removeEntryForTh:th forFolder:folder];
                hit = YES;
            }
        }
        if (hit) {
            [self saveFavoritesAsync];
            [self startRegenerateTableData];
        }
    }

    th.isFav = [self containsThread:th];
}

- (NSArray *)folderListForTh:(Th *)th
{
    return (NSArray *)[self.folderDictionary objectForKey:[th threadUniqueKey]];
}

- (BOOL)containsThread:(Th *)th
{
    NSMutableArray *folderList = (NSMutableArray *)[self.folderDictionary objectForKey:[th threadUniqueKey]];
    if (folderList && [folderList count] > 0) {
        return YES;
    }
    return NO;
}

- (BOOL)containsThread:(Th *)th forFolder:(FavFolder *)folder
{
    NSMutableArray *folderList = (NSMutableArray *)[self.folderDictionary objectForKey:[th threadUniqueKey]];
    if (folderList) {
        for (FavFolder *oldFavFolder in folderList) {
            if (oldFavFolder == folder || [oldFavFolder.name isEqualToString:folder.name]) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSString *)favSavePath
{
    NSString *favoritesPath = [[Env documentPath] stringByAppendingPathComponent:
                                                      @"favorites.plist"];
    return favoritesPath;
}

- (void)rebuildDictionary
{
    self.folderDictionary = [NSMutableDictionary dictionary];
    for (FavFolder *favFolder in self.favFolders) {
        for (ThVm *thVm in favFolder.thVmList) {
            [self putDictionaryWithTh:thVm.th forFolder:favFolder];
        }
    }
}

- (BOOL)putDictionaryWithTh:(Th *)th forFolder:(FavFolder *)favFolder
{
    if (self.folderDictionary == nil) {
        self.folderDictionary = [NSMutableDictionary dictionary];
    }

    NSMutableArray *folderList = (NSMutableArray *)[self.folderDictionary objectForKey:[th threadUniqueKey]];
    if (folderList) {
        for (FavFolder *oldFavFolder in folderList) {
            if (oldFavFolder == favFolder || [oldFavFolder.name isEqualToString:favFolder.name]) {
                return NO;
            }
        }

        [folderList addObject:favFolder];

    } else {
        folderList = [NSMutableArray array];
        [folderList addObject:favFolder];
        [self.folderDictionary setObject:folderList forKey:[th threadUniqueKey]];
    }

    return YES;
}
- (void)removeEntryForTh:(Th *)th forFolder:(FavFolder *)folder
{
    if (self.folderDictionary == nil) {
        self.folderDictionary = [NSMutableDictionary dictionary];
    }

    NSMutableArray *folderList = (NSMutableArray *)[self.folderDictionary objectForKey:[th threadUniqueKey]];
    if (folderList) {
        NSArray *alterate = [NSArray arrayWithArray:folderList];
        for (FavFolder *oldFavFolder in alterate) {
            if (oldFavFolder == folder) {
                [folderList removeObject:folder];
                //[self removeEntryForTh:th forFolder:folder];
            }
        }
    }
}

- (void)loadFavorites
{

    NSString *favoritesPath = [self favSavePath];

    NSDictionary *rootDictionary = [[NSDictionary alloc] initWithContentsOfFile:favoritesPath];
    self.folderDictionary = [NSMutableDictionary dictionary];

    _favFolders = [NSMutableArray array];
    if (rootDictionary) {

        NSArray *folderList = [rootDictionary objectForKey:@"FolderList"];
        BOOL first = YES;
        for (NSDictionary *entry in folderList) {
            NSString *name = [entry objectForKey:@"name"];
            FavFolder *folder = [[FavFolder alloc] init];
            if (first)
                folder.isTopFolder = YES;
            else
                first = NO;
            folder.name = name ? name : @"No Name";
            [self.favFolders addObject:folder];

            NSArray *urlList = [entry objectForKey:@"list"];
            for (NSString *url in urlList) {
                Th *th = [[ThManager sharedManager] registerTh:[Th thFromUrl:url] canLoadFile:YES];
                if (th) {
                    th.isFav = YES;

                    ThVm *thVm = [[ThVm alloc] initWithTh:th]; //[self genThVm:th];
                    thVm.showFavState = NO;
                    [folder.thVmList addObject:thVm];
                    [self putDictionaryWithTh:th forFolder:folder];
                }
            }
        }
    }

    if ([self.favFolders count] == 0) {
        FavFolder *folder = [[FavFolder alloc] init];
        folder.name = @"Top";
        folder.isTopFolder = YES;

        [self.favFolders addObject:folder];
    }

    return;
}

- (void)saveFavoritesAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      [self saveFavorites];
    });
}

- (void)saveFavorites
{
    NSMutableDictionary *rootDictionary = [NSMutableDictionary dictionary];

    NSMutableArray *topLevelList = [NSMutableArray array];
    for (FavFolder *folder in self.favFolders) {
        NSMutableArray *mutable = [NSMutableArray array];
        for (ThVm *thVm in folder.thVmList) {
            [mutable addObject:[thVm.th threadUrl]];
        }

        NSDictionary *folderEntry = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      folder.name, @"name", mutable, @"list",
                                                      @"YES", @"open", @"folder", @"type", nil];

        [topLevelList addObject:folderEntry];
    }

    [rootDictionary setObject:topLevelList forKey:@"FolderList"];
    [rootDictionary setObject:[NSNumber numberWithInteger:1] forKey:@"version"];

    NSString *favoritesPath = [self favSavePath];
    [rootDictionary writeToFile:favoritesPath atomically:NO];
}

//同期構成受け取りFavFoldersの適用
- (void)applySyncFavFolders:(NSMutableArray *)array
{
    @synchronized(self)
    {
        if (self.tableView) {
            @synchronized(self.tableView)
            {
                [self _copyThVmHeightOfSameTh:array];
                self.favFolders = array;
                [self rebuildDictionary];
                [self startRegenerateTableDataIfVisible];
            }
        } else {
            [self _copyThVmHeightOfSameTh:array];
            self.favFolders = array;
        }
    }

    [self saveFavoritesAsync];
}

- (void)_copyThVmHeightOfSameTh:(NSArray *)favFolders
{
    NSMutableDictionary *urlToThVmDictinoary = [NSMutableDictionary dictionary];
    for (FavFolder *favFolder in self.favFolders) {
        for (ThVm *thVm in favFolder.thVmList) {
            [urlToThVmDictinoary setObject:thVm forKey:[thVm.th threadUniqueKey]];
        }
    }

    for (FavFolder *favFolder in favFolders) {
        for (ThVm *thVm in favFolder.thVmList) {
            ThVm *oldThVm = [urlToThVmDictinoary objectForKey:[thVm.th threadUniqueKey]];
            if (oldThVm) {
                thVm.cellHeight = oldThVm.cellHeight;
            }
        }
    }
}

// @override
- (void)onTabSelected:(UITabBarItem *)tabItem tapTwice:(BOOL)tapTwice
{
    if (tapTwice) {
    }
}

- (NSArray *)getThVmList
{
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (FavFolder *folder in self.favFolders) {
        [mutableArray addObjectsFromArray:folder.thVmList];
    }
    myLog(@"fav %lu", (unsigned long)[mutableArray count]);
    return mutableArray;
}

// @override
- (UITableView *)thisTableView
{
    return self.tableView;
}


- (ThVm *)thVmForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavFolder *folder = [self.favFolders objectAtIndex:indexPath.section];
    return [folder.thVmList objectAtIndex:indexPath.row];
}

// ------------------------ ThListSection ---------------------------

- (NSMutableArray *)sectionList
{
    return self.favFolders;
}

- (NSString *)sectionTitle:(NSObject *)sectionObject
{
    FavFolder *favFolder = (FavFolder *)sectionObject;
    return favFolder.name;
}

- (NSMutableArray *)thVmListInSection:(NSObject *)sectionObject
{
    FavFolder *favFolder = (FavFolder *)sectionObject;
    return favFolder.thVmList;
}

// ------------------------ end of ThListSection ---------------------------

- (IBAction)deleteBarButtonAction:(id)sender
{
    NSMutableArray *cellIndicesToBeDeleted = [[NSMutableArray alloc] init];

    NSMutableDictionary *removeRowsDict = [NSMutableDictionary dictionary];

    NSArray *indexPathes = [self.tableView indexPathsForSelectedRows];
    for (NSIndexPath *indexPath in indexPathes) {
        //FavFolder* folder = [self.favFolders objectAtIndex:indexPath.section];
        NSMutableArray *removeRows = [removeRowsDict objectForKey:[NSNumber numberWithInteger:indexPath.section]];
        if (removeRows) {
            [removeRows addObject:[NSNumber numberWithInteger:indexPath.row]];
        } else {
            NSMutableArray *rows = [NSMutableArray array];
            [rows addObject:[NSNumber numberWithInteger:indexPath.row]];
            [removeRowsDict setObject:rows forKey:[NSNumber numberWithInteger:indexPath.section]];
        }
    }

    int i = 0;
    for (FavFolder *favFolder in self.favFolders) {
        NSArray *removeRows = [removeRowsDict objectForKey:[NSNumber numberWithInteger:i]];
        if (removeRows) {
            NSMutableIndexSet *removeIndexSet = [NSMutableIndexSet indexSet];
            for (NSNumber *number in removeRows) {
                NSIndexPath *p = [NSIndexPath indexPathForRow:number.integerValue inSection:i];
                [cellIndicesToBeDeleted addObject:p];
                [removeIndexSet addIndex:number.integerValue];
            }
            if (removeIndexSet.count > 0)
                [favFolder.thVmList removeObjectsAtIndexes:removeIndexSet];
        }
        i++;
    }

    [self.tableView deleteRowsAtIndexPaths:cellIndicesToBeDeleted
                          withRowAnimation:UITableViewRowAnimationLeft];

    [self rebuildDictionary];
    //[self startRegenerateTableDataIfVisible];

    [self saveFavoritesAsync];
}

- (IBAction)onDoneAction:(id)sender
{
    [self setEditing:NO animated:YES];
}
@end
