#import <QuartzCore/QuartzCore.h>
#import <SDImageCache.h>

#import "ResTableViewCell.h"
#import "TextUtils.h"
#import "ThUpdater.h"
#import "ResVmList.h"
#import "Th+ParseAdditions.h"
#import "AppDelegate.h"
#import "ThemeManager.h"
#import "ThManager.h"
#import "HistoryVC.h"
#import "FavVC.h"
#import "GestureManager.h"
#import "GestureEntry.h"
#import "TopWindow.h"
#import "ResNodeBase.h"
#import "Env.h"
#import "BaseModalNavigationVC.h"
#import "BaseTableVC.h"
#import "ResTransaction.h"
#import "PostNaviVC.h"
#import "PostConfirmVC.h"
#import "NGManager.h"

#import "MySplitVC.h"
#import "ResTableView.h"
#import "AutoScrollCalculator.h"
#import "ResVCActionMenu.h"

#define IS_IPHONE (!IS_IPAD)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone)

#import "ResVC.h"
#import "ResVC+Touch.h"

static NSString *const ReadMarkCellIdentifier = @"ReadMarkCellIdentifier";
static NSString *const LastCellIdentifier = @"LastCellIdentifier";

#pragma mark - LabelCell

//  スレッドの最後とここまで読んだ共通
@interface LabelCell : UITableViewCell {
    NSString *reuseID;
}
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UILabel *mainLabel;
@property (nonatomic) UIView *separator;

@end

@implementation LabelCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{

    UIColor *backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    UIColor *foregroundColor = [[ThemeManager sharedManager] colorForKey:ThemeResPageTintColor];

    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        reuseID = reuseIdentifier;
        self.backgroundColor = [UIColor clearColor];

        UILabel *nameLabel = [[UILabel alloc] init];
        self.nameLabel = nameLabel;
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.textColor = foregroundColor;
        self.nameLabel.backgroundColor = backgroundColor;
        self.nameLabel.font = [UIFont systemFontOfSize:12.f];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView addSubview:self.nameLabel];

        UIView *separator = [[UIView alloc] init];
        separator.translatesAutoresizingMaskIntoConstraints = NO;
        self.separator = separator;

        [self.contentView addSubview:separator];

        UILabel *mainLabel = [[UILabel alloc] init];
        self.mainLabel = mainLabel;
        mainLabel.textColor = foregroundColor;
        mainLabel.backgroundColor = backgroundColor;
        mainLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18.0f];
        mainLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView addSubview:mainLabel];
        NSDictionary *views = NSDictionaryOfVariableBindings(nameLabel, mainLabel, separator);

        if (reuseID == ReadMarkCellIdentifier) {
            // self.nameLabel.textAlignment = NSTextAlignmentLeft;
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[nameLabel]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:views];
            [self.contentView addConstraints:constraints];
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[separator]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:views];
            [self.contentView addConstraints:constraints];
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[nameLabel]|"]
                                                                  options:0
                                                                  metrics:nil
                                                                    views:views];
            [self.contentView addConstraints:constraints];

            constraints = [NSLayoutConstraint constraintsWithVisualFormat:
                                                  [NSString stringWithFormat:@"V:[separator(==%f)]|", thinLineWidth]
                                                                  options:0
                                                                  metrics:nil
                                                                    views:views];
            [self.contentView addConstraints:constraints];
        }

        if (reuseID == LastCellIdentifier) {
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[nameLabel]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:views];
            [self.contentView addConstraints:constraints];

            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mainLabel]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:views];
            [self.contentView addConstraints:constraints];

            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[nameLabel]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:views];
            [self.contentView addConstraints:constraints];
        }
    }
    return self;
}

@end

#pragma mark - ResVC

@interface ResVC ()

@property (nonatomic) ResVmList *resVmList;
@property (nonatomic) ResVmList *prevResVmList;
@property (nonatomic) NSInteger readMarkNumber;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic) Th *loadedTh;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) BOOL stability;
@property (nonatomic) BOOL isViewDidAppeard;
@property (nonatomic) LabelCell *lastCell;
@property (nonatomic) LabelCell *readMarkCell;
@property (nonatomic) BOOL isReleaseForUpdateReady;
@property (nonatomic) BOOL isDoingBackgroundParse;
@property (nonatomic) BOOL inTouch;

@property (nonatomic) AutoScrollCalculator *autoScrollCalculator;

@property (nonatomic) GestureManager *gesture;
@end

@implementation ResVC

- (void)awakeFromNib
{
    [super awakeFromNib];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        //self.clearsSelectionOnViewWillAppear = NO;
        //self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)dealloc
{
    NSLog(@"■■■■ dealloc ResVC ■■■■ %@", self.th ? self.th.title : @"null");
    @try {
        [self.th removeObserver:self forKeyPath:@"isUpdating"];
    } @catch (NSException *anExp) {
        
    }
    
    @try {
        [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
    } @catch( NSException* anE) {
    }
    
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    } @catch( NSException* anE) {
    }

    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    } @catch( NSException* anE) {
    }

    @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:MYO_WINDOW_EVENT_NOTIFICATION object:nil];
    } @catch( NSException* anE) {
        
    }
    
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;

    [self detach];
}

