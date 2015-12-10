//
//  TopWindow.h
//  Forest
//

#import <UIKit/UIKit.h>

#define MYO_WINDOW_EVENT_NOTIFICATION @"MYO_WINDOW_EVENT_NOTIFICATION"

#import "GestureEntry.h"
@class GestureEntry;

@interface TopWindow : UIWindow {
}

@property (nonatomic) UIView *gestureView;
@property (nonatomic) UILabel *gestureLabel;
@property (nonatomic) GestureEntry *currentGestureItem;
@property (nonatomic) BOOL showingGestureInfo;

- (void)windowInit;
- (void)showGestureInfo:(GestureEntry *)gestureItem;

- (void)dismissGestureInfo;
@end
