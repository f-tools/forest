//
//  CopyVC.h
//  Forest
//

#import <UIKit/UIKit.h>
@class FXBlurView;

@class ResVC;

@interface CopyVC : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *leftLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *leftRightButton;
@property (weak, nonatomic) IBOutlet UIButton *rightLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightRightButton;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet FXBlurView *buttonsContainer;

@property (nonatomic, copy) NSString *text;
@property (weak, nonatomic) IBOutlet UILabel *leftLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightLabel;
@property (weak, nonatomic) IBOutlet UIView *topBorder;

- (IBAction)onLeftLeftButtonAction:(id)sender;
- (IBAction)onLeftRightButtonAction:(id)sender;
- (IBAction)onRightLeftAction:(id)sender;
- (IBAction)onRightRightAction:(id)sender;

- (IBAction)copyAction:(id)sender;
- (IBAction)searchAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UIButton *textCopyButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@property (weak, nonatomic) IBOutlet UIView *leftSeparator;
@property (weak, nonatomic) IBOutlet UIView *rightSeparator;
@property (weak, nonatomic) IBOutlet UIView *centerSeparator;
@property (weak, nonatomic) IBOutlet UIView *border1;
@property (weak, nonatomic) IBOutlet UIView *border2;

@property (copy, nonatomic) void (^onResSearchRequest)(NSString *searchText);
@end