/* ResVC と Thを切り離す */
- (void)detach
{
    self.currentCellTag++;
    if (self.th) {
        if (![[MyNavigationVC instance] containsResVCForTh:self.th]) {
            NSLog(@"reslist released ");
            [self.th clearResponses];
        }

        @try {
            [self.th removeObserver:self forKeyPath:@"isUpdating"];
        } @catch (NSException *anExp) {

        }
    }

    if (self.resVmList) {
          [self.resVmList removeAllObjects];
          self.resVmList = nil;
    }

    self.th = nil;
    self.loadedTh = nil;
}

- (void)initView
{

    self.searchContainerView.hidden = YES;
    self.searchContainerView.alpha = 0.f;

    self.gesture = [[GestureManager alloc] init];
    self.currentCellTag = 2;
    self.stability = NO;

    self.navBorderHeightConstraint.constant = .5;

    self.popupBackgroundView = [[UIView alloc] init];
    self.popupBackgroundView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.3];

    self.toolbarSeparatorHeightConstraint.constant = 0.5;
    [self.toolbarSeparator setNeedsUpdateConstraints];

    self.progressBar.hidden = NO;
    [self.view setNeedsUpdateConstraints];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView initFastTableView];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self.tableView registerClass:[ResTableViewCell class] forCellReuseIdentifier:@"ResTableViewCell"];

    [[self tableView] registerClass:[LabelCell class] forCellReuseIdentifier:ReadMarkCellIdentifier];
    [[self tableView] registerClass:[LabelCell class] forCellReuseIdentifier:LastCellIdentifier];

    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];

    self.navigationBar.shadowImage = [UIImage new];
    //self.navigationBar.backgroundColor = [UIColor colorWithHue:0 saturation:1.f brightness:0.7 alpha:0.5];
    //    [UIColor color]
    self.navigationBar.translucent = YES;

    [self.toolbar setBackgroundImage:[UIImage new]
                  forToolbarPosition:UIBarPositionAny
                          barMetrics:UIBarMetricsDefault];

    [self.toolbar setShadowImage:[UIImage new]
              forToolbarPosition:UIToolbarPositionAny];

    if ([MySplitVC instance].isTabletMode) {
        NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self.toolbar items]];
        [items removeObjectAtIndex:1];
        [items removeObjectAtIndex:0];
        [self.toolbar setItems:items];
    }
}

// @overriide
- (UITableView *)thisTableView
{
    return self.tableView;
}

- (void)fixTitleLabelFrame
{
    CGFloat statusBarHeight = [Env getStatusBarHeight];
    self.titleLabel.frame = CGRectMake(5, statusBarHeight > 10 ? statusBarHeight - 3 : 0, self.view.frame.size.width - 10, 20);
    [self.titleLabel setNeedsDisplay];
}

- (void)loadThread:(Th *)th complete:(void (^)(void))completionBlock
{
    if (self.th && self.th != th) {
        @try {
            [self.th removeObserver:self forKeyPath:@"isUpdating"];
        } @catch (NSException *e) {
        }
    }

    //  self.title = th.title;
    //self.navigationItem.title = th.title;
    self.th = th;
}

// @override
- (void)startRegenerateTableData:(BOOL)startBackgroundParse
{
    self.stability = NO;
    self.currentCellTag++;
    //    self.tableView.initialWidth = self.tableView.bounds.size.width;
    NSLog(@"GGGGABCD = %d", startBackgroundParse);
    [super startRegenerateTableData:startBackgroundParse];
}

