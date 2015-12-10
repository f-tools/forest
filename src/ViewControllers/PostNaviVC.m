#import "Env.h"
#import "ThManager.h"
#import "ThemeManager.h"
#import "AppDelegate.h"
#import "SyncManager.h"
#import "MyNavigationVC.h"
#import "HistoryVC.h"
#import "Th+ParseAdditions.h"
#import "ThUpdater.h"
#import "ResVC.h"
#import "Transaction.h"
#import "BaseTableVC.h"
#import "PostNaviVC.h"
#import "PostConfirmVC.h"
#import "Views.h"
#import "PostActionMenu.h"
#import "MySplitVC.h"
#import "BaseModalNavigationVC.h"

@interface PostNaviVC ()

@property (nonatomic) BOOL introNextThread;
@property (nonatomic) BOOL proceedFromIntro;
@property (nonatomic) BOOL shouldReload;
@property (nonatomic) BOOL nextThreadMode;
@property (nonatomic) PostEditVC *postEditVC;
@property (nonatomic) PostThreadTitleVC *threadTitleVC;
@property (nonatomic, copy) NSString *res1Text;

@end

@implementation PostNaviVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.postEditVC = [[PostEditVC alloc] initWithNibName:@"PostEditView" bundle:nil];
    self.postEditVC.postNaviVC = self;

    self.threadTitleVC = [[PostThreadTitleVC alloc] initWithNibName:@"PostThreadTitleVC" bundle:nil];
    self.threadTitleVC.postNaviVC = self;

    [self pushViewController:self.threadTitleVC animated:NO];
    [self pushViewController:self.postEditVC animated:NO];
}

- (void)pushPostEditVC
{
    [self pushPostEditVCAnimated:YES];
}

