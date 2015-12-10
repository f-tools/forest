#import "ResVm.h"
#import <CoreText/CoreText.h>
#import "ThemeManager.h"
#import "ResTableViewCell.h"
#import "AnchorNode.h"
#import "LinkNode.h"
#import "TextNode.h"
#import "IDNode.h"
#import "LineBreakNode.h"
#import "Env.h"
#import "Th+ParseAdditions.h"
#import "FastTableView.h"
#import "MySplitVC.h"
#import "MyNavigationVC.h"
#include "../../fonts/AAFontPostscript.h"

static NSMutableDictionary *_nameColorDict;

const NSInteger kResNumberArea =  -1;
const NSInteger kResNameArea = -2;
const NSInteger kResMailArea = -4;
const NSInteger kResIDArea = -3;
const NSInteger kResBEIDArea = -5;
const NSInteger kResNGReasonArea =  -7;

@implementation ThumbnailInfo
@end

@interface ResVm () {
}

@end

@implementation ResVm

- (id)init
{
    if (self = [super init]) {
        _childs = nil;
        super.cellHeight = -1;
    }
    return self;
}

- (void)addChild:(ResVm *)child
{
    if (self.childs == nil) {
        self.childs = [NSMutableArray array];
    }
    child.depth = self.depth + 1;
    [self.childs addObject:child];
}

- (void)dealloc
{
    @synchronized(self)
    {
        [self releaseFrameRefs];
    }

    for (ThumbnailInfo *info in self.thumbnailList) {
        info.image = nil;
        info.linkNode = nil;
        info.completion = nil;
        info.progress = nil;
    }

    [self.thumbnailList removeAllObjects];
    self.thumbnailList = nil;
}

- (void)releaseFrameRefs
{

    if (self.res) {
        // myLog(@"resNumber = %d", self.res.number);
    }

    if (self.headerFrameRef) {
        CTFrameRef headerTemp = self.headerFrameRef;
        self.headerFrameRef = nil;
        CFRelease(headerTemp);
    }

    if (self.bodyFrameRef) {
        CTFrameRef temp = self.bodyFrameRef;
        self.bodyFrameRef = nil;
        CFRelease(temp);
    }
}

- (void)releaseThumbnails
{
    if (self.thumbnailTotalHeight > 0) {
        for (ThumbnailInfo *info in self.thumbnailList) {
            info.image = nil;
        }
        //[self.thumbnailList removeAllObjects];
        //self.thumbnailList = nil;
        //self.thumbnailTotalHeight = 0;
    }
}

// @override
- (void)regenAttributedStrings
{
    @synchronized(self)
    {
        [self releaseFrameRefs];
        self.cellHeight = -1;
        [self calcHeight];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIColor *backgroundColor = nil;
    if (self.highlight) {
        backgroundColor = [[ThemeManager sharedManager] colorForKey:self.resVmList.highlightType != 1 ? ThemeResHighlightBackgroundColor : ThemeResIDPopupHighlightBackgroundColor];
    }

    //全体タップ
    if (self.highlightIndex == -100) {
        backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeResRowSelectedBackgroundColor];
    }

    if (backgroundColor) {

        CGContextSetFillColorWithColor(context, backgroundColor.CGColor); // 塗りつぶしの色を指定
        CGContextFillRect(context, CGRectMake(self.depthSeparatorOffset, 0, rect.size.width - self.depthSeparatorOffset, self.cellHeight)); // 四角形を塗りつぶす
    }

    CGColorRef borderColor = [[ThemeManager sharedManager] colorForKey:ThemeResRowSeparatorColor].CGColor;
    CGContextSetShouldAntialias(context, NO);

    if (self.res.isMine || self.res.resToMe) {
        CGFloat markWidth = 2.5f;

        CGColorRef myResMarkColor = [[ThemeManager sharedManager] colorForKey:ThemeResMyResMarkColor].CGColor;
        CGColorRef refMarkColor = [[ThemeManager sharedManager] colorForKey:ThemeResRefMarkColor].CGColor;

        CGContextSetLineWidth(context, markWidth);
        CGContextSetStrokeColorWithColor(context, (self.res.resToMe ? refMarkColor : myResMarkColor));

        CGContextMoveToPoint(context, self.depthSeparatorOffset - 0.5 + 0.25 + markWidth / 2, 0.25);
        CGContextAddLineToPoint(context, self.depthSeparatorOffset - 0.5 + 0.25 + markWidth / 2, self.cellHeight - 0.25);
        CGContextStrokePath(context);
    }

    CGContextSetLineWidth(context, 0.5);
    CGContextSetStrokeColorWithColor(context, borderColor);

    //左の縦線
    if (self.depthSeparatorOffset > 0) {
        CGContextMoveToPoint(context, self.depthSeparatorOffset - 0.5, 0);
        CGContextAddLineToPoint(context, self.depthSeparatorOffset - 0.5, self.cellHeight - 0.5);
        CGContextStrokePath(context);
    }

    //下線
    if (!self.noBottomLine) {
        CGFloat bottomOffset = self.belowDepthSeparatorOffset - 0.5;

        if (self.depthSeparatorOffset - 0.5 < bottomOffset) {
            bottomOffset = self.depthSeparatorOffset - 0.5;
        }
        if (bottomOffset < 0) {
            bottomOffset = 0;
        }

        CGContextMoveToPoint(context, bottomOffset, self.cellHeight - 0.25);       //-0.5?
        CGContextAddLineToPoint(context, rect.size.width, self.cellHeight - 0.25); //-0.5?
        CGContextStrokePath(context);
    }

    CGContextSetShouldAntialias(context, YES);
}