- (void)viewDidLoad
{
    self.tableView.scrollsToTop = YES;

    self.titleLabel = [[UILabel alloc] init];
    [self fixTitleLabelFrame]; //ラベルの大きさと位置を調整

    self.searchHistoryTableView.scrollsToTop = NO;

    // プルリフレッシュ用のViewを、tableViewのサブViewとして追加する。
    self.pullRefreshView = [[UIView alloc] init];
    self.pullRefreshView.backgroundColor = [UIColor clearColor];
    self.pullRefreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.pullRefreshView addSubview:self.pullRefreshButton];

    self.autoScrollCalculator = [[AutoScrollCalculator alloc] init];
    self.autoScrollCalculator.tableView = self.tableView;
    self.autoScrollCalculator.autoScrollButton = self.autoScrollButton; //valueForKey:@"view"];
    self.autoScrollCalculator.toolbar = self.toolbar;

    self.titleLabel.font = [UIFont boldSystemFontOfSize:11.75];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.8;

    self.automaticallyAdjustsScrollViewInsets = NO;

    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowEvent:)
                                                 name:MYO_WINDOW_EVENT_NOTIFICATION
                                               object:[[[UIApplication sharedApplication] delegate] window]];

    [self initView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    //navigationItemのtitleViewをLabelに置き換える
    [self.navigationBar addSubview:self.titleLabel];

    //    AppDelegate* dele = [UIApplication sharedApplication].delegate;
    //    // Enabling iOS 7 screen-edge-pan-gesture for pop action
    //if ([dele.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
    //dele.navigationController.interactivePopGestureRecognizer.delegate = nil;
    //}
    //[self.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

    [super viewDidLoad];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [self.view convertRect:[[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.searchContainerBottomConstraint.constant = keyboardFrame.size.height;
    [UIView animateWithDuration:duration
                     animations:^{
                       [self.view layoutIfNeeded];
                       [self.searchContainerView layoutIfNeeded];
                     }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.searchContainerBottomConstraint.constant = 0;
    [UIView animateWithDuration:duration
                     animations:^{
                       [self.view layoutIfNeeded];
                       [self.searchContainerView layoutIfNeeded];
                     }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self callViewWillDisappear:NO];
}

- (void)callViewWillDisappear
{
    [self callViewWillDisappear:YES];
}

- (void)callViewWillDisappear:(BOOL)manual
{
    //[Env saveLastThread:nil];
        if (manual) {
            self.currentCellTag++;
        }
    self.downCell = nil;
    self.canTap = NO;

    [self closeSearchMode:nil];

    if ([self isViewVisible] && self.isLoaded && self.isViewDidAppeard) {
        NSArray *indexPathList = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *path in indexPathList) {
            ResVm *resVm = [self.resVmList resVmAtIndex:path.row];
            if (resVm) {
                self.th.reading = resVm.originResNumber;
                break;
            }
        }

        CGFloat contentOffsetWidthWindow = self.tableView.contentOffset.y + self.tableView.bounds.size.height;
        BOOL leachToBottom = contentOffsetWidthWindow >= self.tableView.contentSize.height + self.tableView.contentInset.bottom - 20;

        if (leachToBottom) {
            self.th.reachedLastReading = self.th.localCount;
            self.th.reading = self.th.localCount;
            if (self.th.read != self.th.localCount) {
                //   myLog(@"save when dissapear by leachToBottom: %lu", (unsigned long)self.th.reading);

                self.th.read = self.th.localCount;
            }
        }

        if (self.th.reading > self.th.read) {
            self.th.read = self.th.reading;
        }
    }

    [[ThManager sharedManager] saveThAsync:self.th];
}

// @override
- (void)onOrientationChanged:(CGFloat)width
{
    if ([self isViewVisible]) {
        [self fixTitleLabelFrame];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadForRedraw];
      });
    });
}

