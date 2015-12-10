//
//  ThListViewController.h
//  Forest
//
// 板のスレ一覧
//


#import "Board.h"
#import "ThListBaseVC.h"

@interface ThListVC : ThListBaseVC <UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *segmentCenterConstraint;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshBarButtonItem;

- (IBAction)onRefreshBarButtonItemAction:(id)sender;

@property (nonatomic) Board *board;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segment;

@property (weak, nonatomic) IBOutlet UIToolbar *mainToolbar;

@property (weak, nonatomic) IBOutlet UIView *centerToolbarView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *segmentHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *segment2HeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *toolbarBorder;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segment2;

@property (weak) UISearchBar *searchBar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *normalOrderButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *speedOrderButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *unreadOnlyButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *onReadOnlyButtonAction;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreButton;

- (IBAction)onMoreButtonTap:(id)sender;
- (IBAction)onMoreButtonAction:(id)sender;
- (IBAction)onUnreadOnlyButtonAction:(id)sender;
- (IBAction)onNormalButtonAction:(id)sender;
- (IBAction)onSpeedButtonAction:(id)sender;


- (void)notifyThListUpdated:(NSArray *)list;
- (void)setThList:(NSArray *)list withBoard:(Board *)board;
@end
