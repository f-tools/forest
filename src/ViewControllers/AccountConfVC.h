//
//  AccountConfVC.h
//  Forest
//

#import <UIKit/UIKit.h>

@interface AccountConfVC : UITableViewController

// 浪人
@property (weak, nonatomic) IBOutlet UITextField *rouninIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *rouninPassTextField;
@property (weak, nonatomic) IBOutlet UILabel *loginStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginActionButton;
- (IBAction)loginAction:(id)sender;

- (IBAction)rouninIDChanged:(id)sender;
- (IBAction)rouninPassChanged:(id)sender;
- (IBAction)backItemAction:(id)sender;
- (void)loginRouninIfEnabled:(void (^)(BOOL))completion;

// BE
@property (weak, nonatomic) IBOutlet UITextField *bePassField;
@property (weak, nonatomic) IBOutlet UITextField *beIDField;
@property (weak, nonatomic) IBOutlet UILabel *beLabel;
@property (weak, nonatomic) IBOutlet UIButton *beLoginButton;

- (IBAction)beLoginButtonAction:(id)sender;
@end