// @Override
- (void)onThemeChanged
{

    [super onThemeChanged];

    ThemeManager *tm = [ThemeManager sharedManager];

    self.view.tintColor = [tm colorForKey:ThemeResPageTintColor];

    [self.view setBackgroundColor:[tm colorForKey:ThemeUnderneathBackgroundColor]];

    self.navigationBar.backgroundColor = [tm colorForKey:ThemeResPageTitleBarBackgroundColor];
    self.titleLabel.textColor = [tm colorForKey:ThemeNormalColor]; //文字色

    self.view.backgroundColor = [tm colorForKey:ThemeUnderneathBackgroundColor];

    UIImage *backgroundImage = [tm backgroundImageForKey:ThemeResPageBackgroundImage];
    self.backgroundImageView.image = backgroundImage;
    self.backgroundImageView.contentMode = UIViewContentModeCenter;
    self.backgroundImageView.backgroundColor = [tm colorForKey:ThemeResPageBackgroundColor];

    self.tableView.backgroundColor = [tm colorForKey:ThemeResListBackgroundColor];

    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [[ThemeManager sharedManager] changeTableViewStyle:self.tableView];

    [self.titleLabel setTextColor:[tm colorForKey:ThemeResPageTitleColor]];

    self.toolbar.backgroundColor = [tm colorForKey:ThemeResPageToolBarBackgroundColor];

    self.toolbarSeparator.backgroundColor = [tm colorForKey:ThemeResPageToolBarBorderColor];

    self.navBorderView.backgroundColor = [tm colorForKey:ThemeResPageTitleBarBorderColor];

    self.currentCellTag++;

    for (Res *res in self.th.responses) {
        res.ngChecked = NO;
    }

    self.th.resNGInspector = [[NGManager sharedManager] createResNGInspectorForTh:self.th];

    NSArray *array = [NSArray arrayWithArray:self.resVmList.serializedResVmArray];
    for (ResVm *resVm in array) {
        [resVm releaseThumbnails];
        resVm.thumbnailTotalHeight = 0;
        ;
    }
    //[self.tableView reloadData];
    //[self startBackgroundParse];

    if ([self isViewVisible]) {
        [self.tableView reloadForRedraw];
    } else {
        [self startRegenerateTableDataIfVisible];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    for (ResVm *resVm in self.resVmList.serializedResVmArray) {
        [resVm releaseThumbnails];
    }

    SDImageCache *cache = [SDImageCache sharedImageCache];
    [cache clearMemory];

    self.prevResVmList = nil;
}

// viewWillAppearが呼ばれるときは、指定されたスレッドを開くが、
// すでに開いているときは、何もしない。
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.cannotBack = YES;

    if (self.pullRefreshView.superview) {
        [self.pullRefreshView removeFromSuperview];
    }

    self.pullRefreshButton.frame = CGRectMake(0, 0, self.view.bounds.size.width, 50);

    [self.navigationBar setNeedsDisplay];

    self.isViewDidAppeard = NO;

    self.popupBackgroundView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.popupBackgroundView setNeedsDisplay];

    MyNavigationVC *parentNaviVC = [[MySplitVC instance] resParentMyNavigationVC];
    [parentNaviVC setNavigationBarHidden:YES animated:YES];

    [self fixTitleLabelFrame];

    self.tableView.stability = NO;
 
    if (self.th && self.loadedTh == self.th) {

        //ios8用にスクロールポジションを再度設定する
        @synchronized(self.tableView)
        {
            NSInteger row = [self.resVmList rowAtOriginResNumber:self.th.reading];
            if (self.th.reachedLastReading > 0) {
                if (self.th.reachedLastReading == self.th.localCount) {
                    row = [self rowCount] - 1; //最後を下に合わせる
                } else {
                    //ここまで読んだマーク画面上に合わせる
                    row = -1 + [self.resVmList rowAtOriginResNumber:self.th.reachedLastReading];
                }
            } else {
                row = [self.resVmList rowAtOriginResNumber:self.th.reading];
            }

            //[self.tableView reloadData];

            [self.tableView reloadTableViewAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                                            withOffset:0
                                            completion:^{
                                              [self.tableView startBackgroundParse];
                                              self.isLoaded = YES;
                                            }];
        }

        return;
    }

    self.loadedTh = self.th;

    [Env saveLastThread:[self.th threadUrl]];

    self.titleLabel.attributedText = [self generateTitleAttributeString:self.th.title];
    self.isLoaded = NO;
    self.stability = NO;

    self.currentCellTag++;

    self.prevResVmList = self.resVmList;
    if (self.prevResVmList) {
        __weak ResVC *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
          [NSThread sleepForTimeInterval:3];
          //            ResVmList* releaseVmList = weakSelf.prevResVmList;
          //            if (releaseVmList) {
          //                [releaseVmList removeAllObjects];
          //            }
          weakSelf.prevResVmList = nil;
        });
    }
    self.resVmList = [[ResVmList alloc] init];

    if (self.th.tempHighlightResNumber > 0) {
        self.resVmList.highlightResNumber = self.th.tempHighlightResNumber;
        self.th.tempHighlightResNumber = 0;
    }

    self.th.resNGInspector = [[NGManager sharedManager] createResNGInspectorForTh:self.th];

    self.resVmList.th = self.th;

    self.readMarkNumber = self.th.read;
    [self.resVmList changeReadMarkNumber:self.th.read];

    NSUInteger unreadCount = self.th.localCount - self.resVmList.lastReadNumber;
    [self.readMarkCell.nameLabel setText:[NSString stringWithFormat:@"%@ 新着: %tu", unreadCount > 0 ? @"↓" : @"", unreadCount]];
    [self.readMarkCell setNeedsDisplay];

    if ([Env getTreeModeConfig] == 1) {
        [Env setTreeEnabled:YES];
    } else if ([Env getTreeModeConfig] == 2) {
        [Env setTreeEnabled:NO];
    }

    @synchronized(self.tableView)
    {
        [self.resVmList setTreeMode:[Env getTreeEnabled]];
        [self.resVmList addResList:self.th.responses];

        // スクロール位置を決定
        NSInteger row = [self.resVmList rowAtOriginResNumber:self.th.reading];
        if (self.th.reachedLastReading > 0) {
            if (self.th.reachedLastReading == self.th.localCount) {
                row = [self rowCount] - 1; //最後を下に合わせる
            } else {
                //ここまで読んだマークを画面上に合わせる
                row = -1 + [self.resVmList rowAtOriginResNumber:self.th.reachedLastReading];
            }
        } else {
            row = [self.resVmList rowAtOriginResNumber:self.th.reading];
        }

        [self.tableView reloadData];
        [self.tableView reloadTableViewAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                                        withOffset:0
                                        completion:^{
                                          self.stability = NO;
                                          myLog(@"starting background parse");
                                          [self.tableView startBackgroundParse];
                                          self.isLoaded = YES;
                                        }];
    }

    [self.th addObserver:self forKeyPath:@"isUpdating" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.cannotBack = NO;
    self.isViewDidAppeard = YES;
    self.navigationBar.translucent = YES;
    [self.tableView flashScrollIndicators];

    SDImageCache *cache = [SDImageCache sharedImageCache];
    [cache clearMemory];

    self.navigationController.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeResPageTintColor];
}

