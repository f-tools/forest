

#import <Foundation/Foundation.h>

@interface AutoScrollCalculator : NSObject

@property (weak) UITableView *tableView;
@property (weak, nonatomic) UIBarButtonItem *autoScrollButton;

@property (weak, nonatomic) UIToolbar *toolbar;

@property (nonatomic) BOOL canClickAutoScrollButton;

@property (nonatomic) BOOL isHorizonStarted;
@property (nonatomic) BOOL isAutoScrolling; //手放しの自動スクロールが開始中かどうか

- (void)onTouchBegan:(BOOL)onScrollButton point:(CGPoint)point;
- (void)onTouchMove:(CGPoint)touchPoint;
- (void)onTouchEnd;
- (void)onTouchCancel;
- (void)onClickAutoScrollButton;

@end