- (void)pushPostEditVCAnimated:(BOOL)animated
{
    [self popToRootViewControllerAnimated:NO];
    [self pushViewController:self.postEditVC animated:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.introNextThread) {
        if (self.proceedFromIntro == NO) {
            [self popToRootViewControllerAnimated:NO];
            [self.threadTitleVC viewWillAppear:NO];
        } else {
            [self pushPostEditVCAnimated:NO];
        }
    } else {
        [self pushPostEditVCAnimated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.introNextThread = NO;
}

- (void)applyOriginThread:(Th *)originThread res1Text:(NSString *)res1Text
{
    Th *prevOriginTh = self.originThread;

    self.originThread = originThread;
    self.res1Text = res1Text;

    self.introNextThread = NO;
    if (originThread) {
        self.introNextThread = YES;
        if (prevOriginTh != originThread) {
            self.proceedFromIntro = NO;
            [self.threadTitleVC onOriginThreadChanged];
        }
    }
}

- (void)notifyPostSuccess
{
    [self.postEditVC clearBodyText];
}

- (void)addText:(NSString *)text
{
    [self.postEditVC addText:text];
}

@end



@interface PostEditVC ()

@property (weak, nonatomic) UITextField *nameTextView;
@property (weak, nonatomic) UITextField *mailTextView;
@property (weak, nonatomic) UITextView *bodyTextView;
@property (weak, nonatomic) UITextField *threadTitleTextView;

@property (weak, nonatomic) UIView *toolbar;

@property (nonatomic) UIView *innerView;

@end

//
//  PostThreadTitleVC.m
//  Forest
//
// 次スレ作成時
@interface PostThreadTitleVC ()

@end

@implementation PostThreadTitleVC

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
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.descriptionLabel.text = @"＊次スレタイトルを適切なものに編集してください\n(次の画面でも変更できます)\n\n次の画面の本文には元スレの「1」の本文と元スレのタイトルとURLが末尾に追記されています。";
    [self.descriptionLabel sizeToFit];

    self.prevTitleTextView.textContainerInset = UIEdgeInsetsMake(2, 4, 4, 4);
    self.prevTitleTextView.textContainer.lineFragmentPadding = 0;
    self.nextTextView.textContainerInset = UIEdgeInsetsMake(2, 4, 4, 4);
    self.nextTextView.textContainer.lineFragmentPadding = 0;
    //self.nextTextView.contentInset = UIEdgeInsetsMake(-4,0,0,0);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [self.cancelButton addTarget:self action:@selector(onCancelButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.continueButton addTarget:self action:@selector(onContinueButton:) forControlEvents:UIControlEventTouchUpInside];

    [self.duplicateButton addTarget:self action:@selector(onDuplicateButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)onDuplicateButton:(id)sender
{
    self.nextTextView.text = self.prevTitleTextView.text;
}

- (IBAction)onCancelButton:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onContinueButton:(id)sender
{
    [self.postNaviVC pushPostEditVC];
    self.postNaviVC.postEditVC.initialThreadTitle = self.nextTextView.text;
    self.postNaviVC.postEditVC.initialBodyText = [NSString stringWithFormat:@"%@\n\n前スレ\n%@\n%@", self.postNaviVC.res1Text, self.postNaviVC.originThread.title, [self.postNaviVC.originThread threadUrl]];

    self.postNaviVC.proceedFromIntro = YES;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [self.view convertRect:[[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.bottomConstraint.constant = keyboardFrame.size.height;
    myLog(@"%lu", keyboardFrame.size.height);
    [UIView animateWithDuration:duration
                     animations:^{
                       [self.view layoutIfNeeded];
                       [self.buttonsContainer layoutIfNeeded];
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
                       [self.buttonsContainer layoutIfNeeded];
                     }];
}

- (void)onOriginThreadChanged
{
    NSString *prevTitle = self.postNaviVC.originThread.title;
    self.prevTitleTextView.text = prevTitle;
    self.nextTextView.text = [self changeNextTitle:prevTitle];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.title = @"次スレタイトル決定";
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    [self onOriginThreadChanged];

    self.nextTextView.keyboardAppearance = [[ThemeManager sharedManager] useBlackKeyboard] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceDefault;

    UIColor *tabBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
    UIColor *mainBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    UIColor *tabBorderColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    UIColor *normalColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    UIColor *subTextColor = [[ThemeManager sharedManager] colorForKey:ThemeSubTextColor];


    [Views makeSeparator:self.border];
    [Views makeSeparator:self.centerSeparator];
    self.border.backgroundColor = tabBorderColor;
    self.centerSeparator.backgroundColor = tabBorderColor;

    self.cancelButton.backgroundColor = tabBackgroundColor;
    self.continueButton.backgroundColor = tabBackgroundColor;

    self.prevThreadLabel.textColor = subTextColor;
    self.prevTitleTextView.textColor = subTextColor;
    self.nextLabel.textColor = normalColor;
    self.nextTextView.textColor = normalColor;
    self.descriptionLabel.textColor = subTextColor;

    self.prevThreadLabel.backgroundColor = tabBackgroundColor;
    self.prevTitleTextView.backgroundColor = tabBackgroundColor;
    self.nextLabel.backgroundColor = tabBackgroundColor;
    self.nextTextView.backgroundColor = mainBackgroundColor;
    self.descriptionLabel.backgroundColor = tabBackgroundColor;

    [self.nextTextView becomeFirstResponder];

    self.nextTextView.layer.borderWidth = 0.5f;
    self.nextTextView.layer.cornerRadius = 4.5f;

    self.nextTextView.layer.borderColor = tabBorderColor.CGColor;

    self.view.backgroundColor = tabBackgroundColor;
}

- (NSString *)changeNextTitle:(NSString *)title
{
    BOOL isInNumber = NO;
    NSInteger start = 0;
    NSInteger end;

    NSInteger count = [title length];
    for (NSInteger i = count - 1; i >= 0; i--) {
        NSString *substr = [title substringWithRange:NSMakeRange(i, 1)];
        BOOL isNumber = [self isNumber:substr];

        if (isInNumber) {
            if (!isNumber) {
                start = i + 1;
                break;
            }
        } else {
            if (isNumber) {
                isInNumber = YES;
                end = i;
            }
        }
    }

    if (isInNumber) {
        return [NSString stringWithFormat:@"%@%zd%@", [title substringToIndex:start], [[title substringWithRange:NSMakeRange(start, end - start + 1)] integerValue] + 1, [title substringFromIndex:end + 1]];
    } else {
        return [NSString stringWithFormat:@"%@ Part 2", title];
    }
}

- (BOOL)isNumber:(NSString *)str
{

    if ([str isEqualToString:@"0"]) return YES;
    if ([str isEqualToString:@"1"]) return YES;
    if ([str isEqualToString:@"2"]) return YES;
    if ([str isEqualToString:@"3"]) return YES;
    if ([str isEqualToString:@"4"]) return YES;
    if ([str isEqualToString:@"5"]) return YES;
    if ([str isEqualToString:@"6"]) return YES;
    if ([str isEqualToString:@"7"]) return YES;
    if ([str isEqualToString:@"8"]) return YES;
    if ([str isEqualToString:@"9"]) return YES;

    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

@implementation PostEditVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)addText:(NSString *)text
{
    self.bodyTextView.text = [NSString stringWithFormat:@"%@%@", self.bodyTextView.text, text];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.nameTextView = (UITextField *)[self.view viewWithTag:1];
    self.mailTextView = (UITextField *)[self.view viewWithTag:2];
    self.bodyTextView = (UITextView *)[self.view viewWithTag:3];
    self.threadTitleTextView = (UITextField *)[self.view viewWithTag:4];

    self.innerView = [self.view viewWithTag:5];

    if (self.postNaviVC.board) {
        for (NSLayoutConstraint *constraint in self.threadTitleTextView.constraints) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                constraint.constant = 40;
            }
        }
    } else {
        self.threadTitleContainerHeightConstraint.constant = 0;
    }

    self.bodyTextView.delegate = self;

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"戻る"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(backPressed:)];

    self.navigationItem.leftBarButtonItem = backButton;

    UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithTitle:@"書き込み"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(beginPost:)];

    self.navigationItem.rightBarButtonItem = postButton;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)viewWillAppear:(BOOL)animated
{

    UILabel *nameLabel = (UILabel *)[self.view viewWithTag:6];
    UILabel *mailLabel = (UILabel *)[self.view viewWithTag:7];
    UILabel *threadTitleLLabel = (UILabel *)[self.view viewWithTag:8];

    UIImage *image = [UIImage imageNamed:@"credit.png"];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.accountButton setImage:image forState:UIControlStateNormal];

    [self setLabelStyle:nameLabel];
    [self setLabelStyle:mailLabel];
    [self setLabelStyle:threadTitleLLabel];

    self.toolbarTopBorder.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    self.toolbarTopBorderHeightConstraint.constant = thinLineWidth;
    self.bottomToolbar.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
    for (UIView *subview in self.toolbar.subviews) {
        UIButton *button = (UIButton *)subview;
        [button setTitleColor:[[ThemeManager sharedManager] colorForKey:ThemeNormalColor] forState:UIControlStateNormal];
    }

    self.nameBottomBorderHeightConstraint.constant = thinLineWidth;
    self.mailBottomBorderHeightConstraint.constant = thinLineWidth;
    self.threadTitleBottomBorderHeightConstraint.constant = thinLineWidth;
    self.nameTopBorderHeightConstraint.constant = thinLineWidth;

    self.nameTopBorderView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];

    self.nameBottomBorder.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    self.mailBottomBorder.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    self.threadTitleBottomBorder.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];

    [self setTextFieldStyle:self.nameTextView];
    [self setTextFieldStyle:self.mailTextView];
    [self setTextViewStyle:self.bodyTextView];
    [self setTextFieldStyle:self.threadTitleTextView];

    if (self.initialBodyText) {
        self.bodyTextView.text = self.initialBodyText;
        self.initialBodyText = nil;
    }
    if (self.initialThreadTitle) {
        self.threadTitleTextView.text = self.initialThreadTitle;
        self.initialThreadTitle = nil;
    }

    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

    self.title = self.postNaviVC.board ? self.postNaviVC.board.boardName : self.postNaviVC.th.title;

    [self.navigationController setNavigationBarHidden:YES animated:NO];
    //  [self fitToSuperview:self.view];
    //self.textView.text = self.favFolder.name;
    //self.textView.editable = YES;

    [self.bodyTextView becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)clearBodyText
{
    self.bodyTextView.text = @"";
}

