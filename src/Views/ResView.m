#import <SDWebImage/UIImageView+WebCache.h>
#import <CoreText/CoreText.h>
#import "ResView.h"
#import "AnchorNode.h"
#import "TextNode.h"
#import "Env.h"
#import "ThemeManager.h"
#import "LineBreakNode.h"
#import "ThumbnailManager.h"

@interface ThumbnailView ()

@property (nonatomic) NSInteger currentResIndex;

@end

@implementation ThumbnailView

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    ThemeManager *tm = [ThemeManager sharedManager];

    CGContextSetShouldAntialias(context, NO);
    NSInteger mode = [Env getThumbnailMode];
    if (mode == 1 && self.resVm.thumbnailList) {
        for (ThumbnailInfo *info in self.resVm.thumbnailList) {
            if (info.image) {
                CGContextDrawImage(context, info.frame, info.image.CGImage);
            } else {
                //サムネイル一覧情報
                UIColor *thumbBack = [tm colorForKey:ThemeThumbnailBackgroundColor];
                CGContextSetFillColorWithColor(context, thumbBack.CGColor);
                CGContextFillRect(context, info.frame);

                if (info.hasError) { //ERROR情報を提示
                    CGRect errorRect = info.frame;

                    UIColor *redColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.2 alpha:0.5];
                    errorRect.size.height = 7;
                    CGContextSetFillColorWithColor(context, redColor.CGColor);
                    CGContextFillRect(context, errorRect);
                } else if (info.receivedSize > 0 && info.expectedSize > 0) {
                    CGRect progressRect = info.frame;
                    progressRect.size.width = info.frame.size.width * (info.receivedSize / (CGFloat)info.expectedSize);
                    progressRect.size.height = 5;
                    UIColor *thumbProgressColor = [tm colorForKey:ThemeThumbnailProgressColor];
                    CGContextSetFillColorWithColor(context, thumbProgressColor.CGColor);
                    CGContextFillRect(context, progressRect);
                }
            }

            if (self.resVm.highlightThumbnail == info) {
                UIColor *alphaMap = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
                CGContextSetFillColorWithColor(context, alphaMap.CGColor); // 塗りつぶしの色を指定
                CGContextFillRect(context, info.frame);                    // 四角形を塗りつぶす
            }
        }
    }
}
@end

@interface ResView ()

@property (nonatomic) NSInteger currentResIndex;

@end

@implementation ResView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
}

- (ThumbnailView *)thumbnailView
{
    if (_thumbnailView == nil) {
        _thumbnailView = [[ThumbnailView alloc] init];
        _thumbnailView.backgroundColor = [UIColor clearColor];

        [self addSubview:_thumbnailView];
    }
    return _thumbnailView;
}

- (void)setResVm:(ResVm *)resVm
{
    if (_resVm != resVm) {
        _resVm = resVm;

        self.thumbnailView.resVm = resVm;
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    CGRect rect = self.resVm.thumbnailFrame;
    CGRect newRect = CGRectMake(rect.origin.x, frame.size.height - rect.origin.y - rect.size.height, rect.size.width, rect.size.height - 2);
    [self.thumbnailView setFrame:newRect];
}

- (void)prepareForReuse
{
    self.currentResIndex++;
    [self.resVm releaseThumbnails];
}

- (void)onCellShown
{
    if (self.resVm.thumbnailList == nil) return;

    self.currentResIndex++;

    __weak ResVm *currentResVm = self.resVm;
    __weak ResView *weakSelf = self;

    __block NSInteger thisResIndex = self.currentResIndex;

    __block NSTimeInterval lastDisplay = 0.0;
    NSMutableArray *requestInfoList = [NSMutableArray array];
    for (ThumbnailInfo *info in self.resVm.thumbnailList) {
        info.hasError = NO;
        if (info.image) continue;

        info.progress = ^(ThumbnailInfo *info, NSInteger receivedSize, NSInteger expectedSize) {
          info.receivedSize = receivedSize;
          info.expectedSize = expectedSize;
          NSTimeInterval now = [[NSDate date] timeIntervalSince1970];

          if (thisResIndex == weakSelf.currentResIndex && currentResVm == weakSelf.resVm && now - lastDisplay > 0.1) {
              [weakSelf.thumbnailView setNeedsDisplay];
              lastDisplay = now;
          }

        };

        info.completion = ^(ThumbnailInfo *info, UIImage *image, NSError *error, SDImageCacheType cacheType,
                            BOOL finished, NSURL *imageURL) {

          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (thisResIndex != weakSelf.currentResIndex || currentResVm != weakSelf.resVm) {
                return;
            }

            if (image) {
                CGFloat scale = [[UIScreen mainScreen] scale];
                info.image = [weakSelf resize:image rect:CGRectMake(0, 0, info.frame.size.width * scale, info.frame.size.height * scale)];
            }

            info.hasError = error != nil;
            dispatch_async(dispatch_get_main_queue(), ^{
              if (thisResIndex != weakSelf.currentResIndex || currentResVm != weakSelf.resVm) {
                  return;
              }
              NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
              lastDisplay = now;

              [weakSelf.thumbnailView setNeedsDisplay];
            });
          });

        };
        [requestInfoList addObject:info];
    }
    if ([requestInfoList count] > 0) {
        [[ThumbnailManager sharedManager] addRequests:requestInfoList];
    }
}

