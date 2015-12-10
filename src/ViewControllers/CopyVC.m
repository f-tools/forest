//
//  CopyVC.m
//  Forest
//

#import "CopyVC.h"
#import "Views.h"
#import "ThemeManager.h"
#import "BaseModalNavigationVC.h"
#import "Env.h"

@interface CopyVC ()

@end

@implementation CopyVC

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

    [Views makeSeparator:self.leftSeparator];
    [Views makeSeparator:self.rightSeparator];
    [Views makeSeparator:self.centerSeparator];
    [Views makeSeparator:self.border1];
    [Views makeSeparator:self.border2];
    [Views makeSeparator:self.topBorder];

    UIColor *mainBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    UIColor *tabBorderColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];
    UIColor *normalColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];

    self.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];
    self.view.backgroundColor = mainBackgroundColor;
    self.textView.backgroundColor = mainBackgroundColor;
    self.textView.textColor = normalColor;
    self.textView.text = self.text;
    self.textView.keyboardAppearance = [[ThemeManager sharedManager] useBlackKeyboard] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceDefault;
    [self.textView becomeFirstResponder];
    self.leftLabel.textColor = normalColor;
    self.rightLabel.textColor = normalColor;

    self.cancelButton.backgroundColor = mainBackgroundColor;
    self.searchButton.backgroundColor = mainBackgroundColor;
    self.textCopyButton.backgroundColor = mainBackgroundColor;

    self.leftSeparator.backgroundColor = tabBorderColor;
    self.rightSeparator.backgroundColor = tabBorderColor;
    self.centerSeparator.backgroundColor = tabBorderColor;
    self.border1.backgroundColor = tabBorderColor;
    self.border2.backgroundColor = tabBorderColor;
    self.topBorder.backgroundColor = tabBorderColor;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.leftRightButton addGestureRecognizer:longPress];

    longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.leftLeftButton addGestureRecognizer:longPress];

    longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.rightLeftButton addGestureRecognizer:longPress];

    longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.rightRightButton addGestureRecognizer:longPress];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [self.view convertRect:[[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.bottomConstraint.constant = keyboardFrame.size.height+2;
    [UIView animateWithDuration:duration
                     animations:^{
                       [self.view layoutIfNeeded];
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
                     }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSRange)validateRange:(NSInteger)location length:(NSInteger)length
{
    NSInteger textLength = [self.textView.text length];

    if (location < 0) {
        location = 0;
    } else if (location <= textLength == NO) {
        location = textLength;
    }

    if (location + length <= textLength == NO) {
        length = textLength - location;
    }
    return NSMakeRange(location, length);
}

- (IBAction)onLeftLeftButtonAction:(id)sender
{
    NSRange range = self.textView.selectedRange;
    self.textView.selectedRange = [self validateRange:range.location - 1 length:range.length + 1];
}

- (IBAction)onLeftRightButtonAction:(id)sender
{
    NSRange range = self.textView.selectedRange;
    self.textView.selectedRange = [self validateRange:range.location + 1 length:range.length == 0 ? 0 : range.length - 1];
}

- (IBAction)onRightLeftAction:(id)sender
{
    NSRange range = self.textView.selectedRange;
    self.textView.selectedRange = [self validateRange:(range.length == 0 ? range.location - 1 : range.location)length:range.length == 0 ? 0 : range.length - 1];
}

- (IBAction)onRightRightAction:(id)sender
{
    NSRange range = self.textView.selectedRange;
    self.textView.selectedRange = [self validateRange:range.location length:range.length + 1];
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
    if (self.leftRightButton == gesture.view) {
        [self onLeftRightButtonAction:gesture.view];
    } else if (self.leftLeftButton == gesture.view) {
        [self onLeftLeftButtonAction:gesture.view];

    } else if (self.rightRightButton == gesture.view) {
        [self onRightRightAction:gesture.view];
    } else if (self.rightLeftButton == gesture.view) {
        [self onRightLeftAction:gesture.view];
    }
}

- (IBAction)copyAction:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [self getCurrentText];
}

- (NSString *)getCurrentText
{
    if (self.textView.selectedRange.location == NSNotFound || self.textView.selectedRange.length == 0) {
        return self.textView.text;
    } else {
        return [self.textView.text substringWithRange:self.textView.selectedRange];
    }
}

- (NSString *)percentEscape:(NSString *)str
{
//str = [self removeEmoji:str];

    NSString *escapedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (CFStringRef)str,
        NULL,
        (CFStringRef) @"!*'();:@&=+$,/?%#[]<>",
        kCFStringEncodingUTF8));
    //kCFStringEncodingShiftJIS));
    return escapedUrlString;

}

- (IBAction)searchAction:(id)sender
{
    NSString *googleUrl = [NSString stringWithFormat:@"http://www.google.co.jp/search?q=%@", [self percentEscape:[self getCurrentText]]];
   // UINavigationController *nav = (UINavigationController *)self.navigationController;
    [self.navigationController openUrlInDefaultWay:googleUrl];
}

- (IBAction)ngWordAction:(id)sender
{
}

- (IBAction)allSelectAction:(id)sender
{
}


- (IBAction)cancelAction:(id)sender
{

    [self.navigationController dismissViewControllerAnimated:YES
                                                  completion:^{

                                                  }];
    /*
     if (self.shouldDismiss) {
     } else {
     [self.navigationController popToRootViewControllerAnimated:YES];
     if (notifyNGChange) {
     [[ThemeManager sharedManager] notifyThemeChanged:
     [NSDictionary dictionaryWithObjectsAndKeys:@"resBodySize", @"confChange", nil] ];
     }
     }
     */
}
@end