- (CGFloat)depthToOffset:(NSInteger)depth
{
    int depthOffset = 0;
    int rate = 20;
    int min = 1;
    for (int i = 0; i < depth; i++) {
        if (rate < min)
            depthOffset += min;
        else {
            depthOffset += rate;
            rate = (rate * 0.91);
        }
    }

    return depthOffset;
}

- (CGFloat)calcHeight
{
    if (self.cellHeight > -1) return self.cellHeight;
    @synchronized(self)
    {
        if (self.cellHeight > -1) return self.cellHeight;

        
        UIViewController* vc = [[MySplitVC instance] resParentMyNavigationVC];
        CGFloat width = vc.view.bounds.size.width;
        if (self.priorCellWidth > 0) {
            width = self.priorCellWidth;
        }
        
        BOOL isNGMode = NO;
        BOOL isBaseTransparent = NO;
        NGItem *ngItem = nil;
        @synchronized(self.res)
        {
            if (self.res.ngChecked == NO) {
                [self.th checkNG:self.res];
                self.res.ngChecked = YES;
            }

            if (self.res.ngItem) {
                ngItem = self.res.ngItem;
                isNGMode = YES;
            }

            if (self.isReadBody) {
                //もし基板の場合に非参照レスが全て透明だった場合には表示しない。
                isBaseTransparent = YES;
                @synchronized(self.th)
                {
                    if ([self.th.responses count] > 0 && self.res.refferedResSet) {
                        for (NSNumber *resNum in self.res.refferedResSet) {
                            Res *res = [self.th.responses objectAtIndex:[resNum integerValue] - 1];
                            if (res) {
                                if (res.ngItem == nil || res.ngItem.transparent == NO) {
                                    isBaseTransparent = NO;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }

        self.isHiddenAborn = NO;
        if (self.res.isDummy || (isNGMode && ngItem.transparent) || isBaseTransparent) {
            self.thumbnailFrame = CGRectMake(0, 0, 0, 0);
            self.thumbnailList = nil;
            self.thumbnailTotalHeight = 0;

            self.frameRect = CGRectMake(0, 0, 0, 0);

            self.isHiddenAborn = YES;
            self.cellHeight = 0;
            return 0;
        }

        CGFloat middleMargin = 2.5;
        CGFloat topMargin = 3;
        CGFloat leftMargin = 6.5; //6
        CGFloat rightMargin = 5;
        CGFloat bottomMargin = 5; //4

        CGFloat baseHeaderFontSize = [Env getResHeaderSize];
        CGFloat baseBodyFontSize = [Env getResBodySize];

        int depthOffset = [self depthToOffset:self.depth];
        self.belowDepthSeparatorOffset = [self depthToOffset:self.belowDepth];

        //    myLog(@"depth offset = %d", depthOffset);
        //    myLog(@"self.belowDepthSeparatorOffset = %f", self.belowDepthSeparatorOffset);
        CGFloat leftOffset = depthOffset + leftMargin;
        CGFloat textWidth = width - leftOffset - rightMargin;
        self.depthSeparatorOffset = depthOffset;

        if (isNGMode && self.resVmList.showNGRes == NO) {
            self.thumbnailFrame = CGRectMake(0, 0, 0, 0);
            self.thumbnailList = nil;
            self.thumbnailTotalHeight = 0;

            NSAttributedString *headerAttributedString = self.headerAttributedString = [self genNGHeaderAttributedString:baseHeaderFontSize ngItem:ngItem];

            CTFramesetterRef headerFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)headerAttributedString);
            CGSize headerSize = CTFramesetterSuggestFrameSizeWithConstraints(
                headerFramesetter, CFRangeMake(0, headerAttributedString.length),
                nil, CGSizeMake(textWidth, CGFLOAT_MAX), nil);

            CGMutablePathRef path = CGPathCreateMutable();
            CGRect rect3 = CGRectMake(leftOffset, bottomMargin, textWidth, headerSize.height);
            CGPathAddRect(path, NULL, rect3);

            CGFloat cellHeight = 0.5 + headerSize.height + topMargin + bottomMargin + (self.noBottomLine ? 0 : 0.5);

            CTFrameRef tempFrame = CTFramesetterCreateFrame(headerFramesetter, CFRangeMake(0, [headerAttributedString length]), path, NULL);
            self.headerFrameRef = tempFrame;
            self.frameRect = CGRectMake(0, 0, width, cellHeight);

            CFRelease(headerFramesetter);
            CFRelease(path);

            self.cellHeight = cellHeight;

            return cellHeight;
        }

        /**
         * 各種サイズ取得
         */

        NSAttributedString *headerAttributedString = self.headerAttributedString = [self genHeaderAttributedString:baseHeaderFontSize];

        CTFramesetterRef headerFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)headerAttributedString);
        CGSize headerSize = CTFramesetterSuggestFrameSizeWithConstraints(
            headerFramesetter, CFRangeMake(0, headerAttributedString.length),
            nil, CGSizeMake(textWidth, CGFLOAT_MAX), nil);

        //ヘッダーが一行だった場合に本文とのスペースを大きくする。
        if (headerSize.height < baseHeaderFontSize * 1.7f) {
            middleMargin = 6.5; //2.5;
        }

        Res *res = self.res;
        BOOL isAA = [res checkIsAA];
        CGSize bodyContentSize;

        NSAttributedString *bodyAttributedString = nil;
        CTFramesetterRef bodyFramesetter = nil;
        if (isAA) {
            NSArray *aaFontSizes = @[ @16, @12, @11, @10, @9, @6, @5 ];
            for (NSNumber *num in aaFontSizes) {
                CGFloat fontSize = num.floatValue;

                if (bodyFramesetter) {
                    CFRelease(bodyFramesetter);
                }
                bodyAttributedString = [self genBodyAttributedString:fontSize useAAFont:true];
                bodyFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)bodyAttributedString);
                bodyContentSize = [self calcSize:bodyFramesetter
                                         attrStr:bodyAttributedString
                                        withSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
                if (bodyContentSize.width < textWidth) {
                    break;
                }
            }

        } else {

            bodyAttributedString = [self genBodyAttributedString:baseBodyFontSize useAAFont:false];
            bodyFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)bodyAttributedString);

            bodyContentSize = [self calcSize:bodyFramesetter attrStr:bodyAttributedString withSize:CGSizeMake(textWidth, CGFLOAT_MAX)]; 
        }

        self.bodyAttributedString = bodyAttributedString;

        /**
         * Cellサイズ決定しながらFrame生成
         */

        CGFloat cellHeight = 0.0f;
        cellHeight += (self.noBottomLine ? 0 : 0.5);
        //サムネイルの挿入
        [self.res checkHasImage];
        NSInteger mode = [Env getThumbnailMode];
        if ([self.res hasImage] && mode == 1) {

            if (self.thumbnailTotalHeight < 1.f) {
                NSInteger sizeType = [Env getThumbnailSizeType];
                CGFloat thumbWidth = 70;
                if (sizeType == 0)
                    thumbWidth = 40;
                else if (sizeType == 2)
                    thumbWidth = 120;
                else if (sizeType == 3)
                    thumbWidth = 300;

                CGFloat thumbnailWidth = thumbWidth;
                CGFloat thumbnailHeight = thumbWidth;

                CGFloat topOffset = 0;
                CGFloat leftOffset = 2;
                CGFloat thumbnailTotalHeight = 0;

                //CGFloat leftMargin = 6.5; //6
                //CGFloat rightMargin = 5;
                CGFloat thumbnailMiddleMargin = 7;

                NSMutableArray *thumbnails = [NSMutableArray array];
                for (ResNodeBase *node in self.res.bodyNodes) {
                    if ([node isKindOfClass:[LinkNode class]]) {
                        LinkNode *linkNode = (LinkNode *)node;
                        if ([linkNode isImageLink]) {
                            NSString *url = [linkNode getUrl];
                            ThumbnailInfo *thumbnail = [[ThumbnailInfo alloc] init];
                            thumbnail.url = url;
                            thumbnail.linkNode = linkNode;
                            thumbnail.frame = CGRectMake(leftOffset, topOffset, thumbnailWidth, thumbnailHeight);
                            thumbnailTotalHeight = topOffset + thumbnailHeight + thumbnailMiddleMargin;

                            //set Next thumbnail info
                            leftOffset = leftOffset + thumbnailWidth + thumbnailMiddleMargin;
                            if (leftOffset + thumbnailWidth > width - rightMargin - depthOffset) {
                                topOffset = topOffset + thumbnailHeight + thumbnailMiddleMargin;
                                leftOffset = 2;
                            }
                            [thumbnails addObject:thumbnail];
                        }
                    }
                }
                for (ThumbnailInfo *info in thumbnails) {
                    CGRect newFrame = info.frame;
                    newFrame.origin.y = cellHeight + thumbnailTotalHeight - info.frame.origin.y - info.frame.size.height;
                    info.frame = newFrame;
                }
                self.thumbnailList = thumbnails;
                self.thumbnailFrame = CGRectMake(depthOffset + leftMargin, cellHeight, width - depthOffset - leftMargin - rightMargin, thumbnailTotalHeight);
                self.thumbnailTotalHeight = thumbnailTotalHeight;
            }

            cellHeight += self.thumbnailTotalHeight;
        } else {
            self.thumbnailFrame = CGRectMake(0, 0, 0, 0);
        }

        cellHeight += bottomMargin;

        //CGFloat cellHeight = bodyContentSize.height + headerSize.height + topMargin + bottomMargin + middleMargin + (self.noBottomLine?0:0.5);

        CGMutablePathRef bodyPath = CGPathCreateMutable();
        CGRect bodyRect = CGRectMake(leftOffset, cellHeight, textWidth, bodyContentSize.height);
        CGPathAddRect(bodyPath, NULL, bodyRect);

        CTFrameRef bodyTempFrame = CTFramesetterCreateFrame(bodyFramesetter, CFRangeMake(0, [bodyAttributedString length]), bodyPath, NULL);
        self.bodyFrameRef = bodyTempFrame;

        cellHeight += bodyContentSize.height;

        CFRelease(bodyFramesetter);
        CFRelease(bodyPath);

        cellHeight += middleMargin;

        // header height
        CGMutablePathRef path = CGPathCreateMutable();
        CGRect rect3 = CGRectMake(leftOffset, cellHeight, textWidth, headerSize.height);
        CGPathAddRect(path, NULL, rect3);

        CTFrameRef tempFrame = CTFramesetterCreateFrame(headerFramesetter, CFRangeMake(0, [headerAttributedString length]), path, NULL);
        self.headerFrameRef = tempFrame;

        cellHeight += headerSize.height;

        cellHeight += topMargin;

        // cellHeight += 0.5f;
        CFRelease(headerFramesetter);
        CFRelease(path);

        self.cellHeight = cellHeight;
        self.frameRect = CGRectMake(0, 0, width, cellHeight);
    }

    return self.cellHeight;
}

