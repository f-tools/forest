#import <UIKit/UIKit.h>
#import "ThVm.h"
#import "ThListBaseVC.h"

@class ActionButtonInfo;

@interface ActionMenuBase : NSObject

@property (nonatomic) UIView *view;
@property (nonatomic) BOOL isVerticalMode;

- (void)build;

- (void)changeButtonStyle:(ActionButtonInfo *)info asTouch:(BOOL)asTouch;

- (void)_changeButtonStyle:(UIButton *)button asTouch:(BOOL)asTouch;

- (void)setupButtonStyleHandler:(ActionButtonInfo *)info;

- (void)open;

// @abstract
- (void)onLayoutCompleted;

@end
