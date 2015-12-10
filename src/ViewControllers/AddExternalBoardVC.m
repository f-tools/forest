//
//  AddExternalBoardVC.m
//  Forest
//

#import "AddExternalBoardVC.h"
#import "Board.h"
#import "BoardManager.h"
#import "ThemeManager.h"
#import "Env.h"
#import "Views.h"
#import "BoardVC.h"
#import "Category.h"

#import "ThManager.h"
#import "AppDelegate.h"
#import "CookieManager.h"
#import "MyNavigationVC.h"
#import "HistoryVC.h"
#import "ThUpdater.h"
#import "TextUtils.h"

@interface AddExternalBoardVC ()

@end

@implementation AddExternalBoardVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [Views makeSeparator:self.centerSeparator];
    [Views makeSeparator:self.border];

    //
    NSString *description = @"板のURLと名前を入力指定してください\n\n URLの例) http://jbbs.shitaraba.net/computer/44177/\n\n";

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    self.descriptionTextView.text = description;
}

- (void)viewWillAppear:(BOOL)animated
{

    UIColor *tabBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
    UIColor *mainBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    UIColor *tabBorderColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    UIColor *normalColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];

    self.centerSeparator.backgroundColor = tabBorderColor;
    self.border.backgroundColor = tabBorderColor;
    self.cancelButton.backgroundColor = tabBackgroundColor;
    self.addButton.backgroundColor = tabBackgroundColor;

    self.descriptionTextView.backgroundColor = mainBackgroundColor;
    self.descriptionTextView.textColor = normalColor;

    [self.urlTextField becomeFirstResponder];
    self.urlLabel.textColor = normalColor;
    self.nameLabel.textColor = normalColor;

    self.view.backgroundColor = mainBackgroundColor;
    self.innerView.backgroundColor = mainBackgroundColor;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [self.view convertRect:[[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.bottomConstraint.constant = keyboardFrame.size.height;

    [UIView animateWithDuration:duration
                     animations:^{
                       [self.view layoutIfNeeded];
                       [self.innerView layoutIfNeeded];
                     }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.bottomConstraint.constant = 0;

    [UIView animateWithDuration:duration
                     animations:^{
                       [self.view layoutIfNeeded];
                       [self.innerView layoutIfNeeded];
                     }];
}

- (void)addExternalBoard
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)addBoardAction:(id)sender
{
    NSString *url = self.urlTextField.text;
    NSString *boardName = self.boardNameTextField.text;

    BoardManager *bm = [BoardManager sharedManager];

    Board *board = [Board boardFromUrl:url];
    if ([url length] > 5 && board && [boardName length] > 0) {
        board.boardName = boardName;
        board = [bm registerBoard:board];
        [bm addExternalBoard:board];

        [self dismissViewControllerAnimated:YES
                                 completion:^{

                                   if (self.onAddBoardCompleted != nil) {
                                       self.onAddBoardCompleted(board != nil);
                                   }
                                   self.onAddBoardCompleted = nil;
                                 }];
    }
}
@end