//CGSizeMake(textWidth, CGFLOAT_MAX)
- (CGSize)calcSize:(CTFramesetterRef)bodyFramesetter attrStr:(NSAttributedString *)attrStr withSize:(CGSize)size
{
    CGSize contentSize = CTFramesetterSuggestFrameSizeWithConstraints(
        bodyFramesetter, CFRangeMake(0, attrStr.length),
        nil, size, nil);

    return contentSize;
}

- (NSAttributedString *)genNGHeaderAttributedString:(CGFloat)baseFontSize ngItem:(NGItem *)ngItem
{
    Res *res = self.res;
    ThemeManager *tm = [ThemeManager sharedManager];

    NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc] init];
    if (res == nil) return mutable;

    BOOL isNew = res.number > self.resVmList.lastReadNumber;

    UIColor *numForegroundColor = isNew ? [tm colorForKey:ThemeResNumTextColor] : [tm colorForKey:ThemeResReadNumTextColor];
    NSNumber *numberUnderlineStyle = @(NSUnderlineStyleNone);
    if (self.highlightIndex == kResNumberArea) {
        numForegroundColor = [[ThemeManager sharedManager] colorForKey:ThemeResHighlightTextColor];
        numberUnderlineStyle = @(NSUnderlineStyleSingle); //@(NSUnderlineStyleNone);
    }
    [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                        initWithString:[NSString stringWithFormat:@"%d", res.number]
                                            attributes:@{ NSForegroundColorAttributeName : numForegroundColor,
                                                          NSUnderlineStyleAttributeName : numberUnderlineStyle, @"node" : @(kResNumberArea),
                                                          NSFontAttributeName : isNew ? [UIFont boldSystemFontOfSize:baseFontSize + 0.5f] : [UIFont systemFontOfSize:baseFontSize + 0.5f],

                                            }]];

    if (res.refferedResSet) {
        NSInteger refCount = [res.refferedResSet count];
        if (refCount > 0) {
            [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                                initWithString:[NSString stringWithFormat:@"(%ld)", (long)refCount]
                                                    attributes:@{ NSForegroundColorAttributeName : numForegroundColor,
                                                                  NSUnderlineStyleAttributeName : numberUnderlineStyle, @"node" : @(kResNumberArea),
                                                                  NSFontAttributeName : [UIFont fontWithName:@"AppleGothic" size:baseFontSize - 2.f],

                                                    }]];
        }
    }

    NSDictionary *attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  [UIFont systemFontOfSize:baseFontSize], NSFontAttributeName, nil];

    [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                        initWithString:@"  "
                                            attributes:attributes2]];

    UIColor *ngTextColor = self.highlightIndex == kResNGReasonArea ? [[ThemeManager sharedManager] colorForKey:ThemeResHighlightTextColor] : [tm colorForKey:ThemeSubTextColor];

    NSString *ngResonText = [NSString stringWithFormat:[ngItem typeString], ngItem.value];

    NSNumber *nameUnderlineStyle = self.highlightIndex == kResNGReasonArea ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
    [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                        initWithString:ngResonText
                                            attributes:@{
                                                NSFontAttributeName : [UIFont systemFontOfSize:baseFontSize],
                                                NSUnderlineStyleAttributeName : nameUnderlineStyle,
                                                @"node" : @(kResNGReasonArea),
                                                NSForegroundColorAttributeName : ngTextColor
                                            }]];

    return mutable;
}
- (NSAttributedString *)genHeaderAttributedString:(CGFloat)baseFontSize
{
    Res *res = self.res;
    ThemeManager *tm = [ThemeManager sharedManager];

    NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc] init];
    if (res == nil) return mutable;

    NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
    paragrahStyle.lineHeightMultiple = 0.85f;
    paragrahStyle.alignment = NSTextAlignmentRight;

    BOOL isNew = res.number > self.resVmList.lastReadNumber;
    UIColor *numForegroundColor = isNew ? [tm colorForKey:ThemeResNumTextColor] : [tm colorForKey:ThemeResReadNumTextColor];
    NSNumber *numberUnderlineStyle = @(NSUnderlineStyleNone);
    if (self.highlightIndex == kResNumberArea) {
        numForegroundColor = [[ThemeManager sharedManager] colorForKey:ThemeResHighlightTextColor];
        numberUnderlineStyle = @(NSUnderlineStyleSingle); //@(NSUnderlineStyleNone);
    }
    [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                        initWithString:[NSString stringWithFormat:@"%d", res.number]
                                            attributes:@{ NSForegroundColorAttributeName : numForegroundColor,
                                                          NSUnderlineStyleAttributeName : numberUnderlineStyle, @"node" : @(kResNumberArea),
                                                          NSFontAttributeName : isNew ? [UIFont boldSystemFontOfSize:baseFontSize + 0.5f] : [UIFont systemFontOfSize:baseFontSize + 0.5f],

                                            }]];

    if (res.refferedResSet) {
        NSInteger refCount = [res.refferedResSet count];
        if (refCount > 0) {
            [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                                initWithString:[NSString stringWithFormat:@"(%ld)", (long)refCount]
                                                    attributes:@{ NSForegroundColorAttributeName : numForegroundColor,
                                                                  NSUnderlineStyleAttributeName : numberUnderlineStyle, @"node" : @(kResNumberArea),
                                                                  NSFontAttributeName : [UIFont fontWithName:@"AppleGothic" size:baseFontSize - 2.f],

                                                    }]];
        }
    }

    if (res.name != nil) {
        UIColor *nameTextColor = nil;
        if (self.highlightIndex == kResNameArea) {
            nameTextColor = [[ThemeManager sharedManager] colorForKey:ThemeResHighlightTextColor];
        } else if (res.nameColor) {
            UIColor *color = [ResVm getUIColorForNameColor:res.nameColor];
            if (color)
                nameTextColor = color;
        }

        if (nameTextColor == nil) {
            nameTextColor = [tm colorForKey:ThemeResNameTextColor];
        }

        NSNumber *nameUnderlineStyle = self.highlightIndex == kResNameArea ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:[@"  " stringByAppendingString:res.name]
                                                attributes:@{
                                                    NSParagraphStyleAttributeName : paragrahStyle,
                                                    NSFontAttributeName : [UIFont systemFontOfSize:baseFontSize],
                                                    NSUnderlineStyleAttributeName : nameUnderlineStyle,
                                                    @"node" : @(kResNameArea),
                                                    NSForegroundColorAttributeName : nameTextColor
                                                }]];
    }

    if (res.mail != nil) {
        UIColor *mailTextColor = self.highlightIndex == kResMailArea ? [[ThemeManager sharedManager] colorForKey:ThemeResHighlightTextColor] : [tm colorForKey:ThemeResMailTextColor];
        NSNumber *mailUnderlineStyle = self.highlightIndex == kResMailArea ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:[[@" " stringByAppendingString:res.mail] stringByAppendingString:@""]
                                                attributes:@{
                                                    NSParagraphStyleAttributeName : paragrahStyle,
                                                    NSFontAttributeName : [UIFont systemFontOfSize:baseFontSize],
                                                    NSUnderlineStyleAttributeName : mailUnderlineStyle,
                                                    @"node" : @(kResMailArea),
                                                    NSForegroundColorAttributeName : mailTextColor
                                                }]];
    }

    if (res.dateStr != nil) {
        UIColor *dateForegroundColor = [tm colorForKey:ThemeResDateTextColor];
        NSString *strDate = res.timeStr ? [[res.dateStr stringByAppendingString:@" "] stringByAppendingString:res.timeStr] : res.dateStr;
        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:[@" " stringByAppendingString:strDate]
                                                attributes:@{
                                                    NSParagraphStyleAttributeName : paragrahStyle,
                                                    NSFontAttributeName : [UIFont systemFontOfSize:baseFontSize],
                                                    NSForegroundColorAttributeName : dateForegroundColor
                                                }]];
    }

    if (res.ID != nil) {
        NSDictionary *attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      paragrahStyle, NSParagraphStyleAttributeName,
                                                      [UIFont systemFontOfSize:baseFontSize], NSFontAttributeName, nil];

        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:@" "
                                                attributes:attributes2]];

        NSArray *numbers = [self.th.resListById objectForKey:res.ID];
        NSUInteger count = [numbers count];

        NSString *idStr = res.ID;
        UIColor *idTextColor = self.highlightIndex == kResIDArea ? [tm colorForKey:ThemeResHighlightTextColor] : (
                                                                                                             [tm colorForKey:count > 1 ? (count > 4 ? ThemeResManyIDTextColor : ThemeResMultiIDTextColor) : ThemeResHeaderIDTextColor]);
        if (count > 1) {
            idStr = [NSString stringWithFormat:@"%@ (%ld/%ld)", res.ID, (long)(res.idOrder + 1), (unsigned long)count];
        }

        NSNumber *idUnderlineStyle = self.highlightIndex == kResIDArea ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);

        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     paragrahStyle, NSParagraphStyleAttributeName,
                                                     idTextColor,
                                                     NSForegroundColorAttributeName, idUnderlineStyle, NSUnderlineStyleAttributeName,
                                                     @(kResIDArea), @"node",
                                                     [UIFont systemFontOfSize:baseFontSize], NSFontAttributeName, nil];

        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:idStr
                                                attributes:attributes]];
    }

    if (res.BEID != nil) {
        NSDictionary *attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      paragrahStyle, NSParagraphStyleAttributeName,
                                                      [UIFont systemFontOfSize:baseFontSize], NSFontAttributeName, nil];

        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:@" "
                                                attributes:attributes2]];

        NSString *beidStr = [NSString stringWithFormat:@"?%@(%d)", res.BERank, res.BEPoint];

        UIColor *idTextColor = self.highlightIndex == kResBEIDArea ? [[ThemeManager sharedManager] colorForKey:ThemeResHighlightTextColor] : [tm colorForKey:ThemeResHeaderIDTextColor];
        NSNumber *idUnderlineStyle = self.highlightIndex == kResBEIDArea ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);

        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     paragrahStyle, NSParagraphStyleAttributeName,
                                                     idTextColor,
                                                     NSForegroundColorAttributeName, idUnderlineStyle, NSUnderlineStyleAttributeName,
                                                     @(kResBEIDArea), @"node",
                                                     [UIFont systemFontOfSize:baseFontSize], NSFontAttributeName, nil];

        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:beidStr
                                                attributes:attributes]];
    }

    return mutable;
}