- (UIImage *)resize:(UIImage *)image rect:(CGRect)rect
{
    CGFloat iw = image.size.width;
    CGFloat ih = image.size.height;

    CGFloat scW = rect.size.width;
    CGFloat scH = rect.size.height;

    CGFloat iRatio = iw / ih;
    CGFloat scRatio = scW / scH;

    CGFloat originX;
    CGFloat originY;
    CGFloat width;
    CGFloat height;

    if (scRatio > iRatio) { //portrait
        height = scH;
        width = iw * (scH / ih);
        originX = (scW - width) / 2;
        originY = 0;
    } else { //landscape
        width = scW;
        height = ih * (scW / iw);
        originX = 0;
        originY = (scH - height) / 2;
    }

    UIGraphicsBeginImageContext(rect.size);
    rect = CGRectMake(originX, originY, width, height);
    [image drawInRect:rect];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    UIGraphicsEndImageContext();
    return resizedImage;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    ResVm *resVm = self.resVm;
    if (resVm.isHiddenAborn) {
        return;
    }

    CTFrameRef headerFrameRef = nil;
    CTFrameRef bodyFrameRef = nil;

    @synchronized(resVm)
    {
        headerFrameRef = self.resVm.headerFrameRef;
        bodyFrameRef = self.resVm.bodyFrameRef;

        if (headerFrameRef == nil && bodyFrameRef == nil) return;

        [self.resVm drawRect:rect];

        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, 0, self.bounds.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);

        if (headerFrameRef) {
            CTFrameDraw(headerFrameRef, context);
        }

        if (bodyFrameRef) {
            CTFrameDraw(bodyFrameRef, context);
        }
    }
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    [self.thumbnailView setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
   [super touchesMoved:touches withEvent:event];
}

- (void)redraw
{
    [self setNeedsDisplay];
     [self onCellShown];
}

- (ResNodeBase *)notifyTapEstablished:(UITouch *)touch
{
    id node = [self doWithRecognizer:touch];
    if (node == nil) { // node 全体タップ
        self.resVm.highlightIndex = -100;
        self.resVm.highlightThumbnail = nil;
        [self setNeedsDisplay];
    } else {
        if ([node isKindOfClass:[ThumbnailInfo class]]) {
            ThumbnailInfo *info = (ThumbnailInfo *)node;
            self.resVm.highlightThumbnail = info;
            [self redraw];
        } else {
            if (self.resVm.highlightThumbnail != nil)
                self.resVm.highlightThumbnail = nil;
            // [self redraw];
        }

        if ([node isKindOfClass:[ResNodeBase class]]) {
            ResNodeBase *resNode = (ResNodeBase *)node;
            if (resNode.indexInRes != self.resVm.highlightIndex) {
                self.resVm.highlightIndex = resNode.indexInRes;
                [self.resVm regenAttributedStrings];
                [self redraw];
            }
        } else if ([node isKindOfClass:[NSNumber class]]) {
            self.resVm.highlightIndex = [((NSNumber *)node)integerValue];
            [self.resVm regenAttributedStrings];
            [self redraw];
        } else {
            self.resVm.highlightIndex = 0;
        }
    }
    return node;
}

- (ResNodeBase *)notifyTap:(UITouch *)touch
{
    ResNodeBase *node = [self notifyTapEstablished:touch];

    [self notifyTapCancel:touch];
    return node;
}

- (ResNodeBase *)notifyLongTap:(UITouch *)touch
{
    return [self notifyTap:touch];
}

