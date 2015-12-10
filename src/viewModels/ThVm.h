//
//  ThVm.h
//  Forest
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import "Th.h"
#import "ThListBaseVC.h"

@class ThVm;
@protocol ThVmDelegate <NSObject>

- (void)onThVmPropertyChanged:(ThVm *)thVm name:(NSString *)name;

@end

@interface ThVm : NSObject

@property (nonatomic) CGFloat flagWidth;
@property (nonatomic) BOOL showDate;
@property (nonatomic) BOOL showBoardName;
@property (nonatomic) BOOL showFavState;
@property (weak, nonatomic) id<ThVmDelegate> delegate;

@property (nonatomic) BOOL drawMarkWhenRead;

@property (nonatomic) CGFloat cellHeight;

@property (nonatomic) Th *th;
@property (nonatomic) NSInteger tag;

@property (nonatomic) CGRect speedFrame;
@property (nonatomic) CGRect countFrame;
@property (nonatomic) CGRect titleFrame;
@property (nonatomic) CGRect newFrame;
@property (nonatomic) CGRect otherFrame;
@property (nonatomic) CGRect dateFrame;

@property (nonatomic) CTFrameRef titleFrameRef;
@property (nonatomic) CTFrameRef countFrameRef;
@property (nonatomic) CTFrameRef speedFrameRef;
@property (nonatomic) CTFrameRef otherFrameRef;
@property (nonatomic) CTFrameRef dateFrameRef;
@property (nonatomic) CTFrameRef newCountFrameRef;

- (id)initWithTh:(Th *)th;
- (void)regenAttributedStrings:(CGFloat)width;
- (CGFloat)getHeight:(CGFloat)width;
- (NSComparisonResult)compareLastReadTime:(ThVm *)thVm;

@end