- (NSAttributedString *)genBodyAttributedString:(CGFloat)fontSize useAAFont:(BOOL)useAAFont
{
    Res *res = self.res;
    BOOL isAA = [res checkIsAA];

    NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
    paragrahStyle.lineHeightMultiple = (isAA) ? 0.88f : 1.082f; //0.83f

    ThemeManager *tm = [ThemeManager sharedManager];

    NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc] init];
    if (res == nil) return mutable;

    UIFont *font = useAAFont ? [UIFont fontWithName:AAFontPostscriptName size:fontSize] : [UIFont systemFontOfSize:fontSize];


    NSInteger index = 0;
    for (ResNodeBase *node in res.bodyNodes) {
        index++;
        node.indexInRes = index;

        NSNumber *underlineStyle = node.indexInRes == self.highlightIndex ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
        UIColor *textColor = node.indexInRes == self.highlightIndex ? [[ThemeManager sharedManager] colorForKey:ThemeResHighlightTextColor] : [tm colorForKey:ThemeResLinkTextColor];

        if ([node isKindOfClass:[AnchorNode class]]) {
            UIColor *anchorColor = node.indexInRes == self.highlightIndex ? [[ThemeManager sharedManager] colorForKey:ThemeResHighlightTextColor] : [tm colorForKey:ThemeResAnchorTextColor];

            [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                                initWithString:[node getText]
                                                    attributes:@{ NSFontAttributeName : font,
                                                                  NSParagraphStyleAttributeName : paragrahStyle,
                                                                  @"node" : node,
                                                                  NSUnderlineStyleAttributeName : underlineStyle,
                                                                  NSForegroundColorAttributeName : anchorColor,
                                                    }]];

        } else if ([node isKindOfClass:[LinkNode class]]) {

            [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                                initWithString:[node getText]
                                                    attributes:@{ NSFontAttributeName : font,
                                                                  @"node" : node,
                                                                  NSParagraphStyleAttributeName : paragrahStyle,
                                                                  NSUnderlineStyleAttributeName : underlineStyle,
                                                                  NSForegroundColorAttributeName : textColor }]];

        } else if ([node isKindOfClass:[LineBreakNode class]]) {
            [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                                initWithString:[node getText]
                                                    attributes:@{ NSFontAttributeName : font,
                                                                  @"node" : node,
                                                                  NSParagraphStyleAttributeName : paragrahStyle }]];

        } else if ([node isKindOfClass:[IDNode class]]) {
            [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                                initWithString:[node getText]
                                                    attributes:@{ NSFontAttributeName : font,
                                                                  @"node" : node,
                                                                  NSUnderlineStyleAttributeName : underlineStyle,
                                                                  NSParagraphStyleAttributeName : paragrahStyle,
                                                                  NSForegroundColorAttributeName : textColor }]];

        } else if ([node isKindOfClass:[TextNode class]]) {
            NSString *text = [node getText];

            [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                                initWithString:text
                                                    attributes:@{ NSFontAttributeName : font,
                                                                  @"node" : node,
                                                                  NSParagraphStyleAttributeName : paragrahStyle,
                                                                  NSForegroundColorAttributeName : [tm colorForKey:self.isReadBody ? ThemeResReadRefTextColor : ThemeNormalColor] }]];
        }
    }

    return mutable;
}