- (void)notifyTapCancel:(UITouch *)touch
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [NSThread sleepForTimeInterval:0.05];
      dispatch_async(dispatch_get_main_queue(), ^{
        self.resVm.highlightIndex = 0;
        self.resVm.highlightThumbnail = nil;
        [self.resVm regenAttributedStrings];
        [UIView transitionWithView:self
                          duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{

                          [self setNeedsDisplay];

                        }
                        completion:nil];
      });
    });
}

- (id)doWithRecognizer:(UITouch *)touch
{
    ResVm *resVm = self.resVm;
    CTFrameRef headerFrameRef = nil;
    CTFrameRef bodyFrameRef = nil;

    @synchronized(resVm)
    {
        headerFrameRef = self.resVm.headerFrameRef;
        bodyFrameRef = self.resVm.bodyFrameRef;
    }

    if (headerFrameRef == nil && bodyFrameRef == nil) return nil;

    CGPoint tapLocation = [touch locationInView:self];
    CGPoint tapLocationInThumbnail = [touch locationInView:self.thumbnailView];

    if (resVm.thumbnailList) {
        for (ThumbnailInfo *info in resVm.thumbnailList) {
            CGRect rect = info.frame;
            CGRect newRect = CGRectMake(rect.origin.x, self.thumbnailView.bounds.size.height - rect.origin.y - rect.size.height, info.frame.size.width, info.frame.size.height);
            BOOL touchOnThumbnail = (CGRectContainsPoint(newRect, tapLocationInThumbnail));
            if (touchOnThumbnail) {
                return info;
            }
        }
    }

    ResNodeBase *node = [self getTouchNode:nil
                               tapLocation:tapLocation
                                  frameRef:headerFrameRef
                      withAttributedString:self.resVm.headerAttributedString];
    if (node) return node;

    if (bodyFrameRef) {
        return [self getTouchNode:nil
                      tapLocation:tapLocation
                         frameRef:bodyFrameRef
             withAttributedString:self.resVm.bodyAttributedString];
    }
    return nil;
}

- (ResNodeBase *)getTouchNode:(CGContextRef)context tapLocation:(CGPoint)tapLocation frameRef:(CTFrameRef)frameRef withAttributedString:(NSAttributedString *)attributedString
{
    CGPathRef path = CTFrameGetPath(frameRef);

    CGRect frameBoundingBox = CGPathGetBoundingBox(path);

    CFArrayRef lines = CTFrameGetLines(frameRef);
    CGPoint origins[CFArrayGetCount(lines)];
    // the origins of each line at the baseline

    CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), origins);

    CFIndex linesCount = CFArrayGetCount(lines);

    for (int lineIdx = 0; lineIdx < linesCount; lineIdx++) {
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, lineIdx);

        for (id runObj in(NSArray *)CTLineGetGlyphRuns(line)) {
            CTRunRef run = (__bridge CTRunRef)runObj;
            CFRange runRange = CTRunGetStringRange(run);

            CGRect runBounds;
            CGFloat ascent; // height above the baseline
            CGFloat descent; //height below the baseline
            
            runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
            runBounds.size.height = ascent + descent;
            
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, runRange.location, NULL);
            
            runBounds.origin.x = origins[lineIdx].x + xOffset + frameBoundingBox.origin.x;
            
            runBounds.origin.y = self.frame.size.height - frameBoundingBox.origin.y - origins[lineIdx].y - runBounds.size.height;
            
            runBounds = CGRectMake(runBounds.origin.x - 15, runBounds.origin.y - 5, runBounds.size.width + 30, runBounds.size.height + 10);

            if (CGRectContainsPoint(runBounds, tapLocation)) {
                NSRange longestRange;

                for (NSInteger i = runRange.location; i < runRange.location + runRange.length; i++) {
                    NSDictionary *attributes = [attributedString attributesAtIndex:i
                                                             longestEffectiveRange:&longestRange
                                                                           inRange:NSMakeRange(i, 1)];

                    ResNodeBase *node = [attributes objectForKey:@"node"];
                    if (node == nil) {
                        continue;
                    }

                    if ([node isKindOfClass:[NSNumber class]]) {
                        NSNumber *num = (NSNumber *)node;
                        if ([num integerValue] != -2 && [num integerValue] != -4) {
                            return node;
                        }
                    }

                    if ([node isKindOfClass:[TextNode class]] == NO && [node isKindOfClass:[LineBreakNode class]] == NO && [node isKindOfClass:[ResNodeBase class]]) {
                        return node;
                    }
                }
            }
        }
    }
    return nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
}

@end
