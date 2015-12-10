//
//  FastTableView.m
//
// TableViewのCell一つ一つに対応するViewModelを前提にして、
// バックグラウンドでの高さ計算と、適宜reloadDataを実行する機構を実装する
// 高さ計算はViewModelが行う

#import "FastTableView.h"

@implementation FastViewModelBase

- (CGFloat)calcHeight
{
    return 0.f;
}

- (void)regenAttributedStrings
{
}

@end

@interface FastTableView ()

@property (nonatomic) NSObject *backgroundParseLock;
@property (nonatomic) BOOL isDoingBackgroundParse;

@end

@implementation FastTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)initFastTableView
{
    [self swapDelegate];

    self.statusIndex = 1;
    self.stability = NO;
    self.backgroundParseLock = [NSObject new];
}

- (void)swapDelegate
{
    self.clientDataSource = (id<FastTableViewDataSource>)self.dataSource;
    self.clientDelegate = (id<FastTableViewDelegate>)self.delegate;

    self.delegate = self;
    self.dataSource = self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.clientDataSource tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.clientDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    FastViewModelBase *vm = [self.clientDataSource tableView:(FastTableView *)tableView vmAtIndexPath:indexPath];
    if (vm == nil) {
        return 24;
    }

    if (vm.cellHeight > 0) {
        return vm.cellHeight;
    }

    return 140;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    FastViewModelBase *vm = [self.clientDataSource tableView:(FastTableView *)tableView vmAtIndexPath:indexPath];

    if (vm == nil) {
        return 24;
    }

    if (vm.cellHeight <= 0 || vm.statusIndex != self.statusIndex) {
        [vm regenAttributedStrings];
        vm.statusIndex = self.statusIndex;
    }

    return vm.cellHeight;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.clientDelegate respondsToSelector:@selector(tableView:shouldHighlightRowAtIndexPath:)]) {
        return [self.clientDelegate tableView:tableView shouldHighlightRowAtIndexPath:indexPath];
    }
    return YES;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.clientDelegate respondsToSelector:@selector(tableView:editingStyleForRowAtIndexPath:)]) {
        return [self.clientDelegate tableView:tableView editingStyleForRowAtIndexPath:indexPath];
    }

    return UITableViewCellEditingStyleNone;
}

- (NSInteger)allRowCount
{
    NSInteger sections = [self numberOfSections];
    NSInteger rowCount = 0;
    for (NSInteger i = 0; i < sections; i++) {
        rowCount += [self numberOfRowsInSection:i];
    }
    return rowCount;
}

- (void)startBackgroundParse
{

    NSInteger rowCount = [self allRowCount];
    if (rowCount > 2400) {
        return;
    }

    myLog(@"startBackgroundParse");

    NSUInteger checkCellTag = self.statusIndex;

    // バックグラウンドでの計算が終わったら、現在位置を記憶した後に、reloadDataを行う。
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

      @synchronized(self.backgroundParseLock)
      {
          self.isDoingBackgroundParse = YES;
          NSMutableArray *array = [NSMutableArray array];

          NSInteger sections = [self numberOfSections];
          for (NSInteger section = 0; section < sections; section++) {
              NSInteger rows = [self numberOfRowsInSection:section];
              for (NSInteger row = 0; row < rows; row++) {
                  FastViewModelBase *vm = [self.clientDataSource tableView:self vmAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
                  if (vm) {
                      [array addObject:vm];
                  }
              }
          }

          BOOL bottomUp = true;//self.th.reading  > [array count]/2;
          NSUInteger count = [array count];

          NSInteger increment = bottomUp ? -1 : 1;
          for (NSInteger i = bottomUp ? count - 1 : 0; bottomUp ? i >= 0 : i < count; i += increment) {
              FastViewModelBase *resVm = [array objectAtIndex:i];

              // checkTag が変更されていたら中止
              if (checkCellTag != self.statusIndex) {
                  myLog(@"cancel background parse resVms.");
                  self.isDoingBackgroundParse = NO;
                  return;
              }

              //  myLog(@"tag = %ld, current=%ld, %@,",(long)resVm.tag,(long)self.currentCellTag, self.tableView);
              if (resVm.statusIndex != self.statusIndex) {
                  [resVm regenAttributedStrings];
                  resVm.statusIndex = self.statusIndex;
              }
          }

          self.isDoingBackgroundParse = NO;
      }

      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isDecelerating == NO && self.isDragging == NO) {
            if (checkCellTag == self.statusIndex) {
                [self reloadDataForStability];
            }
        }
      });
    });
}

- (void)reloadForRedraw
{
    @synchronized(self)
    {
        self.statusIndex++;
        self.stability = NO;

        NSArray *visibleRows = [self indexPathsForVisibleRows];
        if ([visibleRows count] > 0) {
            NSIndexPath *firstPath = [visibleRows objectAtIndex:0];
            UITableViewCell *cell = [self cellForRowAtIndexPath:firstPath];
            CGFloat offset = (cell.frame.origin.y - self.contentInset.top) - self.contentOffset.y;

            [self reloadTableAtRow:firstPath.row
                        withOffset:-offset
                        completion:^{
                          [self startBackgroundParse];
                        }];
        }
    }
}