- (NSAttributedString *)generateTitleAttributeString:(NSString *)title
{

    if (title == nil) {
        title = @"";
    }

    NSString *rawTitle = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc] init];
    ThemeManager *tm = [ThemeManager sharedManager];
    UIColor *accentColor = [tm colorForKey:ThemeResPageTintColor];
    UIColor *normalColor = [tm colorForKey:ThemeNormalColor];
    //[tm colorForKey:ThemeMainBackgroundColor];

    NSArray *pairs = @[ @"【", @"】", @"[", @"]", @"「", @"」" ];

    for (int i = 0; i < pairs.count / 2; i++) {
        NSInteger termBeginIndex = 0;
        if ([rawTitle hasPrefix:[pairs objectAtIndex:i]]) {
            NSRange range = [rawTitle rangeOfString:[pairs objectAtIndex:i + 1]];
            if (range.location != NSNotFound) {

                NSString *prefixString = [rawTitle substringToIndex:range.location + 1];
                termBeginIndex = range.location;
                [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                                    initWithString:prefixString
                                                        attributes:@{
                                                            NSForegroundColorAttributeName : accentColor
                                                        }]];

                rawTitle = [rawTitle substringFromIndex:range.location + 1];
                break;
            }
        }
    }

    BOOL hit = NO;
    for (int i = 0; i < pairs.count / 2; i++) {

        if ([rawTitle hasSuffix:[pairs objectAtIndex:i + 1]]) {
            NSRange range = [rawTitle rangeOfString:[pairs objectAtIndex:i] options:NSBackwardsSearch];
            NSInteger location = range.location;
            if (location != NSNotFound) {

                NSInteger endLoc = range.location == 0 ? [rawTitle length] : range.location;
                NSString *middleText = [rawTitle substringToIndex:endLoc];

                [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                                    initWithString:middleText
                                                        attributes:@{
                                                            NSForegroundColorAttributeName : normalColor
                                                        }]];
                if (range.location != 0) {
                    NSString *endText = [rawTitle substringFromIndex:range.location];
                    [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:endText
                                                            attributes:@{
                                                                NSForegroundColorAttributeName : accentColor
                                                            }]];
                }
                hit = YES;
                break;
            }
        }
    }

    if (hit == NO) {
        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:rawTitle
                                                attributes:@{
                                                    NSForegroundColorAttributeName : normalColor
                                                }]];
    }
    return mutable;
}

- (void)requestUpdateForPostSuccess
{
    [self update];
}

- (void)update
{
    MyNavigationVC *myNavigationViewController = [MyNavigationVC instance];

    ResTransaction *man = [[ResTransaction alloc] init];
    man.isPushDisabled = YES;

    man.th = self.th;
    if ([man startOpenThTransaction]) {
        //成功
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (self == nil) return;
    
    __weak ResVC *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      if (weakSelf.pullRefreshView.superview) {
          if (object == weakSelf.tableView && [keyPath isEqualToString:@"contentOffset"]) {
              CGFloat contentOffsetWidthWindow = weakSelf.tableView.contentOffset.y + weakSelf.tableView.bounds.size.height;
              BOOL exceed = contentOffsetWidthWindow > weakSelf.tableView.contentSize.height + weakSelf.tableView.contentInset.bottom;
              if (!exceed) {
                  [weakSelf.pullRefreshView removeFromSuperview];
              }
          }
      }

      Th *th = object;
      if (weakSelf.th == th && [keyPath isEqual:@"isUpdating"]) {
          if (th.isUpdating == NO && weakSelf.isLoaded && weakSelf.isViewDidAppeard) {

              weakSelf.currentCellTag++;

              weakSelf.resVmList.th = weakSelf.th;
              //self.resVmList.tag = self.currentCellTag;

              [weakSelf.resVmList changeReadMarkNumber:th.read];
              NSUInteger unreadCount = weakSelf.th.localCount - weakSelf.resVmList.lastReadNumber;
              NSString *newStr = [NSString stringWithFormat:@"%@ 新着: %tu", unreadCount > 0 ? @"↓" : @"", unreadCount];
              [weakSelf.readMarkCell.nameLabel setText:newStr];
              @synchronized(weakSelf.tableView)
              {
                  [weakSelf.resVmList addResList:th.responses];

                  [weakSelf.tableView reloadForRedraw];
              }
          }
      }
    });
}

#pragma mark - ジェスチャー
- (NSArray *)getGestureItems
{
    __weak ResVC *weakSelf = self;

    NSMutableArray *gestureItems = [NSMutableArray array];

    GestureEntry *gestureItem = [[GestureEntry alloc] init];
    gestureItem.nameGetter = ^{
      return @"戻る";
    };
    gestureItem.directions = [[NSArray alloc] initWithObjects:DIRECTION_RIGHT, nil];
    gestureItem.completionBlock = ^{
      if (self.cannotBack) {

      } else if (weakSelf.currentPopupEntry) {
          [self closeOnePopupEntry:nil oneMode:YES];
      } else if (weakSelf.isLoaded) {
          [[MyNavigationVC instance] popMyViewController];
      }
    };
    [gestureItems addObject:gestureItem];

    gestureItem = [[GestureEntry alloc] init];
    gestureItem.nameGetter = ^{
      return @"進む";
    };
    gestureItem.directions = [[NSArray alloc] initWithObjects:DIRECTION_LEFT, nil];
    // gestureItem.isEnabled = ^{ return (weakSelf.nextViewController != nil); };
    gestureItem.completionBlock = ^{
      if (weakSelf) {
          MyNavigationVC *myNavigationViewController = [MyNavigationVC instance];
          [myNavigationViewController pushNexViewController];
      }
    };
    [gestureItems addObject:gestureItem];

    gestureItem = [[GestureEntry alloc] init];
    gestureItem.nameGetter = ^{
      return @"更新";
    };
    gestureItem.isEnabled = ^{
      BOOL enabled = weakSelf.th.isUpdating == NO;
      return enabled;
    };
    gestureItem.directions = [[NSArray alloc] initWithObjects:DIRECTION_RIGHT, DIRECTION_DOWN, DIRECTION_LEFT, nil];
    gestureItem.completionBlock = ^{
      [weakSelf update];
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
        [weakSelf scrollToBottom];
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
      if (weakSelf.currentPopupEntry) {
          [weakSelf tableViewScrollToTop:weakSelf.currentPopupEntry.tableView animated:NO];
      } else {
          [weakSelf scrollToTop];
      }
    };
    [gestureItems addObject:gestureItem];

    gestureItem = [[GestureEntry alloc] init];
    gestureItem.nameGetter = ^{
      return [self.resVmList getTreeMode] ? @"レス順" : @"ツリー";
    };
    gestureItem.isEnabled = ^{
      return YES;
    };
    gestureItem.directions = [[NSArray alloc] initWithObjects:DIRECTION_RIGHT, DIRECTION_LEFT, DIRECTION_DOWN, nil];
    gestureItem.completionBlock = ^{
      [weakSelf toggleTreeMode];
    };
    [gestureItems addObject:gestureItem];

    return gestureItems;
}

