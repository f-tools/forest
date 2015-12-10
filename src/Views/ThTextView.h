//
//  ThTextView.h
//  Forest
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "ThVm.h"
@class ThTableViewCell;

//drawTypes
#define thVmTitle 0
#define thVmSpeed 1
#define thVmCount 2
#define thVmNewCount 3
#define thVmOther 4
#define thVmDate 5
#define thVmAll 6

@interface ThTextView : UIView

@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
@property (nonatomic) ThVm *thVm;
@property (nonatomic) int drawType;
@property (nonatomic) BOOL drawMarkWhenRead;

@property (weak, nonatomic) ThTableViewCell *thTableViewCell;

@property (nonatomic) CTFrameRef ctFrameRef;

@end
