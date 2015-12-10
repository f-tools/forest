//
//  ConfigListViewController.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "BaseTableVC.h"
@interface ConfigListVC : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *appUpdateNotificationSwitch;
- (IBAction)appUpdateNotificationAction:(id)sender;


- (IBAction)backAction:(id)sender;
- (IBAction)sync2ch_id_edit_end:(id)sender;
- (IBAction)sync2ch_pass_edit_end:(id)sender;
- (IBAction)anchorPopupTreeEnabled:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *sync2ch_pass_textfield;
@property (weak, nonatomic) IBOutlet UITextField *sync2ch_id_textfield;
- (IBAction)screenModeValueChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *screenModeSegmentedControl;

- (IBAction)autoSyncSegmentChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *autoSyncSwitch;
- (IBAction)resetConvertScript:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *convertScriptTextField;

@property (weak, nonatomic) IBOutlet UIButton *sync2chButton;
- (IBAction)sync2chUrlButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *orientationSegmentControl;
- (IBAction)orientaoinChanged:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *resAutoMarkSwitch;

@property (weak, nonatomic) IBOutlet UISegmentedControl *treeModeSegment;
- (IBAction)onTreeModeChanged:(id)sender;
- (IBAction)onAutoMarkChanged:(id)sender;

@property (weak, nonatomic) IBOutlet UITableViewCell *sync2chIdCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *sync2chPassCell;
@property (weak, nonatomic) IBOutlet UISwitch *anchorPopupTreeSwith;
- (IBAction)deleteCookieAction:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *thumbnailModeSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *thumbnailSizeTypeSegment;
- (IBAction)onThumbnailModeChanged:(id)sender;
- (IBAction)onThumbnailSizeTypeChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *syncCryptPasswordVisibleChangeButton;
- (IBAction)onSyncCryptPasswordVisibleTap:(id)sender;

@property (weak, nonatomic) IBOutlet UISegmentedControl *syncCryptLevelSegment;
- (IBAction)syncCryptPasswordEditingEnd:(id)sender;

- (IBAction)syncLevelChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *syncCryptPasswordTextField;

@end
