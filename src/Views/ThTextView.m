//
//  ThTextView.m
//  Forest
//

#import "ThTextView.h"
#import <CoreText/CoreText.h>
#import <CoreFoundation/CoreFoundation.h>
#import "ThemeManager.h"
#import "ThTableViewCell.h"

@implementation ThTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    ThemeManager *tm = [ThemeManager sharedManager];
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (self.drawType == thVmTitle) {
        BOOL drawMark = NO;
        if (self.thVm.th.lastReadTime > 0) {
            if (self.thVm.th.count > self.thVm.th.read) {
                drawMark = YES;
                if ([self.thVm.th isOver1000]) {
                    // 未読あり&&1000Over
                    CGContextSetFillColorWithColor(context, [tm colorForKey:ThemeThListUnreadOverFlagColor].CGColor);
                } else {
                    // 未読あり
                    CGContextSetFillColorWithColor(context, [tm colorForKey:ThemeThListUnreadFlagColor].CGColor);
                }
            } else {
                if (self.thVm.th.isDown) {
                    //Dat落ち
                    drawMark = YES;
                    CGContextSetFillColorWithColor(context, [tm colorForKey:ThemeThListDatDownFlagColor].CGColor);
                } else if ([self.thVm.th isOver1000]) {
                    // Over 1000
                    drawMark = YES;
                    CGContextSetFillColorWithColor(context, [tm colorForKey:ThemeThListOverFlagColor].CGColor);
                } else if (self.drawMarkWhenRead) {
                    //既読マークカキコ
                    drawMark = YES;
                    CGContextSetFillColorWithColor(context, [tm colorForKey:ThemeThListReadFlagColor].CGColor);
                }
            }
        }
        
        if (drawMark) {
            float radious = 3;
            float diameter = radious * 2;
            float margin = 15;
            float x = (margin - diameter) / 2;
            float y = (self.thVm.cellHeight - diameter) / 2;
            // 円を塗りつぶす
            CGContextFillEllipseInRect(context, CGRectMake(x, y, diameter, diameter));
        }
    }

    @synchronized(self.thVm)
    {
        CTFrameRef frameRef = nil;
        switch (self.drawType) {
        case thVmTitle:
            frameRef = self.thVm.titleFrameRef;
            break;
        case thVmSpeed:
            frameRef = self.thVm.speedFrameRef;
            break;
        case thVmCount:
            frameRef = self.thVm.countFrameRef;
            break;
        case thVmNewCount:
            frameRef = self.thVm.newCountFrameRef;
            break;
        case thVmOther:
            frameRef = self.thVm.otherFrameRef;
            break;
        case thVmDate:
            frameRef = self.thVm.dateFrameRef;
            break;
        }

        if (frameRef) {
            CGContextSetTextMatrix(context, CGAffineTransformIdentity);
            CGContextTranslateCTM(context, 0, self.bounds.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CTFrameDraw(frameRef, context);
        }
    }
}

@end
