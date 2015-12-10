#import "ThListSectionVC.h"

@interface HistoryVC : ThListSectionVC <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (void)addHistory:(Th *)th;
- (void)removeHistory:(Th *)th;
- (void)applySyncThList:(NSArray *)historyThList;
+ (id)sharedInstance;
- (NSArray *)getThVmList;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *editToolbarHeightConstraint;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneToolButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *purgeToolButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllButton;
- (IBAction)onDoneToolButtonAction:(id)sender;
- (IBAction)onPurgeToolButton:(id)sender;
- (IBAction)onSelectAllButtonAction:(id)sender;

@end
