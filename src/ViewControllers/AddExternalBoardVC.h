//
//  AddExternalBoardVC.h
//  Forest
//

#import <UIKit/UIKit.h>

@interface AddExternalBoardVC : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *boardNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *fetchNameButton;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;

@property (weak, nonatomic) IBOutlet UIView *centerSeparator;
@property (weak, nonatomic) IBOutlet UIView *innerView;
@property (weak, nonatomic) IBOutlet UIView *border;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@property (copy, nonatomic) void (^onAddBoardCompleted)(BOOL success);

- (IBAction)cancelAction:(id)sender;
- (IBAction)addBoardAction:(id)sender;

@end
