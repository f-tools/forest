
#import "AutoScrollCalculator.h"

@interface AutoScrollCalculator ()

@property (nonatomic) NSTimer *timer;
@property (nonatomic) BOOL shouldStartAutoScrollingOnTouchEnd;
@property (nonatomic) BOOL isOnStartScrollingArea;

@property (nonatomic) CGFloat baseContentOffset;
@property (nonatomic) NSDate *baseDate;

@property (nonatomic) CGPoint touchPositionInScrollButton;

@property (nonatomic) CGFloat prevSettingContentOffset;
@property (nonatomic) CGFloat scrollVector;
@property (nonatomic) BOOL isWaitingHorizonScroll;
@property (nonatomic) BOOL isHorizonCanceled;

@end

@implementation AutoScrollCalculator

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

- (void)onTouchBegan:(BOOL)onScrollButton point:(CGPoint)point
{
    self.canClickAutoScrollButton = onScrollButton;

    self.isWaitingHorizonScroll = onScrollButton;
    self.isHorizonCanceled = onScrollButton == NO;

    self.touchPositionInScrollButton = point;
}

// onTouchMoveを読んでも意味が無い場合にNOを返す
- (BOOL)acceptTouchMove:(CGPoint)touchPoint
{
    return self.isHorizonStarted || (self.isHorizonCanceled == NO && self.isWaitingHorizonScroll);
}

// タッチポイントの変更
// スクロール速度の変更を伴うかもしれない
- (void)onTouchMove:(CGPoint)touchPoint
{
    CGFloat minOffset = 22.f;
    BOOL shouldFireTimer = NO;

    if (self.isHorizonStarted) {
        if (self.shouldStartAutoScrollingOnTouchEnd == NO) {
        }

    } else if (self.isHorizonCanceled == NO && self.isWaitingHorizonScroll) {
        if (touchPoint.x < self.touchPositionInScrollButton.x - minOffset ||
            self.touchPositionInScrollButton.x + minOffset < touchPoint.x) {

            self.canClickAutoScrollButton = NO;
            self.isHorizonStarted = YES;

            if (self.isAutoScrolling) {
                //自動スクロールからスライドスクロールへの切替
                self.shouldStartAutoScrollingOnTouchEnd = YES;
                self.isAutoScrolling = NO;

            } else {
                //　スライドスクロールの開始
                shouldFireTimer = YES;
            }
        }
    }

    // 必要に応じて基準位置の変更を行う
    if (self.isHorizonStarted) {
        if (shouldFireTimer == NO) {
            [self onInterval:nil];
        }

        CGFloat oldVector = self.scrollVector;
        CGFloat newVector = 0.f;
        CGFloat xOffset = touchPoint.x - self.touchPositionInScrollButton.x;
        if (xOffset > minOffset) {
            newVector = (xOffset - minOffset);
            newVector = newVector * newVector;
        } else if (xOffset < minOffset) {
            newVector = (xOffset - minOffset);
            newVector = -newVector * newVector;
        }
        newVector = newVector / 18;

        // newVector *= 2;
        self.scrollVector = newVector;
        if (newVector != oldVector) {
            [self _changeBase];
        }
    }

    if (shouldFireTimer && [self.timer isValid] == NO) {
        [self startTimer];
    }
}

- (void)_changeBase
{
    self.baseDate = [NSDate date];
    self.prevSettingContentOffset = self.baseContentOffset = self.tableView.contentOffset.y;
}

- (void)onInterval:(NSTimer *)timer
{
    if (self.tableView.isDragging || self.tableView.isDecelerating) {
        return;
    }

    CGFloat diff = self.prevSettingContentOffset - self.tableView.contentOffset.y;
    if (diff < -40 || 40 < diff) {
        [self _changeBase];
        return;
    }

    NSDate *now = [NSDate date];

    NSTimeInterval interval = [now timeIntervalSinceDate:self.baseDate];

    CGFloat newY = self.baseContentOffset + (interval * self.scrollVector);

    if (newY < -self.tableView.contentInset.top) {
        newY = -self.tableView.contentInset.top;
    } else if (self.tableView.contentSize.height + self.tableView.contentInset.bottom - self.tableView.bounds.size.height < newY) {
        newY = self.tableView.contentSize.height + self.tableView.contentInset.bottom - self.tableView.bounds.size.height;
    }

    self.prevSettingContentOffset = newY;
    self.tableView.contentOffset = CGPointMake(0, newY);
}

- (void)onTouchEnd
{
    self.isHorizonCanceled = YES;
    if (self.isHorizonStarted) {
        self.isHorizonStarted = NO;

        if (self.shouldStartAutoScrollingOnTouchEnd) {
            //self.autoScrollButton.image = [UIImage imageNamed:@"pause_30.png"];
            self.isAutoScrolling = YES;
            self.shouldStartAutoScrollingOnTouchEnd = NO;
        } else {
            //self.toolbar.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeToolBarBackgroundColor];
            if (self.isOnStartScrollingArea) {
                self.autoScrollButton.image = [UIImage imageNamed:@"pause_30.png"];
                self.isAutoScrolling = YES;
            } else {
                //self.autoScrollButton.image = [UIImage imageNamed:@"play.png"];
                if ([self.timer isValid]) {
                    [self.timer invalidate];
                }
            }
        }
    }
}

- (void)onTouchCancel
{
    [self onTouchEnd];
}

- (void)onClickAutoScrollButton
{
    if (self.canClickAutoScrollButton) {
        if (self.isAutoScrolling) {
            //停止
            if ([self.timer isValid]) {
                [self.timer invalidate];
            }
            self.autoScrollButton.image = [UIImage imageNamed:@"play.png"];
            self.isAutoScrolling = NO;
        } else {
            //開始
            self.autoScrollButton.image = [UIImage imageNamed:@"pause_30.png"];
            [self startAutoScroll];
            self.isAutoScrolling = YES;
        }
    }
}

- (void)startAutoScroll
{
    [self _changeBase];
    self.scrollVector = 45.0f;
    if ([self.timer isValid] == NO) {
        [self startTimer];
    }
}

- (void)startTimer
{
    self.timer = [NSTimer
        timerWithTimeInterval:1 / 60.f
                       target:self
                     selector:@selector(onInterval:)
                     userInfo:nil
                      repeats:YES];
    [
        [NSRunLoop currentRunLoop]
        addTimer:self.timer
         forMode:NSRunLoopCommonModes];
}

@end
