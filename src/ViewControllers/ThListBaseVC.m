#import <QuartzCore/QuartzCore.h>

#import "ThListBaseVC.h"
#import "ThVm.h"
#import "ThTableViewCell.h"
#import "ThemeManager.h"
#import "MyNavigationVC.h"
#import "ResVC.h"
#import "AppDelegate.h"
#import "Env.h"
#import "ViewController+Additions.h"
#import "GestureEntry.h"
#import "GestureManager.h"
#import "Th+ParseAdditions.h"
#import "ThListTransaction.h"
#import "BoardManager.h"
#import "ThItemActionMenu.h"
#import "NextSearchVC.h"
#import "MySplitVC.h"

#import "FavVC.h"

@interface ThListBaseVC ()

@property (nonatomic) GestureManager *gesture;
@property (nonatomic) Th *selectedTh;

@property (nonatomic) ThListTransaction *thlistTransaction;
@property (nonatomic) ThItemActionMenu *thItemActionMenu;

@end

@implementation ThListBaseVC

// @ virtual
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self
                  name:MYO_WINDOW_EVENT_NOTIFICATION
                object:[[[UIApplication sharedApplication] delegate] window]]; //
}

- (void)onOrientationChanged:(CGFloat)width
{
    self.thItemActionMenu = nil;

    [self startRegenerateTableData:YES];
}


- (void)viewDidLoad
{
    self.hasSections = NO;

    [super viewDidLoad];

    self.gesture = [[GestureManager alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowEvent:)
                                                 name:MYO_WINDOW_EVENT_NOTIFICATION
                                               object:[[[UIApplication sharedApplication] delegate] window]];

    [[self thisTableView] registerNib:[UINib nibWithNibName:@"ThTableViewCell" bundle:nil]
              forCellReuseIdentifier:@"Cell"];

    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                             action:@selector(_onLongGesture:)];
    longPressGestureRecognizer.minimumPressDuration = 0.60;
    [[self thisTableView] addGestureRecognizer:longPressGestureRecognizer];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.hasSections) {
        for (ThTableViewCell *cell in [self thisTableView].visibleCells) {
            CGFloat hiddenFrameHeight = scrollView.contentOffset.y + 22 - cell.frame.origin.y;
            if (hiddenFrameHeight >= 0) {
                [cell maskCellFromTop:hiddenFrameHeight];
            } else {
                cell.layer.mask = nil;
            }
        }
    }
}

- (void)maskCell:(UITableViewCell *)cell fromTopWithMargin:(CGFloat)margin
{
    cell.layer.mask = [self visibilityMaskForCell:cell withLocation:margin / cell.frame.size.height];
    cell.layer.masksToBounds = YES;
}

- (CAGradientLayer *)visibilityMaskForCell:(UITableViewCell *)cell withLocation:(CGFloat)location
{
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.frame = cell.bounds;
    mask.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:1 alpha:0] CGColor], (id)[[UIColor colorWithWhite:1 alpha:1] CGColor], nil];
    mask.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:location], [NSNumber numberWithFloat:location], nil];
    return mask;
}

- (void)onThemeChanged
{
    [super onThemeChanged];
    [self startRegenerateTableDataIfVisible];
    [self thisTableView].backgroundColor = [UIColor clearColor];

    [[ThemeManager sharedManager] changeTableViewStyle:[self thisTableView]];

    self.view.backgroundColor = [UIColor clearColor];

    [self thisTableView].separatorColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadRowSeparatorColor];
}

- (IBAction)buttonClicked:(id)sender
{

    dispatch_async(dispatch_get_main_queue(), ^{
      [[MySplitVC instance] closeActionMenu:nil complete:nil];

      self.thlistTransaction = [[ThListTransaction alloc] init];

      Board *board = [[BoardManager sharedManager] boardForTh:self.selectedTh];
      [self.thlistTransaction startOpenThListTransaction:board];

    });
}

- (IBAction)modalBackgroundTouchInsideUp:(id)sender
{
    [[MySplitVC instance] closeActionMenu:nil complete:nil];
}

- (BOOL)canEditing
{
    return NO;
}