- (void)scrollToBottom
{
    if (self.currentPopupEntry) {
        [self.currentPopupEntry.tableView scrollsToBottom];
    } else {
        if (self.resVmList.readMarkRow > 0) {
            NSArray *indexPathList = [self.tableView indexPathsForVisibleRows];
            for (NSIndexPath *path in indexPathList) {
                if (path.row < self.resVmList.readMarkRow) {
                    [self.tableView reloadTableViewAtIndexPath:[NSIndexPath indexPathForRow:self.resVmList.readMarkRow inSection:0]
                                                    withOffset:0
                                                    completion:nil];
                    return;
                }
                break;
            }
        }

        [self.tableView scrollsToBottom];
    }
}

- (void)scrollToTop
{
    NSInteger targetRow = 0; 
    if (self.resVmList.readMarkRow > 0) {
        NSArray *indexPathList = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *path in indexPathList) {
            if (self.resVmList.readMarkRow < path.row) {
                targetRow = self.resVmList.readMarkRow;
            }
            break;
        }
    }

    [self.tableView reloadTableViewAtIndexPath:[NSIndexPath indexPathForRow:targetRow inSection:0]
                                    withOffset:0
                                    completion:nil];
}

- (void)windowEvent:(NSNotification *)notification
{
    if (![self isViewVisible] || self.isLoaded == NO || self.isSearchMode) {
        return;
    }

    UIEvent *event = (id)notification.userInfo;
    NSSet *touches = [event allTouches];

    if ([touches count] != 1) {
        return;
    }

    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self.view];

    CGPoint posInTable = [touch locationInView:self.tableView];

    CGRect b = self.tableView.bounds;
    CGRect bounds = CGRectMake(b.origin.x, b.origin.y, b.size.width, b.size.height - self.tableView.contentInset.bottom);

    BOOL touchOnTable = (CGRectContainsPoint(bounds, posInTable));

    UIView *autoScrollView = [self.autoScrollButton valueForKey:@"view"];
    CGRect autoScrollRect = autoScrollView.bounds;
    autoScrollRect = CGRectMake(autoScrollRect.origin.x - 20, autoScrollRect.origin.y, autoScrollRect.size.width + 50, autoScrollRect.size.height + 40);

    CGPoint posInAutoScrollButton = [touch locationInView:autoScrollView];
    BOOL touchOnItem = (CGRectContainsPoint(autoScrollRect, posInAutoScrollButton));

    switch (touch.phase) {
    case UITouchPhaseBegan:
        self.inTouch = touchOnTable;
        [self.gesture touchesBegan:pos withEvent:event];

        if (touchOnTable == NO || [MySplitVC instance].isActionMenuOpen) { //ジェスチャーのスタート地点はテーブル内に限定
            [self.gesture cancel];
        }

        if (![MySplitVC instance].isActionMenuOpen) {
            if (touchOnTable) {
                [self handleTouchBeganEvent:touch];
            } else {
                [self.autoScrollCalculator onTouchBegan:touchOnItem point:posInAutoScrollButton];
            }
        }

        break;
    case UITouchPhaseMoved:
        [self.gesture touchesMoved:pos withEvent:event];
        if ([self isViewVisible] && [self.gesture isGestureStarted]) {
            GestureEntry *showingGestureItem = nil;
            if (self.currentPopupEntry) {
                if (self.currentPopupEntry.tableView.scrollEnabled) {
                    self.currentPopupEntry.tableView.scrollEnabled = NO;
                }
            } else if (self.tableView.scrollEnabled) {
                self.tableView.scrollEnabled = NO;
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

        [self.autoScrollCalculator onTouchMove:posInAutoScrollButton];
        [self handleTouchMovedEvent:touch];

        break;

    case UITouchPhaseEnded: {
        self.inTouch = NO;
        //ジェスチャーによってスクロールが止まっていたのを解除
        if (self.currentPopupEntry) {
            if (self.currentPopupEntry.shouldScrollEnabled) {
                self.currentPopupEntry.tableView.scrollEnabled = YES;
            }
        } else {
            self.tableView.scrollEnabled = YES;
        }

        if (self.isReleaseForUpdateReady) {
            self.isReleaseForUpdateReady = NO;
            if (self.pullRefreshView.superview) {
                [self.pullRefreshButton setTitle:@"  更新中・・・  " forState:UIControlStateNormal];
                [UIView animateWithDuration:0.3
                    delay:0.0
                    options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{
                      self.pullRefreshView.alpha = 0.0;
                    }
                    completion:^(BOOL finished) {
                      [self.pullRefreshView removeFromSuperview];
                      self.pullRefreshView.alpha = 1.0;
                    }];
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              [NSThread sleepForTimeInterval:0.25];
              dispatch_sync(dispatch_get_main_queue(), ^{
                [self update];
              });
            });

            return;
        }

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

        [self.autoScrollCalculator onTouchEnd];
        [self handleTouchEndedEvent:touch];

        AppDelegate *app = [UIApplication sharedApplication].delegate;
        [app.window dismissGestureInfo];
    } break;

    case UITouchPhaseCancelled: {
        self.inTouch = NO;
        [self.gesture touchesEnded:pos withEvent:event];
        AppDelegate *app = [UIApplication sharedApplication].delegate;
        [app.window dismissGestureInfo];
        [self handleTouchCanceledEvent:touch];

        [self.autoScrollCalculator onTouchEnd];

    } break;
    default:
        break;
    }
}

