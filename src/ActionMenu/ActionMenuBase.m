#import "ActionMenuBase.h"
#import "MyNavigationVC.h"
#import "ThListTransaction.h"
#import "BoardManager.h"
#import "ThManager.h"
#import "ActionLayout.h"
#import "ThemeManager.h"
#import "MySplitVC.h"

@interface ActionMenuBase ()

@end

@implementation ActionMenuBase

- (void)dealloc
{
    // 通知を解除する
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self
                  name:@"themeChanged"
                object:nil];
}

- (id)init
{
    if (self = [super init]) {
        [self _init];
    }
    return self;
}

- (NSArray *)createAllButtons
{
    return nil;
}

- (void)open
{
    [[MySplitVC instance] openActionMenu:self];
}

- (void)_init
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(onThemeChanged:)
               name:@"themeChanged"
             object:nil];
}

- (NSArray *)createAboveViews
{
    return nil;
}

- (void)build
{
    ActionLayout *actionLayout = [[ActionLayout alloc] init];

    NSArray *actionButtons = [self createAllButtons];
    actionLayout.aboveViews = [self createAboveViews];

    CGSize size = [Env fixSize:[UIScreen mainScreen].bounds.size];

    if (self.isVerticalMode) {
        [actionLayout verticalLayout:actionButtons withWidth:size.width];
    } else {
        [actionLayout layout:actionButtons withWidth:size.width];
    }

    for (ActionButtonInfo *info in actionButtons) {
        [self setupButton:info];
    }

    [self onLayoutCompleted];

    _view = actionLayout.view;
}

// @abstract
- (void)onLayoutCompleted
{
}

- (void)applyTheme
{
    _view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

    for (ActionButtonInfo *info in [self createAllButtons]) {
        [self changeButtonStyle:info asTouch:NO];
    }
}

- (void)onThemeChanged:(NSNotification *)center
{
    [self applyTheme];
}

- (void)setupButton:(ActionButtonInfo *)info
{
    if (info.label) {
        info.label.text = info.title;
    }

    UIColor *backgroundColor = [UIColor clearColor];
    info.button.backgroundColor = backgroundColor;

    if (self.isVerticalMode) {
        [info.button setTitle:info.title forState:UIControlStateNormal];
    } else {
        info.button.layer.borderWidth = 1.f;
        info.button.layer.cornerRadius = 14.5f;
        if (info.buttonImageName) {
            UIImage *image = [UIImage imageNamed:info.buttonImageName]; //@"more_gray.png"];
            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [info.button setImage:image forState:UIControlStateNormal];
        } else {
            UIImage *image = [UIImage imageNamed:@"more_gray.png"];
            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [info.button setImage:image forState:UIControlStateNormal];
        }
    }

    [self setupButtonStyleHandler:info];
}

- (void)setupButtonStyleHandler:(ActionButtonInfo *)info
{
    [self changeButtonStyle:info asTouch:NO];

    [info.button addTarget:self
                    action:@selector(onButtonTouchDown:)
          forControlEvents:UIControlEventTouchDown];

    [info.button addTarget:self
                    action:@selector(onButtonTouchUpInside:)
          forControlEvents:UIControlEventTouchUpInside];

    [info.button addTarget:self
                    action:@selector(onButtonTouchUpOutside:)
          forControlEvents:UIControlEventTouchUpOutside];

    [info.button addTarget:self action:@selector(onButtonTouchUpOutside:) forControlEvents:UIControlEventTouchDragOutside];
    [info.button addTarget:self action:@selector(onButtonTouchDown:) forControlEvents:UIControlEventTouchDragInside];
    [info.button addTarget:self action:@selector(onButtonTouchUpOutside:) forControlEvents:UIControlEventTouchDragExit];
    [info.button addTarget:self action:@selector(onButtonTouchDown:) forControlEvents:UIControlEventTouchDragEnter];
    [info.button addTarget:self action:@selector(onButtonTouchUpOutside:) forControlEvents:UIControlEventTouchCancel];
}

- (ActionButtonInfo *)getInfoFromButton:(UIButton *)button
{
    NSArray *array = [self createAllButtons];
    for (ActionButtonInfo *info in array) {
        if (info.button == button) {
            return info;
        }
    }

    return nil;
}

- (IBAction)onButtonTouchDown:(id)sender
{
    [self changeButtonStyle:[self getInfoFromButton:sender] asTouch:YES];
}

- (IBAction)onButtonTouchUpOutside:(id)sender
{
    [self changeButtonStyle:[self getInfoFromButton:sender] asTouch:NO];
}

- (IBAction)onButtonTouchUpInside:(id)sender
{
    [self changeButtonStyle:[self getInfoFromButton:sender] asTouch:NO];

    [self onButtonTap:[self getInfoFromButton:sender]];
}

- (void)onButtonTap:(ActionButtonInfo *)info
{
}

- (void)changeButtonStyle:(ActionButtonInfo *)info asTouch:(BOOL)asTouch
{
    ThemeManager *tm = [ThemeManager sharedManager];
    UIColor *color = [tm colorForKey:asTouch ? ThemeAccentColor : ThemeNormalColor];

    if (info.label) [info.label setTextColor:color];

    [self _changeButtonStyle:info.button asTouch:asTouch];
}

- (void)_changeButtonStyle:(UIButton *)button asTouch:(BOOL)asTouch
{
    ThemeManager *tm = [ThemeManager sharedManager];
    UIColor *color = [tm colorForKey:asTouch ? ThemeAccentColor : ThemeMenuIconColor];

    button.tintColor = color;

    UIColor *backgroundColor = [UIColor clearColor];
    button.backgroundColor = backgroundColor;
    if (self.isVerticalMode == NO) {
        button.layer.borderWidth = 1.f;
        button.layer.cornerRadius = 14.5f;
    }

    button.layer.borderColor = color.CGColor;

    UIColor *titleColor = [tm colorForKey:ThemeNormalColor];
    UIColor *accentColor = [tm colorForKey:ThemeAccentColor];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    [button setTitleColor:accentColor forState:UIControlStateHighlighted];
    [button setTitleColor:accentColor forState:UIControlStateSelected];
    [button setTitleColor:accentColor forState:UIControlStateDisabled];
}

@end