- (void)_onLongGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    UITableView *tableView = [self thisTableView];
    if (tableView && tableView.isEditing) return;

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // NSLog(@"UIGestureRecognizerStateEnded");
    } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {

        CGPoint p = [gestureRecognizer locationInView:[self thisTableView]];

        NSIndexPath *indexPath = [[self thisTableView] indexPathForRowAtPoint:p];

        ThVm *thVm = [self thVmForRowAtIndexPath:indexPath];

        self.selectedTh = thVm.th;

        if (self.thItemActionMenu == nil) {
            self.thItemActionMenu = [[ThItemActionMenu alloc] init];

            self.thItemActionMenu.thListBaseVC = self;
            self.thItemActionMenu.canEdit = [self isKindOfClass:[ThListVC class]] == false;

            [self.thItemActionMenu build];
        }

        self.thItemActionMenu.thVm = thVm;
        self.thItemActionMenu.indexPath = indexPath;

        [[MySplitVC instance] openActionMenu:self.thItemActionMenu];
    }
}

- (BOOL)canUpdateAll
{
    return YES;
}

- (void)updateAll
{
    myLog(@"updateAll in base");
}

- (NSString *)getUpdateAllLabel
{
    return @"更新/巡回";
}

- (NSArray *)getGestureItems
{
    __weak ThListBaseVC *weakSelf = self;

    NSMutableArray *gestureItems = [NSMutableArray array];

    GestureEntry *gestureItem = [[GestureEntry alloc] init];
    gestureItem.nameGetter = ^{
      return @"戻る";
    };
    gestureItem.directions = [[NSArray alloc] initWithObjects:DIRECTION_RIGHT, nil];
    gestureItem.completionBlock = ^{
      if (weakSelf) {
          MyNavigationVC *navCon = [MyNavigationVC instance];
          if (weakSelf.isTabInMain == NO && weakSelf == navCon.topViewController) {
              [navCon popMyViewController];
          }
      }
    };
    [gestureItems addObject:gestureItem];

    gestureItem = [[GestureEntry alloc] init];
    gestureItem.nameGetter = ^{
      return @"進む";
    };
    gestureItem.directions = [[NSArray alloc] initWithObjects:DIRECTION_LEFT, nil];
//    gestureItem.isEnabled = ^{
//        if (weakSelf.nextViewController == nil) {
//            return NO;
//        } else {
//            return YES;
//        }
//
//    };
    gestureItem.completionBlock = ^{
      if (weakSelf) {
          MyNavigationVC *myNavigationViewController = [MyNavigationVC instance];
          [myNavigationViewController pushNexViewController];
      };
    };
    [gestureItems addObject:gestureItem];

    // 更新・再巡回
    gestureItem = [[GestureEntry alloc] init];
    gestureItem.nameGetter = ^{
      return [weakSelf getUpdateAllLabel];
    };
    gestureItem.isEnabled = ^{
      return [weakSelf canUpdateAll];
    };
    gestureItem.directions = [[NSArray alloc] initWithObjects:DIRECTION_RIGHT, DIRECTION_DOWN, DIRECTION_LEFT, nil];
    gestureItem.completionBlock = ^{
      [weakSelf updateAll];
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
      [weakSelf tableViewScrollToBottomAnimated:NO];
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
      [weakSelf tableViewScrollToTopAnimated:NO];
    };
    [gestureItems addObject:gestureItem];

    return gestureItems;
}

- (UIView *)getToolbar
{
    return nil;
}