- (void)reloadDataForStability
{
    if (self.isDoingBackgroundParse) return;
    //if (self.inTouch) return;

    @synchronized(self)
    {
        if (self.stability == YES) {
            return;
        }
        self.stability = YES;

        BOOL tempScrollEnabled = self.scrollEnabled;
        self.scrollEnabled = NO;

        NSArray *visibleRows = [self indexPathsForVisibleRows];
        if ([visibleRows count] > 0) {
            //差分を取得しておく
            NSIndexPath *firstPath = [visibleRows objectAtIndex:0];
            UITableViewCell *cell = [self cellForRowAtIndexPath:firstPath];
            CGFloat offset = (cell.frame.origin.y - self.contentInset.top) - self.contentOffset.y;

            [self reloadTableViewAtIndexPath:firstPath
                                  withOffset:-offset
                                  completion:^() {
                                    self.scrollEnabled = tempScrollEnabled;
                                    NSLog(@"reloaded for stability");
                                  }];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)sender willDecelerate:(BOOL)willDecelerate
{
    if (willDecelerate == NO && self.isDragging == NO) {
        [self reloadDataForStability];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{
    if (self.isDragging == NO) {
        [self reloadDataForStability];
    }
}

- (NSIndexPath *)bottomIndexPath
{
    NSInteger bottomSection = [self numberOfSections] - 1;
    return [NSIndexPath indexPathForRow:[self numberOfRowsInSection:bottomSection] - 1
                              inSection:bottomSection];
}

- (void)scrollsToTop
{
    @synchronized(self)
    {
        [self reloadTableViewAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              withOffset:0
                              completion:^(){

                              }];
    }
}

- (void)scrollsToBottom
{
    @synchronized(self)
    {
        [self reloadTableViewAtIndexPath:[self bottomIndexPath]
                              withOffset:0
                              completion:^(){

                              }];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.clientDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.clientDelegate scrollViewDidScroll:scrollView];
    }
}

- (void)reloadTableAtRow:(NSInteger)row
              withOffset:(NSUInteger)offset
              completion:(void (^)())completion
{
    [self reloadTableViewAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                          withOffset:offset
                          completion:completion];
}

- (void)reloadTableViewAtIndexPath:(NSIndexPath *)indexPath
                        withOffset:(NSUInteger)offset
                        completion:(void (^)())completion
{
    @synchronized(self)
    {
        [self _reloadTableViewAtIndexPath:indexPath  withOffset:offset completion:completion];
    }
}

- (void)_reloadTableViewAtIndexPath:(NSIndexPath *)indexPath
                         withOffset:(NSUInteger)offset
                         completion:(void (^)())completion
{


    NSUInteger rowCount = [self numberOfRowsInSection:indexPath.section];
    NSUInteger tableHeight = self.bounds.size.height;


    //表示する部分は前もって高さを計算しておく。
    NSUInteger calculatedCellHeight = 0;

    NSInteger firstRow = indexPath.row;
    if (firstRow < 0) {
        firstRow = 0;
    } else if (firstRow < rowCount == NO) {
        firstRow = rowCount - 1;
    }

    NSInteger i = firstRow + (-13); //見えない上方のセルは多めに計算しておく。
    if (i < 0) {
        i = 0;
    } else if (i < rowCount == NO) {
        i = rowCount - 1;
    }

    BOOL noreach = NO;
    int bonusUsed = 0;
    for (; (noreach = calculatedCellHeight < tableHeight + offset) == YES || bonusUsed <= 1 ; i++) {
        if (i >= rowCount) break;

        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
        FastViewModelBase *vm = [self.clientDataSource tableView:self vmAtIndexPath:newIndexPath];
        if (vm) {
            [vm regenAttributedStrings];
            vm.statusIndex = self.statusIndex;

            if (vm.cellHeight > 0) {
                BOOL addHeight = i >= firstRow; //check required area
                if (addHeight) {
                    calculatedCellHeight += vm.cellHeight;
                }
                if (noreach == NO) {
                    bonusUsed++;
                }
            }
        }
    }

    [self reloadData];

    rowCount = [self numberOfRowsInSection:indexPath.section];
    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:firstRow inSection:indexPath.section];

    if (firstRow < rowCount) {
        [self scrollToRowAtIndexPath:nextIndexPath
                    atScrollPosition:UITableViewScrollPositionTop
                            animated:NO];

        if (self.superview == nil || self.window == nil) {
            //   return;
        } else {
            [self layoutIfNeeded];
        }

        NSInteger newY = offset + self.contentOffset.y;
        if (self.contentSize.height > tableHeight && newY > self.contentSize.height + self.contentInset.bottom - tableHeight) {
            newY = self.contentSize.height + self.contentInset.bottom - tableHeight - 1;
        }
        self.contentOffset = CGPointMake(0, newY);
    } 

    if (completion) {
        completion();
    }
}


@end