- (void)viewWillLayoutSubviews
{
    CGFloat statusBarHeight = [Env getStatusBarHeight]; //

    [self fixTitleLabelFrame];

    self.navigationBarHeightConstraint.constant = statusBarHeight + (statusBarHeight > 0 ? 18 : 20);
    [self.navigationBar setNeedsUpdateConstraints];
    [self.view setNeedsDisplay];

    [super viewWillLayoutSubviews];
    //self.currentCellTag ++;
    //[self.tableView reloadData];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)rowCount
{
    NSUInteger inte = [self.resVmList count] + 1; //+1はスレッドの最後セル
    return inte;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self rowCount];
    }
    return 0;
}

- (FastViewModelBase *)tableView:(FastTableView *)tableView vmAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.resVmList.readMarkRow == indexPath.row) {
        return nil;
    } else if (indexPath.row == [self.resVmList count]) {
        return nil;
    }

    ResVm *resVm = [self.resVmList resVmAtIndex:indexPath.row];
    return resVm;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self isViewVisible] && self.isLoaded && self.isViewDidAppeard && self.tableView.scrollEnabled) {
        CGFloat contentOffsetWidthWindow = self.tableView.contentOffset.y + self.tableView.bounds.size.height;
        BOOL leachToBottom = contentOffsetWidthWindow >= -20 + self.tableView.contentSize.height + self.tableView.contentInset.bottom;
        BOOL exceed = contentOffsetWidthWindow > self.tableView.contentSize.height + self.tableView.contentInset.bottom;

        self.isReleaseForUpdateReady = NO;
        if (exceed && self.inTouch) {
            if (self.pullRefreshView.superview == nil) {
                [self.tableView addSubview:self.pullRefreshView];
            }
            self.pullRefreshView.frame = CGRectMake(0, self.tableView.contentSize.height, self.view.frame.size.width, contentOffsetWidthWindow - (self.tableView.contentSize.height + self.tableView.contentInset.bottom));
            //self.pullRefreshView.backgroundColor = [UIColor purpleColor];
        } else {

        }

        BOOL releaseMode = NO;
        if (exceed && self.inTouch) { // && self.tableView.isDecelerating == NO
            BOOL canReleaseUpdate = contentOffsetWidthWindow >= 50 + self.tableView.contentSize.height + self.tableView.contentInset.bottom;
            if (canReleaseUpdate) {
                releaseMode = YES;
                NSString *labelText = @"  離して更新　";
                self.isReleaseForUpdateReady = YES;

                if (![self.pullRefreshButton.titleLabel.text isEqualToString:labelText]) {
                    [self.pullRefreshButton setImage:[[UIImage imageNamed:@"arrowdown.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                    [self.pullRefreshButton setTitleColor:[[ThemeManager sharedManager] colorForKey:ThemeResPageTintColor] forState:UIControlStateNormal];

                    [self.pullRefreshButton setTitle:labelText forState:UIControlStateNormal];
                }
            }
        }

        if (releaseMode == NO && self.inTouch) {
            NSString *labelText = @"  引っ張って更新　";
            if (![self.pullRefreshButton.titleLabel.text isEqualToString:labelText]) {
                [self.pullRefreshButton setImage:[[UIImage imageNamed:@"arrowup.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                [self.pullRefreshButton setTitle:labelText forState:UIControlStateNormal];
                [self.pullRefreshButton setTitleColor:[[ThemeManager sharedManager] colorForKey:ThemeResPageTintColor] forState:UIControlStateNormal];
                self.pullRefreshButton.titleLabel.font = [UIFont systemFontOfSize:16];
            }
        }

        if (leachToBottom) {
            self.th.reachedLastReading = self.th.localCount;
            self.th.reading = self.th.localCount; //self.tableView.contentOffset.y;
            if (self.th.read != self.th.localCount) {
                myLog(@"save by leachToBottom: %lu", (unsigned long)self.th.reading);

                self.th.read = self.th.localCount;
                //[[ThManager sharedManager] saveThAsync:self.th];
            }
        } else {
            if (self.th.reachedLastReading > 0) {
                self.th.reachedLastReading = -1;
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (self.resVmList.readMarkRow == indexPath.row) {
        LabelCell *cell = (LabelCell *)[tableView dequeueReusableCellWithIdentifier:ReadMarkCellIdentifier];
        self.readMarkCell = cell;
        if (cell.tag != self.currentCellTag) {
            cell.separator.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];
            cell.nameLabel.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeResPageReadMarkBackgroundColor];
            cell.nameLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];

            [cell setNeedsDisplay];
            [cell.nameLabel setNeedsDisplay];
            cell.tag = self.currentCellTag;
        }

        self.readMarkCell.nameLabel.text = [NSString stringWithFormat:@"新着: %zd", self.th.localCount - self.resVmList.lastReadNumber];
        return cell;
    } else if ([self.resVmList count] == indexPath.row) {
        LabelCell *cell = (LabelCell *)[tableView dequeueReusableCellWithIdentifier:LastCellIdentifier];
        self.lastCell = cell;
        if (cell.tag != self.currentCellTag) {
            cell.separator.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];

            cell.nameLabel.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeEndOfThreadBackgroundColor];
            cell.nameLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeSubTextColor];

            cell.tag = self.currentCellTag;
        }

        NSInteger unreadCount = self.th.localCount - self.resVmList.lastReadNumber;
        cell.nameLabel.text = [NSString stringWithFormat:@"----- %@ -----", unreadCount > 0 ? @"おわり" : @"すべて読んだ"];
        return cell;
    }

    ResVm *resVm = [self.resVmList resVmAtIndex:indexPath.row];

    NSString *identifier = @"ResTableViewCell";
    ResTableViewCell *cell = (ResTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    BOOL newCell = self.currentCellTag != cell.tag;
    if (newCell) { //change Theme
        UIColor *backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeResRowBackgroundColor];

        cell.resView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = backgroundColor;
        for (UIView *subView in cell.subviews) {
            subView.backgroundColor = [UIColor clearColor];
        }

        cell.tag = self.currentCellTag;
    }

    cell.resView.resVm = resVm;


    if (resVm.statusIndex != self.tableView.statusIndex) {
        [resVm regenAttributedStrings]; //登録時
        resVm.statusIndex = self.currentCellTag;
    }


    cell.resView.frame = resVm.frameRect;
    [cell.resView setNeedsDisplay];
    [cell.resView onCellShown];

    return cell;
}

#pragma - mark ツールバー

// ツリー切替
- (IBAction)toggleButtonTouchupInside:(id)sender
{
    [self toggleTreeMode];
}

- (void)toggleTreeMode
{
    self.currentCellTag++;
    self.stability = NO;

    NSInteger originResNumber = 0;
    NSArray *indexPathList = [self.tableView indexPathsForVisibleRows];
    BOOL first = YES;
    for (NSIndexPath *path in indexPathList) {
        if (first) {
            first = NO;
            continue;
        }
        ResVm *resVm = [self.resVmList resVmAtIndex:path.row];
        if (resVm) {
            originResNumber = resVm.originResNumber;
            break;
        }
        //self.th.reading = firstPath.row+1;
    }
    if (originResNumber < 1) {
        originResNumber = 1;
    }

    BOOL toEnabled = ![self.resVmList getTreeMode];
    [self.resVmList setTreeMode:toEnabled];
    [Env setTreeEnabled:toEnabled];

    [self.resVmList rebuild];

    NSInteger row = [self.resVmList rowAtOriginResNumber:originResNumber];

    [self.tableView reloadTableViewAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                                    withOffset:0
                                    completion:^{
                                      [self startBackgroundParse];
                                    }];
}

- (IBAction)moreButtonTapAction:(id)sender
{
    if (self.currentPopupEntry) {
        [self closeAllPopup];
        return;
    }

    ResVCActionMenu *actionMenu = [[ResVCActionMenu alloc] init];
    actionMenu.resVC = self;

    [actionMenu build];
    [actionMenu open];
}


- (IBAction)postTapAction:(id)sender
{
    if (self.currentPopupEntry) {
        [self closeAllPopup];
        return;
    }

    PostNaviVC *postNaviVC = [[MySplitVC instance] sharedPostNaviVC];
    postNaviVC.resVC = self;
    postNaviVC.th = self.th;

    [[MySplitVC instance] presentViewController:postNaviVC
                                            animated:YES
                                          completion:^{

                                          }];
}

- (IBAction)onToBottomToolButtonAction:(id)sender
{
    [self scrollToBottom];
}

- (IBAction)autoScrollAction:(id)sender
{
    if (self.currentPopupEntry) {
        [self closeAllPopup];
        return;
    }
    [self.autoScrollCalculator onClickAutoScrollButton];
}

- (void)closeAllPopup
{
    PopupEntry *targetPopupEntry = self.currentPopupEntry;
    while (targetPopupEntry) {
        [UIView animateWithDuration:0.1
            delay:0.0
            options:UIViewAnimationOptionCurveEaseInOut
            animations:^{
              targetPopupEntry.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.7f, 0.7f);
              targetPopupEntry.view.alpha = 0.0;
            }
            completion:^(BOOL finished) {
              [targetPopupEntry.view removeFromSuperview];

            }];

        targetPopupEntry = targetPopupEntry.prev;
        self.currentPopupEntry = targetPopupEntry;
    }

    self.tableView.scrollEnabled = YES;
    self.tableView.userInteractionEnabled = YES;
}

@end
