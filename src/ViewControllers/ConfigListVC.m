//
//  ConfigListViewController.m
//  Forest
//

#import "ConfigListVC.h"
#import "Env.h"
#import "CookieManager.h"
#import "SyncManager.h"
#import "MySplitVC.h"

@interface ConfigListVC ()

@end

@implementation ConfigListVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [Env changeConvertScript:self.convertScriptTextField.text];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.convertScriptTextField.text = [Env getConvertScript:NO];

    self.sync2ch_id_textfield.text = [Env getConfStringForKey:@"Sync2ch_ID" withDefault:@""];
    self.sync2ch_pass_textfield.text = [Env getConfStringForKey:@"Sync2ch_PASS" withDefault:@""];
    [self.sync2ch_pass_textfield setSecureTextEntry:NO];
    [self.anchorPopupTreeSwith setOn:[Env getAnchorPopupTree] animated:NO];
    
    [self.appUpdateNotificationSwitch setOn:[Env getConfBOOLForKey:kConfigAppUpdateNotificationKey withDefault:YES]];

    [self.resAutoMarkSwitch setOn:[Env getAutoMarkEnabled]];

    self.treeModeSegment.selectedSegmentIndex = [Env getTreeModeConfig];

    self.thumbnailSizeTypeSegment.selectedSegmentIndex = [Env getThumbnailSizeType];
    self.thumbnailModeSegment.selectedSegmentIndex = [Env getThumbnailMode];

    UIInterfaceOrientationMask orientation = [Env getOrientation];
    int row = 0;
    if (orientation == UIInterfaceOrientationMaskPortrait) {
        row = 0;
    } else if (orientation == UIInterfaceOrientationMaskLandscapeLeft) {
        row = 1;
    } else if (orientation == UIInterfaceOrientationMaskLandscapeRight) {
        row = 2;
    } else if (orientation == UIInterfaceOrientationMaskLandscape) {
        row = 3;
    } else if (orientation == UIInterfaceOrientationMaskAllButUpsideDown) {
        row = 4;
    }
    self.orientationSegmentControl.selectedSegmentIndex = row;
    self.screenModeSegmentedControl.selectedSegmentIndex = [Env getConfBOOLForKey:@"tabletMode" withDefault:NO] ? 1 : 0;

    [self.autoSyncSwitch setOn:[Env getConfBOOLForKey:@"autoSync" withDefault:NO]];
    self.syncCryptLevelSegment.selectedSegmentIndex = [Env getConfIntegerForKey:@"syncCryptLevel" withDefault:0];
    [self.syncCryptPasswordTextField setSecureTextEntry:YES];
    self.syncCryptPasswordTextField.text = [Env getConfStringForKey:@"syncCryptPass" withDefault:@""];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

//@property (weak, nonatomic) IBOutlet UISegmentedControl *orientationSegmentControl;
- (IBAction)orientaoinChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    NSInteger index = segment.selectedSegmentIndex;
    if (index == 0) {
        [Env setOrientation:UIInterfaceOrientationMaskPortrait];
    } else if (index == 1) {
        [Env setOrientation:UIInterfaceOrientationMaskLandscapeLeft];
    } else if (index == 2) {
        [Env setOrientation:UIInterfaceOrientationMaskLandscapeRight];
    } else if (index == 3) {
        [Env setOrientation:UIInterfaceOrientationMaskLandscape];
    } else if (index == 4) {
        [Env setOrientation:UIInterfaceOrientationMaskAllButUpsideDown];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)appUpdateNotificationAction:(id)sender {
    UISwitch *swi = (UISwitch *)sender;
    [Env setConfBOOL:swi.isOn forKey:kConfigAppUpdateNotificationKey];
}

- (IBAction)backAction:(id)sender
{

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sync2ch_id_edit_end:(id)sender
{
    UITextField *f = sender;
    [Env setConfString:f.text forKey:@"Sync2ch_ID"];
}

- (IBAction)sync2ch_pass_edit_end:(id)sender
{
    UITextField *f = sender;
    [Env setConfString:f.text forKey:@"Sync2ch_PASS"];
}

- (IBAction)anchorPopupTreeEnabled:(id)sender
{
    UISwitch *swi = (UISwitch *)sender;
    [Env setAnchorPopupTree:swi.isOn];
}

- (IBAction)resAutoMarkChanged:(id)sender
{
}

- (IBAction)onTreeModeChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    [Env setTreeModeConfig:segment.selectedSegmentIndex];
}

- (IBAction)onAutoMarkChanged:(id)sender
{
    UISwitch *swi = (UISwitch *)sender;
    [Env setAutoMarkEnabled:swi.isOn];
}

// 0:no 1: auto download
- (IBAction)onThumbnailModeChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    [Env setThumbnailMode:segment.selectedSegmentIndex];
}

// 0:tiny 1:middle 2:huge
- (IBAction)onThumbnailSizeTypeChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    [Env setThumbnailSizeType:segment.selectedSegmentIndex];
}

//  self.thumbnailSizeSegment.selectedSegmentIndex = [Env getThumbnailSizeType];
- (IBAction)deleteCookieAction:(id)sender
{
    [[CookieManager sharedManager] deleteAllCookie];
}

- (IBAction)syncCryptPasswordEditingEnd:(id)sender
{
    [Env setConfString:self.syncCryptPasswordTextField.text forKey:@"syncCryptPass"];
}

- (IBAction)syncLevelChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    [Env setConfInteger:segment.selectedSegmentIndex forKey:@"syncCryptLevel"];
}

- (IBAction)screenModeValueChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    BOOL tabletMode = segment.selectedSegmentIndex == 1;
    [Env setConfBOOL:tabletMode forKey:@"tabletMode"];
    [[MySplitVC instance] changeTabletMode:tabletMode];
}

- (IBAction)autoSyncSegmentChanged:(id)sender
{
    UISwitch *swi = (UISwitch *)sender;
    [Env setConfBOOL:swi.isOn forKey:@"autoSync"];

    //自動同期のON/OFF
    if (swi.isOn) {
        [[SyncManager sharedManager] startAutoSync];
    } else {
        [[SyncManager sharedManager] stopAutoSync];
    }
}
- (IBAction)sync2chUrlButtonAction:(id)sender
{
    NSURL *nsurl = [NSURL URLWithString:@"http://sync2ch.com/about"];
    [[UIApplication sharedApplication] openURL:nsurl];
}

- (IBAction)onSyncCryptPasswordVisibleTap:(id)sender
{
    [self.syncCryptPasswordTextField setSecureTextEntry:!self.syncCryptPasswordTextField.secureTextEntry];
}

- (IBAction)resetConvertScript:(id)sender
{
    NSString *localpath = [[NSBundle mainBundle] pathForResource:@"external_script" ofType:@"js"];
    NSString *localjsCode = [NSString stringWithContentsOfFile:localpath encoding:NSUTF8StringEncoding error:nil];
    self.convertScriptTextField.text = localjsCode;
}

@end
