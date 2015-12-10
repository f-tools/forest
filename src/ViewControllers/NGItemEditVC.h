//
//  NGItemEditVC.h
//  Forest
//

#import <UIKit/UIKit.h>

#import "NGManager.h"

@class Board;

@interface NGItemEditVC : UIViewController

@property (nonatomic) NGItem *ngItem;
@property (nonatomic) BOOL initialMode;
//@property (nonatomic) BOOL shouldDismiss; //NOの場合は、popviewすべき

- (void)refreshBoardInfo;

@property (weak, nonatomic) IBOutlet UIView *bottomButtonContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomSpaceConstraint;

@property (weak, nonatomic) IBOutlet UISwitch *transparentSwitch;
- (IBAction)transparentSwitchChanged:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *chainSwitch;
- (IBAction)chainSwitchChanged:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *regexSwitch;
- (IBAction)regexSwitchChanged:(id)sender;

@property (weak, nonatomic) IBOutlet UITextView *valueTextView;

@property (weak, nonatomic) IBOutlet UIButton *applyButton;
- (IBAction)onApplyButtonAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
- (IBAction)onApplyButtonTouchUp:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
- (IBAction)deleteButtonAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *boardSelectButton;
- (IBAction)onBoardSelectButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *transparentLabel;
@property (weak, nonatomic) IBOutlet UILabel *chainLabel;
@property (weak, nonatomic) IBOutlet UILabel *regexLabel;

@property (weak, nonatomic) IBOutlet UIView *separator1;
@property (weak, nonatomic) IBOutlet UIView *separator2;
@property (weak, nonatomic) IBOutlet UIView *leftSeparator;
@property (weak, nonatomic) IBOutlet UIView *rightSeparator;
@end
