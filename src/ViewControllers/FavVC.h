//
//  FavItemViewController.h
//  Forest
//

#import "ThListBaseVC.h"
#import "ThVm.h"
#import "Th.h"
#import "ThListSectionVC.h"

@interface FavFolder : NSObject <NSCopying> {
    NSMutableArray *_favFolders;
}
@property (nonatomic) NSString *name;
@property (nonatomic) NSMutableArray *thVmList;
@property (nonatomic) BOOL isTopFolder;

- (BOOL)containsForTh:(Th *)th;
@end

@interface FavVC : ThListSectionVC <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (nonatomic) NSMutableArray *favFolders;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *finButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *manipulateButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButtonItem;
- (IBAction)deleteBarButtonAction:(id)sender;
- (IBAction)onDoneAction:(id)sender;
- (void)onContextMenuTap;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *editToolbarHeightConstraint;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *syncButtonItem;

+ (id)sharedInstance;
- (void)addTh:(Th *)th;
- (void)addNextThread:(Th *)th base:(Th *)base;

- (void)saveFavorites;
- (void)saveFavoritesAsync;
- (void)notifyEditFavFolders;
- (void)applySyncFavFolders:(NSMutableArray *)array;
- (void)addThread:(Th *)th forFolder:(FavFolder *)folder;
- (void)removeThread:(Th *)th forFolder:(FavFolder *)folder;
- (BOOL)containsThread:(Th *)th;
- (BOOL)containsThread:(Th *)th forFolder:(FavFolder *)folder;
- (NSArray *)folderListForTh:(Th *)th;
- (void)refreshTabBadge;
@end
