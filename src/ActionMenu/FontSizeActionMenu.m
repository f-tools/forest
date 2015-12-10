//
//  FontSizeActionMenu.m
//  Forest
//

#import "ThItemActionMenu.h"
#import "MyNavigationVC.h"
#import "ThListTransaction.h"
#import "BoardManager.h"
#import "ThManager.h"
#import "ActionLayout.h"
#import "ThemeManager.h"
#import "Env.h"

#import "FontSizeActionMenu.h"

@interface FontSizeActionMenu ()

@property (nonatomic, weak) UILabel *titleSizeLabel;
@property (nonatomic, weak) UILabel *metaSizeLabel;

@end

@implementation FontSizeActionMenu

static const NSInteger kTitleSizeValueLabelTag = 1;
static const NSInteger kTitleSizeNameLabelTag = 10;
static const NSInteger kMetaSizeNameLabelSize = 4;
static const NSInteger kMetaSizeValueLabelSize = 5;

static const NSInteger kSeparatorTag = 11;

static const NSInteger kTitleMinusButtonTag = 2;
static const NSInteger kTitlePlusButtonTag = 3;
static const NSInteger kMetaMinusButtonTag = 6;
static const NSInteger kMetaPlusButtonTag = 7;


- (void)dealloc
{
}

// @override
- (void)build
{
    CGSize size = [UIScreen mainScreen].bounds.size;

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    CGFloat windowWidth = size.width;
    CGFloat windowHeight = size.height;
    if (orientation == 0 || orientation == UIInterfaceOrientationPortrait) {

    } else if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        windowWidth = size.height;
        windowHeight = size.width;
    }

    UINib *nib = [UINib nibWithNibName:@"FontSizeView" bundle:[NSBundle mainBundle]];
    NSArray *array = [nib instantiateWithOwner:self options:nil];

    UIView *view = [array objectAtIndex:0];

    self.titleSizeLabel = (UILabel *)[view viewWithTag:kTitleSizeValueLabelTag];
    self.metaSizeLabel = (UILabel *)[view viewWithTag:kMetaSizeValueLabelSize];

    UIColor *foregroundColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    UIColor *backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];

    [(UILabel *)[view viewWithTag:kTitleSizeNameLabelTag] setText:self.forRes ? @"ヘッダー" : @"タイトル"];
    [(UILabel *)[view viewWithTag:kMetaSizeNameLabelSize] setText:self.forRes ? @"本文" : @"日付等"];
    [(UILabel *)[view viewWithTag:kTitleSizeNameLabelTag] setTextColor:foregroundColor];
    [(UILabel *)[view viewWithTag:kMetaSizeNameLabelSize] setTextColor:foregroundColor];
    [self.titleSizeLabel setTextColor:foregroundColor];
    [self.metaSizeLabel setTextColor:foregroundColor];

    UIView *separator = [view viewWithTag:kSeparatorTag];
    NSLayoutConstraint *heightConstraint = [separator.constraints objectAtIndex:0];
    heightConstraint.constant = thinLineWidth;
    separator.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];

    UIButton *titleMinus = (UIButton *)[view viewWithTag:kTitleMinusButtonTag];
    UIButton *titlePlus = (UIButton *)[view viewWithTag:kTitlePlusButtonTag];
    UIButton *metaMinus = (UIButton *)[view viewWithTag:kMetaMinusButtonTag];
    UIButton *metaPlus = (UIButton *)[view viewWithTag:kMetaPlusButtonTag];

    [self _changeButtonStyle:titleMinus asTouch:NO];
    [self _changeButtonStyle:titlePlus asTouch:NO];
    [self _changeButtonStyle:metaMinus asTouch:NO];
    [self _changeButtonStyle:metaPlus asTouch:NO];

    [titleMinus addTarget:self
                   action:@selector(onButtonTouchUpInside:)
         forControlEvents:UIControlEventTouchUpInside];
    [titlePlus addTarget:self
                  action:@selector(onButtonTouchUpInside:)
        forControlEvents:UIControlEventTouchUpInside];
    [metaMinus addTarget:self
                  action:@selector(onButtonTouchUpInside:)
        forControlEvents:UIControlEventTouchUpInside];
    [metaPlus addTarget:self
                  action:@selector(onButtonTouchUpInside:)
        forControlEvents:UIControlEventTouchUpInside];

    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view addConstraints:@[
        [NSLayoutConstraint constraintWithItem:view
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0
                                      constant:101]
    ]];
    //[view viewWithTag:0];
    self.view = view;
    self.view.backgroundColor = backgroundColor;
    [self updateSizeLabel];
}

- (void)updateSizeLabel
{
    //
    NSInteger increment = self.forRes ? [Env getResHeaderSizeIncrement] : [Env getThreadTitleSizeIncrement];
    CGFloat diff = (increment) / 2.f;
    NSString *titleSizeString = increment == 0 ? @"±0" : [NSString stringWithFormat:(diff < 0.1f ? @"%1.1f" : @"+%1.1f"), diff];
    [self.titleSizeLabel setText:titleSizeString];

    increment = self.forRes ? [Env getResBodySizeIncrement] : [Env getThreadMetaSizeIncrement];
    diff = (increment) / 2.f;
    NSString *metaSizeString = increment == 0 ? @"±0" : [NSString stringWithFormat:(diff < 0.1f ? @"%1.1f" : @"+%1.1f"), diff];
    [self.metaSizeLabel setText:metaSizeString];
}

// @override
- (NSArray *)createAllButtons
{
    return nil;
}

- (IBAction)onButtonTouchUpInside:(id)sender
{
    UIButton *button = sender;

    if (self.forRes) {
        if (button.tag == kTitleMinusButtonTag) {
            [Env setResHeaderSize:[Env getResHeaderSizeIncrement] - 1];
        } else if (button.tag == kTitlePlusButtonTag) {
            [Env setResHeaderSize:[Env getResHeaderSizeIncrement] + 1];
        } else if (button.tag == kMetaMinusButtonTag) {
            [Env setResBodySize:[Env getResBodySizeIncrement] - 1];
        } else if (button.tag == kMetaPlusButtonTag) {
            [Env setResBodySize:[Env getResBodySizeIncrement] + 1];
        }
    } else {
        if (button.tag == kTitleMinusButtonTag) {
            [Env setThreadTitleSize:[Env getThreadTitleSizeIncrement] - 1];
        } else if (button.tag == kTitlePlusButtonTag) {
            [Env setThreadTitleSize:[Env getThreadTitleSizeIncrement] + 1];
        } else if (button.tag == kMetaMinusButtonTag) {
            [Env setThreadMetaSize:[Env getThreadMetaSizeIncrement] - 1];
        } else if (button.tag == kMetaPlusButtonTag) {
            [Env setThreadMetaSize:[Env getThreadMetaSizeIncrement] + 1];
        }
    }
    [self updateSizeLabel];
}

@end
