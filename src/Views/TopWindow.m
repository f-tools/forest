//
//  TopWindow.m
//  Forest
//

#import "TopWindow.h"
#import "Env.h"
#import "ThemeManager.h"

@implementation TopWindow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

// @override
- (void)becomeKeyWindow
{
}

- (void)windowInit
{

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self
           selector:@selector(onThemeChanged:)
               name:@"themeChanged"
             object:nil];
}

// 通知と値を受けるonThemeChangedメソッド
- (void)onThemeChanged:(NSNotification *)center
{
    [self changeTheme];
}

- (void)changeTheme
{
    self.gestureView.layer.cornerRadius = 10.0;
    self.gestureView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeGestureBackgroundColor];
    self.gestureView.layer.masksToBounds = YES;

    // 縁取りの色を設定する
    // self.gestureLabel.outlineColor

    self.gestureLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeGestureTextColor];
}

- (void)showGestureInfo:(GestureEntry *)gestureItem
{
    if (self.gestureView == nil) {

        self.gestureView = [[UIView alloc] initWithFrame:CGRectMake(0, 80, 250, 0.5)];
        self.gestureLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 250, 0.5)];
        self.gestureLabel.textAlignment = NSTextAlignmentCenter;
        self.gestureLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        self.gestureLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [[[self subviews] objectAtIndex:0] addSubview:self.gestureView];

        [self.gestureView addSubview:self.gestureLabel];

        [self changeTheme];

    } else {
        // タブレットモード切り替え時には最前面でなくなる可能性がある
        [[[self subviews] objectAtIndex:0] bringSubviewToFront:self.gestureView];
    }

    NSString *text = gestureItem ? gestureItem.nameGetter() : @"none";

    if (self.currentGestureItem != gestureItem) {
        // サイズ・位置調整
        CGSize size = [UIScreen mainScreen].bounds.size;
        CGFloat width = 90;
        CGFloat height = 90;

        size = [Env fixSize:size];

        self.gestureView.frame = CGRectMake((size.width - width) / 2, (size.height - height) / 4, width, height);
        self.gestureLabel.frame = CGRectMake(0, 0, width, height);
        [self.gestureLabel setNeedsDisplay];
        [self.gestureView setNeedsDisplay];

        self.gestureLabel.text = text;
        self.currentGestureItem = gestureItem;
    }

    self.showingGestureInfo = YES;
    self.gestureView.hidden = NO;
}

- (void)dismissGestureInfo
{
    if (self.gestureView && self.showingGestureInfo) {
        self.gestureView.hidden = YES;
        self.currentGestureItem = nil;
        self.showingGestureInfo = YES;
    }
}

- (void)sendEvent:(UIEvent *)event
{
    [super sendEvent:event];
    [[NSNotificationCenter defaultCenter] postNotificationName:MYO_WINDOW_EVENT_NOTIFICATION object:self userInfo:(id)event];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
