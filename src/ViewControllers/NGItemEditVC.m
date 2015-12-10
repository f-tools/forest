//
//  NGItemEditVC.m
//  Forest
//

#import "NGItemEditVC.h"
#import "ThemeManager.h"
#import "Env.h"
#import "ThManager.h"
#import "AppDelegate.h"
#import "CookieManager.h"
#import "MyNavigationVC.h"
#import "HistoryVC.h"
#import "ThUpdater.h"
#import "ResVC.h"
#import "TextUtils.h"
#import "AccountConfVC.h"
#import "BoardVC.h"
#import "BaseModalNavigationVC.h"
#import "Views.h"

@interface NGItemEditVC ()

@end

@implementation NGItemEditVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{

    self.title = [self.ngItem typeString]; // @"NG編集";
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    if (self.ngItem) {
        if (self.initialMode) {
            [self.transparentSwitch setOn:[Env getConfBOOLForKey:
                                                   [NSString stringWithFormat:@"initialTransparent%ld", (long)self.ngItem.type]
                                                     withDefault:NO]];

            [self.chainSwitch setOn:[Env getConfBOOLForKey:
                                             [NSString stringWithFormat:@"initialChain%ld", (long)self.ngItem.type]
                                               withDefault:NO]];

            [self.regexSwitch setOn:NO];

        } else {
            [self.regexSwitch setOn:self.ngItem.regex];
            [self.transparentSwitch setOn:self.ngItem.transparent];
            [self.chainSwitch setOn:self.ngItem.chain];
        }

        if (self.ngItem.type == 2) { //2:NG Thread
            [self.transparentSwitch setOn:YES];
            [self.transparentSwitch setEnabled:NO];

            [self.chainSwitch setEnabled:NO];
        }

        self.valueTextView.text = self.ngItem.value;
    }

    if (self.initialMode) {
        [self.applyButton setTitle:@"登録" forState:UIControlStateNormal];
        [self.cancelButton setTitle:@"キャンセル" forState:UIControlStateNormal];
        [self.deleteButton setEnabled:NO];
    } else {
        [self.applyButton setTitle:@"変更" forState:UIControlStateNormal];
        [self.cancelButton setTitle:@"戻る" forState:UIControlStateNormal];
        [self.deleteButton setEnabled:YES];
    }

    [Views makeSeparator:self.separator1];
    [Views makeSeparator:self.separator2];
    [Views makeSeparator:self.leftSeparator];
    [Views makeSeparator:self.rightSeparator];

    [self refreshBoardInfo];

    [self changeTheme];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [self.view convertRect:[[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.bottomSpaceConstraint.constant = keyboardFrame.size.height+2;
    myLog(@"%lu", keyboardFrame.size.height);
    [UIView animateWithDuration:duration
                     animations:^{
                       [self.view layoutIfNeeded];
                       [self.bottomButtonContainer layoutIfNeeded];
                     }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.bottomSpaceConstraint.constant = 0;

    [UIView animateWithDuration:duration
                     animations:^{
                       [self.view layoutIfNeeded];
                       [self.bottomButtonContainer layoutIfNeeded];
                     }];
}


- (void)refreshBoardInfo
{
    NSString *boardStr = @"板: 全体 ▼";
    if (self.ngItem.board) {
        boardStr = [NSString stringWithFormat:@"板: %@ ▼", self.ngItem.board.boardName];
    }
    [self.boardSelectButton setTitle:boardStr forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self changeTheme];

    self.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];
    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

    self.separator1.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];
    self.separator2.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];
    self.leftSeparator.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];
    self.rightSeparator.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];

    self.valueTextView.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    //self.valueTextView.backgroundColor =[[ThemeManager sharedManager] colorForKey:ThemeNormalColor];

    self.applyButton.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
    self.cancelButton.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
    self.deleteButton.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];

    self.transparentLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    self.regexLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    self.chainLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];

    self.valueTextView.keyboardAppearance = [[ThemeManager sharedManager] useBlackKeyboard] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceDefault;
}

- (void)changeTheme
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)onBoardSelectButtonAction:(id)sender
{
    __weak NGItemEditVC *weakSelf = self;

    BoardSelectNavigationController *naviCon = [[BoardSelectNavigationController alloc] init];

    [self.navigationController presentViewController:naviCon
                                            animated:YES
                                          completion:^{
                                            naviCon.boardVC.selectBoardMode = YES;

                                            //boardVC  選択された場合のブロックを定義
                                            naviCon.boardVC.completionBlock = ^(Board *board) {

                                              if (weakSelf.initialMode) {
                                                  weakSelf.ngItem.board = board;
                                              } else {
                                                  [[NGManager sharedManager] changeNGItemBoard:weakSelf.ngItem board:board];
                                              }
                                              [weakSelf refreshBoardInfo];
                                            };

                                          }];
}

- (IBAction)transparentSwitchChanged:(id)sender
{
    UISwitch *switchButton = sender;
    self.ngItem.transparent = switchButton.isOn;
    if (switchButton.isOn) { //透明の場合は連鎖のみ
        if (self.chainSwitch.isOn == NO) {
            [self.chainSwitch setOn:YES];
        }
        self.ngItem.chain = YES;
    }
}
- (IBAction)chainSwitchChanged:(id)sender
{
    UISwitch *switchButton = sender;
    self.ngItem.chain = switchButton.isOn;
}
- (IBAction)regexSwitchChanged:(id)sender
{
    UISwitch *switchButton = sender;
    self.ngItem.regex = switchButton.isOn;
}

- (IBAction)onApplyButtonAction:(id)sender
{
    self.ngItem.value = self.valueTextView.text;
    self.ngItem.transparent = self.transparentSwitch.isOn;
    self.ngItem.chain = self.chainSwitch.isOn;
    self.ngItem.regex = self.regexSwitch.isOn;

    if (self.initialMode) {
        [[NGManager sharedManager] addNGItem:self.ngItem];
        [Env setConfBOOL:self.ngItem.transparent forKey:[NSString stringWithFormat:@"initialTransparent%ld", (long)self.ngItem.type]];
        [Env setConfBOOL:self.ngItem.chain forKey:[NSString stringWithFormat:@"initialChain%ld", (long)self.ngItem.type]];
    } else {
        [[NGManager sharedManager] changeNGItemInfo:self.ngItem];
    }

    [self backPage:YES];
}

//キャンセル？
- (IBAction)onApplyButtonTouchUp:(id)sender
{
    [self backPage:NO];
}

- (IBAction)deleteButtonAction:(id)sender
{
    if (self.initialMode == NO) {
        [[NGManager sharedManager] removeNGItem:self.ngItem];
    }
    [self backPage:YES];
}

- (void)backPage:(BOOL)notifyNGChange
{
    if ([self.navigationController.viewControllers count] == 1) {
        [self.navigationController dismissViewControllerAnimated:YES
                                                      completion:^{
                                                        if (notifyNGChange) {
                                                            [[ThemeManager sharedManager] notifyThemeChanged:
                                                                                              [NSDictionary dictionaryWithObjectsAndKeys:@"resBodySize", @"confChange", nil]];
                                                        }
                                                      }];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
        if (notifyNGChange) {
            [[ThemeManager sharedManager] notifyThemeChanged:
                                              [NSDictionary dictionaryWithObjectsAndKeys:@"resBodySize", @"confChange", nil]];
        }
    }
}

@end
