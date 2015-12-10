//
//  DynamicBaseViewController.h
//  Forest
//

#import <UIKit/UIKit.h>

@interface DynamicBaseVC : UIViewController

@property (nonatomic) DynamicBaseVC *nextViewController;
@property (nonatomic) NSUInteger currentCellTag;
@property (nonatomic) BOOL shouldReloadTableViewWhenViewWillAppear;
@property (nonatomic) BOOL shouldCheckOrientationWhenViewWillAppear;
@property (nonatomic) CGFloat prevWidth;

// @virtual
- (void)startBackgroundParse;
- (void)startRegenerateTableData:(BOOL)startBackgroundParse;
- (void)startRegenerateTableData;
- (void)startRegenerateTableDataIfVisible;

// @virtual
- (void)onThemeChanged;

// @virtual
- (UITableView *)thisTableView;

- (void)reloadTableData:(UITableView *)tableView;
- (CGFloat)tableWidthForOrientation;

- (void)tableViewScrollToBottom:(UITableView *)tableView animated:(BOOL)animated;
- (void)tableViewScrollToBottomAnimated:(BOOL)animated;
- (void)tableViewScrollToTop:(UITableView *)tableView animated:(BOOL)animated;
- (void)tableViewScrollToTopAnimated:(BOOL)animated;

@end
