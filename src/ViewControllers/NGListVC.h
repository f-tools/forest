//
//  NGListVC.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "BaseModalNavigationVC.h"

@interface NGListNavigationController : BaseModalNavigationVC 

@end



@interface NGListVC : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *wordToolButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *idToolButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *threadToolButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nameToolButton;

- (IBAction)threadToolButtonAction:(id)sender;
- (IBAction)nameToolButtonAction:(id)sender;
- (IBAction)idButtonAction:(id)sender;
- (IBAction)wordToolButtonAction:(id)sender;

@end
