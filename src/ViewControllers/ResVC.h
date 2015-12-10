//
//  ResViewController.h
//

#import <UIKit/UIKit.h>
#import "Th.h"
#import "DynamicBaseVC.h"
#import "FavVC.h"
#import "ResTableView.h"

@class ResVmList;
@class PopupEntry;
@class ImagesPageViewController;

@interface ResVC : DynamicBaseVC <FastTableViewDataSource, FastTableViewDelegate, UISearchBarDelegate>


@property (nonatomic) Th *th;
@property (nonatomic, copy) NSArray *thumbnails;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationBarHeightConstraint;
@property (weak, nonatomic) IBOutlet ResTableView *tableView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *navBorderView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressBarTopSpaceConstraint;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navBorderHeightConstraint;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIView *toolbarSeparator;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarSeparatorHeightConstraint;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *autoScrollButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toBottomToolButton;

@property (nonatomic) UIView *pullRefreshView;
@property (nonatomic) UIButton *pullRefreshButton;
@property (nonatomic) UILabel *pullRefreshLabel;

@property (nonatomic) BOOL cannotBack;

@property (nonatomic) ImagesPageViewController *imageViewVC;

@property (nonatomic) UIView *popupBackgroundView;
@property (nonatomic) BOOL canTap;

@property (nonatomic) PopupEntry *currentPopupEntry;
@property (nonatomic) PopupEntry *downPopupEntry;

@property (nonatomic) CGPoint downPoint;
@property (nonatomic) UITableViewCell *downCell;
@property (nonatomic) BOOL isEstablished;

@property (nonatomic) BOOL isSearchMode;
@property (nonatomic) NSInteger currentSearchTag;

- (IBAction)onToBottomToolButtonAction:(id)sender;

- (IBAction)autoScrollAction:(id)sender;

- (IBAction)postTapAction:(id)sender;

- (void)requestUpdateForPostSuccess;

- (void)loadThread:(Th *)th complete:(void (^)(void))completionBlock;

- (void)detach;

- (void)closeAllPopup;

- (void)popupCenterWithRes:(Res *)res;

- (void)callViewWillDisappear;

- (void)toggleTreeMode;

#pragma - mark Search

@property (weak, nonatomic) IBOutlet UIView *searchContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchContainerBottomConstraint;
@property (weak, nonatomic) IBOutlet UITableView *searchHistoryTableView;
@property (weak, nonatomic) IBOutlet UIView *searchCountContainerView;
@property (weak, nonatomic) IBOutlet UIView *searchTopBorder;
@property (weak, nonatomic) IBOutlet UIView *topBorder;
@property (weak, nonatomic) IBOutlet UIView *bottomBorder2;
@property (weak, nonatomic) IBOutlet UIView *bottomBorder;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchCountIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *searchCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *searchCountDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *otherExtractButton;
@property (weak, nonatomic) IBOutlet UIButton *popularExtractButton;
@property (weak, nonatomic) IBOutlet UIButton *linkExtractButton;
@property (weak, nonatomic) IBOutlet UIButton *imageExtractButton;
@property (weak, nonatomic) IBOutlet UIButton *clearHistoryExtractButton;
@property (weak, nonatomic) IBOutlet UIButton *closeExtractButton;
@property (weak, nonatomic) IBOutlet UIView *rightSeparator;
@property (weak, nonatomic) IBOutlet UIView *leftSeparator;
@property (weak, nonatomic) IBOutlet UIView *centerSeparator1;
@property (weak, nonatomic) IBOutlet UIView *centerSeparator2;

@end