- (void)beginPost:(id)sender
{
}

- (void)backPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [self.view convertRect:[[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.bottomConstraint.constant = keyboardFrame.size.height;
    myLog(@"%lu", keyboardFrame.size.height);
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


- (void)setTextFieldStyle:(UITextField *)textView
{
    if (textView) {
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        textView.keyboardAppearance = [[ThemeManager sharedManager] useBlackKeyboard] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceDefault;
        textView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
        textView.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    }
}

- (void)setTextViewStyle:(UITextView *)textView
{
    if (textView) {
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        textView.keyboardAppearance = [[ThemeManager sharedManager] useBlackKeyboard] ? UIKeyboardAppearanceAlert
                                                                                      : UIKeyboardAppearanceDefault;
        textView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
        textView.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
        [textView setFont:[UIFont systemFontOfSize:14]];
    }
}

- (void)setLabelStyle:(UILabel *)textView
{
    if (textView) {
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        textView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
        textView.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
        [textView setFont:[UIFont systemFontOfSize:14]];
    }
}


- (IBAction)backInToolbar:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)postButtonTapAction:(id)sender
{
    PostConfirmVC *confirmVC = [[PostConfirmVC alloc] initWithNibName:@"PostConfirmVC" bundle:nil];
    confirmVC.postNaviVC = self.postNaviVC;
    confirmVC.name = self.nameTextView.text;
    confirmVC.mail = self.mailTextView.text;
    confirmVC.threadTitle = self.threadTitleTextView.text;
    confirmVC.text = self.bodyTextView.text;

    [confirmVC.postNaviVC pushViewController:confirmVC animated:YES];
}

- (IBAction)moveRightButtonAction:(id)sender
{
    if ([self moveCursorIfPossible:self.bodyTextView offset:1])
        ;
    else if ([self moveCursorIfPossible:self.nameTextView offset:1])
        ;
    else if ([self moveCursorIfPossible:self.mailTextView offset:1])
        ;
    else if ([self moveCursorIfPossible:self.threadTitleTextView offset:1]) {
    }
}

- (IBAction)onAccountButtonAction:(id)sender
{

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"AccountConf" bundle:nil];

    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"acountConfNavigationVC"];

    [self presentViewController:vc animated:YES completion:nil];
}