- (void)windowEvent:(NSNotification *)notification
{
    if (![self isViewVisible] || [MySplitVC instance].isActionMenuOpen) {
        return;
    }

    UIEvent *event = (id)notification.userInfo;
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint pos = [touch locationInView:self.view];
    

    
    UITableView *tableView = [self thisTableView];

    BOOL beforeStarted = [self.gesture isGestureStarted];

    switch (touch.phase) {
    case UITouchPhaseBegan: {
        [self.gesture touchesBegan:pos withEvent:event];
        
        BOOL touchOnTable = (CGRectContainsPoint(self.view.bounds, pos));
        if (!touchOnTable) {
            [self.gesture cancel];
            return;
        }
        

        UIView *toolbar = [self getToolbar];
        if (toolbar) {

            CGPoint posIntoolbar = [touch locationInView:toolbar];
            BOOL touchOntoolbar = (CGRectContainsPoint(toolbar.bounds, posIntoolbar));
            if (touchOntoolbar) {
                [self.gesture cancel];
                return;
            }
        }
    }

    break;
    case UITouchPhaseMoved:
        [self.gesture touchesMoved:pos withEvent:event];
        if ([self isViewVisible] && [self.gesture isGestureStarted]) {
            GestureEntry *showingGestureItem = nil;
            if (tableView.scrollEnabled) {
                tableView.scrollEnabled = NO;
            }
            [tableView setUserInteractionEnabled:NO];

            if (beforeStarted == NO) { // ジェスチャーが有効になった瞬間にセル選択を解除
                CGPoint p = [touch locationInView:[self thisTableView]];
                NSIndexPath *indexPath = [[self thisTableView] indexPathForRowAtPoint:p];

                if (indexPath) {
                    ThTableViewCell *cell = (ThTableViewCell *)[[self thisTableView] cellForRowAtIndexPath:indexPath];
                    if (cell.isHighlighted || cell.isSelected) {
                        [cell setHighlighted:NO];
                        [cell setSelected:NO];
                    }
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

        break;

    case UITouchPhaseEnded: {
        tableView.scrollEnabled = YES;
        [tableView setUserInteractionEnabled:YES];
        [self.gesture touchesEnded:pos withEvent:event];


        if ([self isViewVisible] && [self.gesture isGestureStarted]) {
            [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
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

- (void)startBackgroundParse
{
    NSArray *thVmList = [self getThVmList];
    UITableView *tableView = [self thisTableView];
    if (tableView == nil || thVmList == nil || [self isViewLoaded] == NO) {
        return;
    }

    NSUInteger checkCellTag = self.currentCellTag;

    myLog(@"startParseForThVmList success");

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      for (ThVm *thVm in thVmList) {
          if (checkCellTag != self.currentCellTag) {
              myLog(@"stop background request by diff of currentCellTag");
              break;
          }

          if (thVm.tag != self.currentCellTag && tableView) {

              @synchronized(thVm)
              {
                  [thVm regenAttributedStrings:[[MySplitVC instance] thListTableViewWidth:self]];
                  thVm.tag = self.currentCellTag;
              }
          }
      }
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Subclassが実装する
// thVmForRowAtIndexPath
- (ThVm *)thVmForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSArray *)getThVmList
{
    return nil;
}

- (UIProgressView *)returnProgressView
{
    return nil;
}

- (ThVm *)genThVm:(Th *)th
{
    ThVm *thVm = [[ThVm alloc] initWithTh:th];
    if ([self isKindOfClass:[FavVC class]]) {
        thVm.showFavState = NO;
    }
    //thVm.tag = self.currentCellTag;
    thVm.delegate = (id)self;

    return thVm;
}

/*
 - (NSObject*) canReloadCells {
 return self;
 }
 */

// 一覧で表示するべきスレッドのプロパティが変わったことを伝える。
- (void)onThVmPropertyChanged:(ThVm *)thVm name:(NSString *)propertyName
{
    thVm.tag = -1;

    UITableView *tableView = [self thisTableView];
    if (tableView) {

        if ([self isKindOfClass:[FavVC class]] && [propertyName isEqualToString:@"read"]) {
            [[FavVC sharedInstance] refreshTabBadge];
        }

        @synchronized(tableView)
        {
            if ([self isViewVisible]) {
                [self reloadVisibleCells];
            } else {
                self.shouldReloadTableViewWhenViewWillAppear = YES;
            }
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
          [NSThread sleepForTimeInterval:1.2];
          @synchronized(thVm)
          {
              if (thVm.tag != self.currentCellTag) {
                  [thVm regenAttributedStrings:[[MySplitVC instance] thListTableViewWidth:self]];
                  thVm.tag = self.currentCellTag;
              }
          }
        });
    }
}

// 今表示しているCellをリロードする。
- (void)reloadVisibleCells
{

    dispatch_async(dispatch_get_main_queue(),
                   ^{
                     UITableView *tableView = [self thisTableView];
                     @synchronized(tableView)
                     {
                         NSMutableArray *mutablePathSet = [NSMutableArray array];
                         NSArray *indexPathList = [tableView indexPathsForVisibleRows];
                         for (NSIndexPath *indexPath in indexPathList) {
                             ThVm *thVm = [self thVmForRowAtIndexPath:indexPath];
                             //ThTableViewCell* cell = (ThTableViewCell*)[[self thisTableView] cellForRowAtIndexPath:indexPath];
                             if (thVm.tag != self.currentCellTag) {
                                 [mutablePathSet addObject:indexPath];
                             }
                         }

                         if ([mutablePathSet count] > 0) {

                             [tableView reloadRowsAtIndexPaths:mutablePathSet
                                              withRowAnimation:UITableViewRowAnimationNone];
                         }
                     }
                   });

}

// スレの監視を中止するため削除の通知
- (void)removeThVm:(ThVm *)thVm
{
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThVm *thVm = [self thVmForRowAtIndexPath:indexPath];

    if (thVm.delegate == nil) {
        thVm.delegate = (id)self;
    }

    if (thVm.cellHeight > 0) {
        return thVm.cellHeight;
    }
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @synchronized(tableView)
    {
        ThVm *thVm = [self thVmForRowAtIndexPath:indexPath];

        if (thVm.tag != self.currentCellTag) {

            @synchronized(thVm)
            {
                [thVm regenAttributedStrings:[[MySplitVC instance] thListTableViewWidth:self]];
                thVm.tag = self.currentCellTag;
            }
        }

        return [thVm getHeight:tableView.bounds.size.width];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThTableViewCell *thCell = (ThTableViewCell *)cell;
    [thCell.speedTextView setNeedsDisplay];
    [thCell.countTextView setNeedsDisplay];
    [thCell.titleTextView setNeedsDisplay];
    [thCell.otherTextView setNeedsDisplay];
    [thCell.newsCountTextView setNeedsDisplay];
    [thCell.dateTextView setNeedsDisplay];
    [thCell setNeedsDisplay];

    if (self.isEditing == NO && self.hasSections) {
        NSUInteger numberOfSections = [self numberOfSectionsInTableView:tableView];
        CGFloat sectionHeight = [self tableView:tableView heightForHeaderInSection:0];
        if (sectionHeight > 0 && numberOfSections > 0) {
            CGFloat hiddenFrameHeight = tableView.contentOffset.y + sectionHeight - cell.frame.origin.y;
            if (hiddenFrameHeight >= 0) {
                [thCell maskCellFromTop:hiddenFrameHeight];
            } else {
                cell.layer.mask = nil;
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @synchronized(tableView)
    {
        ThVm *thVm = [self thVmForRowAtIndexPath:indexPath];

        ThTableViewCell *cell = (ThTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];

        if (cell.tag != self.currentCellTag) {
            UIColor *backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadRowBackgroundColor];
            UIColor *selectedBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadRowSelectedBackgroundColor];
            ;

            cell.backgroundColor = backgroundColor;
            for (UIView *subView in cell.subviews) {
                // iOS7でCellの下のViewにも同じUIColorが設定されてしまい
                // 半透明の場合におかしくなってしまうので、clearColorを設定
                subView.backgroundColor = [UIColor clearColor];
            }

            UIView *selectedBackgroundViewForCell = [UIView new];
            selectedBackgroundViewForCell.backgroundColor = selectedBackgroundColor;
            cell.selectedBackgroundView = selectedBackgroundViewForCell;

            UIColor *clearColor = [UIColor clearColor];

            [cell.titleTextView setBackgroundColor:clearColor];
            cell.titleTextView.thTableViewCell = cell;

            [cell.countTextView setBackgroundColor:clearColor];
            [cell.speedTextView setBackgroundColor:clearColor];
            [cell.otherTextView setBackgroundColor:clearColor];
            [cell.newsCountTextView setBackgroundColor:clearColor];
            [cell.dateTextView setBackgroundColor:clearColor];

            cell.titleTextView.drawMarkWhenRead = [self isKindOfClass:[ThListVC class]] || [self isKindOfClass:[NextSearchVC class]];
            cell.titleTextView.drawType = thVmTitle;
            cell.countTextView.drawType = thVmCount;
            cell.speedTextView.drawType = thVmSpeed;
            cell.otherTextView.drawType = thVmOther;
            cell.newsCountTextView.drawType = thVmNewCount;
            cell.dateTextView.drawType = thVmDate;

            cell.tag = self.currentCellTag;
        }

        cell.layer.mask = nil;

        if (thVm.tag != self.currentCellTag) {
            [thVm regenAttributedStrings:[[MySplitVC instance] thListTableViewWidth:self]];
            thVm.tag = self.currentCellTag;
        }

        cell.titleTextView.thVm = thVm;
        cell.countTextView.thVm = thVm;
        cell.speedTextView.thVm = thVm;
        cell.otherTextView.thVm = thVm;
        cell.newsCountTextView.thVm = thVm;
        cell.dateTextView.thVm = thVm;

        [cell.titleTextView setFrame:thVm.titleFrame];
        [cell.countTextView setFrame:thVm.countFrame];
        [cell.speedTextView setFrame:thVm.speedFrame];
        [cell.otherTextView setFrame:thVm.otherFrame];
        [cell.newsCountTextView setFrame:thVm.newFrame];
        [cell.dateTextView setFrame:thVm.dateFrame];

        return cell;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // ThTableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if (tableView.isEditing) {
        // [cell setNeedsDisplay];
        // [cell.titleTextView setNeedsDisplay];
        return;
    }

    if ([self.gesture isGestureStarted]) {
        [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
        return;
    }

    ThVm *thVm = [self thVmForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    ResTransaction *man = [[ResTransaction alloc] init];

    man.th = thVm.th;
    if ([man startOpenThTransaction]) {
        //return YES;
    }
    //    return NO;
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