+ (UIColor *)getUIColorForNameColor:(NSString *)nameColor
{
    if (_nameColorDict == nil) {

        NSMutableDictionary *dict = _nameColorDict = [NSMutableDictionary dictionary];

        dict[@"black"] = @"#000000";
        dict[@"aliceblue"] = @"#f0f8ff";
        dict[@"darkcyan"] = @"#008b8b";
        dict[@"lightyellow"] = @"#ffffe0";
        dict[@"coral"] = @"#ff7f50";
        dict[@"dimgray"] = @"#696969";
        dict[@"lavender"] = @"#e6e6fa";
        dict[@"teal"] = @"#008080";
        dict[@"lightgoldenrodyellow"] = @"#fafad2";
        dict[@"tomato"] = @"#ff6347";
        dict[@"gray"] = @"#808080";
        dict[@"lightsteelblue"] = @"#b0c4de";
        dict[@"darkslategray"] = @"#2f4f4f";
        dict[@"lemonchiffon"] = @"#fffacd";
        dict[@"orangered"] = @"#ff4500";
        dict[@"darkgray"] = @"#a9a9a9";
        dict[@"lightslategray"] = @"#778899";
        dict[@"darkgreen"] = @"#006400";
        dict[@"wheat"] = @"#f5deb3";
        dict[@"red"] = @"#ff0000";
        dict[@"silver"] = @"#c0c0c0";
        dict[@"slategray"] = @"#708090";
        dict[@"green"] = @"#008000";
        dict[@"burlywood"] = @"#deb887";
        dict[@"crimson"] = @"#dc143c";
        dict[@"lightgrey"] = @"#d3d3d3";
        dict[@"steelblue"] = @"#4682b4";
        dict[@"forestgreen"] = @"#228b22";
        dict[@"tan"] = @"#d2b48c";
        dict[@"mediumvioletred"] = @"#c71585";
        dict[@"gainsboro"] = @"#dcdcdc";
        dict[@"royalblue"] = @"#4169e1";
        dict[@"seagreen"] = @"#2e8b57";
        dict[@"khaki"] = @"#f0e68c";
        dict[@"deeppink"] = @"#ff1493";
        dict[@"whitesmoke"] = @"#f5f5f5";
        dict[@"midnightblue"] = @"#191970";
        dict[@"mediumseagreen"] = @"#3cb371";
        dict[@"yellow"] = @"#ffff00";
        dict[@"hotpink"] = @"#ff69b4";
        dict[@"white"] = @"#ffffff";
        dict[@"navy"] = @"#000080";
        dict[@"mediumaquamarine"] = @"#66cdaa";
        dict[@"gold"] = @"#ffd700";
        dict[@"palevioletred"] = @"#db7093";
        dict[@"snow"] = @"#fffafa";
        dict[@"darkblue"] = @"#00008b";
        dict[@"darkseagreen"] = @"#8fbc8f";
        dict[@"orange"] = @"#ffa500";
        dict[@"pink"] = @"#ffc0cb";
        dict[@"ghostwhite"] = @"#f8f8ff";
        dict[@"mediumblue"] = @"#0000cd";
        dict[@"aquamarine"] = @"#7fffd4";
        dict[@"sandybrown"] = @"#f4a460";
        dict[@"lightpink"] = @"#ffb6c1";
        dict[@"floralwhite"] = @"#fffaf0";
        dict[@"blue"] = @"#0000ff";
        dict[@"palegreen"] = @"#98fb98";
        dict[@"darkorange"] = @"#ff8c00";
        dict[@"thistle"] = @"#d8bfd8";
        dict[@"linen"] = @"#faf0e6";
        dict[@"dodgerblue"] = @"#1e90ff";
        dict[@"lightgreen"] = @"#90ee90";
        dict[@"goldenrod"] = @"#daa520";
        dict[@"magenta"] = @"#ff00ff";
        dict[@"antiquewhite"] = @"#faebd7";
        dict[@"cornflowerblue"] = @"#6495ed";
        dict[@"springgreen"] = @"#00ff7f";
        dict[@"peru"] = @"#cd853f";
        dict[@"fuchsia"] = @"#ff00ff";
        dict[@"papayawhip"] = @"#ffefd5";
        dict[@"deepskyblue"] = @"#00bfff";
        dict[@"mediumspringgreen"] = @"#00fa9a";
        dict[@"darkgoldenrod"] = @"#b8860b";
        dict[@"violet"] = @"#ee82ee";
        dict[@"blanchedalmond"] = @"#ffebcd";
        dict[@"lightskyblue"] = @"#87cefa";
        dict[@"lawngreen"] = @"#7cfc00";
        dict[@"chocolate"] = @"#d2691e";
        dict[@"plum"] = @"#dda0dd";
        dict[@"bisque"] = @"#ffe4c4";
        dict[@"skyblue"] = @"#87ceeb";
        dict[@"chartreuse"] = @"#7fff00";
        dict[@"sienna"] = @"#a0522d";
        dict[@"orchid"] = @"#da70d6";
        dict[@"moccasin"] = @"#ffe4b5";
        dict[@"lightblue"] = @"#add8e6";
        dict[@"greenyellow"] = @"#adff2f";
        dict[@"saddlebrown"] = @"#8b4513";
        dict[@"mediumorchid"] = @"#ba55d3";
        dict[@"navajowhite"] = @"#ffdead";
        dict[@"powderblue"] = @"#b0e0e6";
        dict[@"lime"] = @"#00ff00";
        dict[@"maroon"] = @"#800000";
        dict[@"darkorchid"] = @"#9932cc";
        dict[@"peachpuff"] = @"#ffdab9";
        dict[@"paleturquoise"] = @"#afeeee";
        dict[@"limegreen"] = @"#32cd32";
        dict[@"darkred"] = @"#8b0000";
        dict[@"darkviolet"] = @"#9400d3";
        dict[@"mistyrose"] = @"#ffe4e1";
        dict[@"lightcyan"] = @"#e0ffff";
        dict[@"yellowgreen"] = @"#9acd32";
        dict[@"brown"] = @"#a52a2a";
        dict[@"darkmagenta"] = @"#8b008b";
        dict[@"lavenderblush"] = @"#fff0f5";
        dict[@"cyan"] = @"#00ffff";
        dict[@"darkolivegreen"] = @"#556b2f";
        dict[@"firebrick"] = @"#b22222";
        dict[@"purple"] = @"#800080";
        dict[@"seashell"] = @"#fff5ee";
        dict[@"aqua"] = @"#00ffff";
        dict[@"olivedrab"] = @"#6b8e23";
        dict[@"indianred"] = @"#cd5c5c";
        dict[@"indigo"] = @"#4b0082";
        dict[@"oldlace"] = @"#fdf5e6";
        dict[@"turquoise"] = @"#40e0d0";
        dict[@"olive"] = @"#808000";
        dict[@"rosybrown"] = @"#bc8f8f";
        dict[@"darkslateblue"] = @"#483d8b";
        dict[@"ivory"] = @"#fffff0";
        dict[@"mediumturquoise"] = @"#48d1cc";
        dict[@"darkkhaki"] = @"#bdb76b";
        dict[@"darksalmon"] = @"#e9967a";
        dict[@"blueviolet"] = @"#8a2be2";
        dict[@"honeydew"] = @"#f0fff0";
        dict[@"darkturqoise"] = @"#00ced1 ";
        dict[@"palegoldenrod"] = @"#eee8aa";
        dict[@"lightcoral"] = @"#f08080 ";
        dict[@"mediumpurple"] = @"#9370db";
        dict[@"mintcream"] = @"#f5fffa";
        dict[@"lightseagreen"] = @"#20b2aa";
        dict[@"cornsilk"] = @"#fff8dc";
        dict[@"salmon"] = @"#fa8072";
        dict[@"slateblue"] = @"#6a5acd";
        dict[@"azure"] = @"#f0ffff";
        dict[@"cadetblue"] = @"#5f9ea0";
        dict[@"beige"] = @"#f5f5dc";
        dict[@"lightsalmon"] = @"#ffa07a";
        dict[@"mediumslateblue"] = @"#7b68ee";
    }

    NSString *str = [_nameColorDict objectForKey:nameColor];
    if (str) {
        UIColor *color = [ResVm hexToUIColor:[str substringFromIndex:1] alpha:1.0];
        if (color) return color;
    }
    return nil;
}

+ (UIColor *)hexToUIColor:(NSString *)hex alpha:(CGFloat)alpha
{
    NSScanner *colorScanner = [NSScanner scannerWithString:hex];
    unsigned int color;
    [colorScanner scanHexInt:&color];
    if ([hex length] == 8) {
        CGFloat a = ((color & 0xFF000000) >> 24) / 255.0f;
        CGFloat r = ((color & 0x00FF0000) >> 16) / 255.0f;
        CGFloat g = ((color & 0x0000FF00) >> 8) / 255.0f;
        CGFloat b = (color & 0x000000FF) / 255.0f;
        //myLog(@"HEX to RGB >> r:%f g:%f b:%f a:%f\n",r,g,b,a);
        return [UIColor colorWithRed:r green:g blue:b alpha:a];

    } else {
        CGFloat r = ((color & 0xFF0000) >> 16) / 255.0f;
        CGFloat g = ((color & 0x00FF00) >> 8) / 255.0f;
        CGFloat b = (color & 0x0000FF) / 255.0f;
        //myLog(@"HEX to RGB >> r:%f g:%f b:%f a:%f\n",r,g,b,a);
        return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
    }
}

@end