- (BOOL)moveCursorIfPossible:(id)textView offset:(NSInteger)offset
{
    if ([textView isKindOfClass:[UITextView class]]) {
        UITextView *textView2 = (UITextView *)textView;
        if (textView2.isFirstResponder) {
            NSInteger newOffset = textView2.selectedRange.location + offset;
            if (newOffset >= 0) {
                textView2.selectedRange = NSMakeRange(newOffset, 0);
            }
            return YES;
        }
        return NO;
    }

    UITextField *textView3 = (UITextField *)textView;
    if (textView3.isFirstResponder) {
        UITextRange *range = textView3.selectedTextRange;
        UITextPosition *pos = [textView3 positionFromPosition:range.start inDirection:offset > 0 ? UITextLayoutDirectionRight : UITextLayoutDirectionLeft offset:offset * offset];
        UITextRange *newRange = [textView3 textRangeFromPosition:pos toPosition:pos];

        textView3.selectedTextRange = newRange;

        return YES;
    }

    return NO;
}

- (IBAction)moveLeftButtonAction:(id)sender
{
    NSInteger offset = -1;
    if ([self moveCursorIfPossible:self.bodyTextView offset:offset])
        ;
    else if ([self moveCursorIfPossible:self.nameTextView offset:offset])
        ;
    else if ([self moveCursorIfPossible:self.mailTextView offset:offset])
        ;
    else if ([self moveCursorIfPossible:self.threadTitleTextView offset:offset]) {
    }
}

- (IBAction)onMoreAction:(id)sender
{
    BaseModalNavigationVC *naviVC = (BaseModalNavigationVC *)self.navigationController;
    PostActionMenu *menu = [[PostActionMenu alloc] init];
    menu.onAddedText = ^(NSString *text) {
      self.bodyTextView.text = [NSString stringWithFormat:@"%@%@", self.bodyTextView.text, text];
      [self.bodyTextView becomeFirstResponder]; //duplicate process in viewwillAppear
    };
    menu.onDeleteRequest = ^{
      self.bodyTextView.text = @"";
      [self.bodyTextView becomeFirstResponder];
    };
    menu.navigationController = naviVC;

    [self.bodyTextView resignFirstResponder];
    [self.nameTextView resignFirstResponder];
    [self.mailTextView resignFirstResponder];
    [self.threadTitleTextView resignFirstResponder];

    [menu build];
    [naviVC openActionMenu:menu];
}
@end
