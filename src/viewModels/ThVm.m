//
//  ThVm.m
//

#import "ThVm.h"
#import <CoreText/CoreText.h>
#import "ThemeManager.h"
#import "Env.h"

@implementation ThVm

- (id)initWithTh:(Th *)th
{
    if (self = [super init]) {
        self.cellHeight = 0;
        self.showBoardName = YES;
        self.showDate = YES;
        self.showFavState = YES;
        _th = th;

        // 変更を監視するプロパティ
        [th addObserver:self forKeyPath:@"read" options:NSKeyValueObservingOptionNew context:nil];
        [th addObserver:self forKeyPath:@"count" options:NSKeyValueObservingOptionNew context:nil];
        [th addObserver:self forKeyPath:@"boardName" options:NSKeyValueObservingOptionNew context:nil];
        [th addObserver:self forKeyPath:@"isFav" options:NSKeyValueObservingOptionNew context:nil];
        //[th addObserver:self forKeyPath:@"number" options:NSKeyValueObservingOptionNew context:nil];
        //[th addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:nil];
    }

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (self.delegate) {
        [self.delegate onThVmPropertyChanged:self name:keyPath];
    }
}

- (NSComparisonResult)compareLastReadTime:(ThVm *)thVm
{
    if (self.th.lastReadTime > thVm.th.lastReadTime) {
        return NSOrderedAscending;
    } else if (self.th.lastReadTime < thVm.th.lastReadTime) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSComparisonResult)compareNumber:(ThVm *)thVm
{
    if (self.th.lastReadTime != thVm.th.lastReadTime) {
        return [self compareLastReadTime:thVm];
    }

    if (self.th.number < thVm.th.number) {
        return NSOrderedAscending;
    } else if (self.th.number > thVm.th.number) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSComparisonResult)compareSpeed:(ThVm *)thVm
{
    return [self.th compareSpeed:thVm.th];
}
- (NSComparisonResult)compareCreated:(ThVm *)thVm
{
    if (self.th.key > thVm.th.key) {
        return NSOrderedAscending;
    } else if (self.th.key < thVm.th.key) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSComparisonResult)compareCount:(ThVm *)thVm
{
    if (self.th.count > thVm.th.count) {
        return NSOrderedAscending;
    } else if (self.th.count < thVm.th.count) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (void)releaseAllFrameRefs
{
    if (self.countFrameRef) {
        CTFrameRef frameRef = self.countFrameRef;
        self.countFrameRef = nil;
        CFRelease(frameRef);
    }

    if (self.speedFrameRef) {
        CTFrameRef frameRef = self.speedFrameRef;
        self.speedFrameRef = nil;
        CFRelease(frameRef);
    }
    if (self.titleFrameRef) {
        CTFrameRef frameRef = self.titleFrameRef;
        self.titleFrameRef = nil;
        CFRelease(frameRef);
    }
    if (self.otherFrameRef) {
        CTFrameRef frameRef = self.otherFrameRef;
        self.otherFrameRef = nil;
        CFRelease(frameRef);
    }
    if (self.newCountFrameRef) {
        CTFrameRef frameRef = self.newCountFrameRef;
        self.newCountFrameRef = nil;
        CFRelease(frameRef);
    }
    if (self.dateFrameRef) {
        CTFrameRef frameRef = self.dateFrameRef;
        self.dateFrameRef = nil;
        CFRelease(frameRef);
    }
}

- (void)dealloc
{
    if (self.th) {
        [self.th removeObserver:self forKeyPath:@"read"];
        [self.th removeObserver:self forKeyPath:@"count"];
        [self.th removeObserver:self forKeyPath:@"boardName"];
        [self.th removeObserver:self forKeyPath:@"isFav"];
        // [self.th removeObserver:self forKeyPath:@"number"];
        // [self.th removeObserver:self forKeyPath:@"progress"];
        self.delegate = nil;
    }

    self.th = nil;

    @synchronized(self)
    {
        [self releaseAllFrameRefs];
    }
}

- (CGFloat)getHeight:(CGFloat)width
{
    if (self.cellHeight > 0) {
        return self.cellHeight;
    }

    return [self calcHeight:width];
}

- (void)regenAttributedStrings:(CGFloat)width
{
    @synchronized(self)
    {
        self.cellHeight = 0;
        [self releaseAllFrameRefs];
        [self calcHeight:width];
    }
}

- (CGFloat)calcHeight:(CGFloat)width
{
    @synchronized(self)
    {
        self.flagWidth = 15;
        if (self.cellHeight > 0) return self.cellHeight;

        CGFloat metaFontSize = [Env getThreadMetaSize];

        NSAttributedString *titleAttributedString = [self genTitleAttributedString];
        NSAttributedString *countAttributedString = [self genCountAttributedString:metaFontSize];
        NSAttributedString *speedAttributedString = [self genSpeedAttributedString:metaFontSize];
        NSAttributedString *otherAttributedString = [self genOtherAttributedString:metaFontSize];
        NSAttributedString *newCountAttributedString = [self genNewCountAttributedString:metaFontSize];
        NSAttributedString *dateAttributedString = [self genDateAttributedString:metaFontSize];

        CTFramesetterRef titleFramesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)titleAttributedString);
        CTFramesetterRef countFramesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)countAttributedString);
        CTFramesetterRef speedFramesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)speedAttributedString);
        CTFramesetterRef otherFramesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)otherAttributedString);
        CTFramesetterRef newCountFramesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)newCountAttributedString);
        CTFramesetterRef dateFramesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)dateAttributedString);

        CGFloat topMargin = 6;
        CGFloat bottomMargin = 5.5;
        CGFloat heightMiddle = 3;
        CGFloat rightMargin = 6;
        CGFloat innerWidth = width - self.flagWidth - rightMargin;

        /*
         CGFloat dateWidth = 65;
         CGFloat newWidth = 35;
         CGFloat countWidth = 35;
         CGFloat speedWidth = 60;
         */
        CGFloat dateWidth = innerWidth * 0.25f;
        CGFloat newWidth = innerWidth * 0.09f;
        CGFloat countWidth = innerWidth * 0.14f;
        CGFloat speedWidth = innerWidth * 0.19f;

        // タイトル
        CGSize titleSize = [self getHeightForAttributedString:titleFramesetter
                                                    withWidth:innerWidth
                                                       length:titleAttributedString.length];

        CGFloat infoTopOffset = topMargin + titleSize.height + heightMiddle;
        CGFloat leftOffset = self.flagWidth;

        CGSize dateSize = [self getHeightForAttributedString:dateFramesetter
                                                   withWidth:dateWidth
                                                      length:dateAttributedString.length];

        // 日付
        if (self.showDate) {
            self.dateFrame = CGRectMake(leftOffset, infoTopOffset, dateWidth, dateSize.height);
            self.dateFrameRef = [self createCTFrameRef:self.dateFrame.size
                                       withFramesetter:dateFramesetter
                                                length:dateAttributedString.length];
        } else {
            dateSize = CGSizeMake(0, 0);
        }

        leftOffset += dateWidth + 5;

        // 新着数
        CGSize newCountSize = [self getHeightForAttributedString:newCountFramesetter
                                                       withWidth:newWidth
                                                          length:newCountAttributedString.length];
        self.newFrame = CGRectMake(leftOffset, infoTopOffset, newWidth, newCountSize.height);

        self.newCountFrameRef = [self createCTFrameRef:self.newFrame.size
                                       withFramesetter:newCountFramesetter
                                                length:newCountAttributedString.length];
        leftOffset += newWidth + 5;

        // レスカウント
        CGSize countSize = [self getHeightForAttributedString:countFramesetter
                                                    withWidth:countWidth
                                                       length:countAttributedString.length];
        self.countFrame = CGRectMake(leftOffset, infoTopOffset, countWidth, countSize.height);

        self.countFrameRef = [self createCTFrameRef:self.countFrame.size
                                    withFramesetter:countFramesetter
                                             length:countAttributedString.length];
        leftOffset += countWidth + 5;

        // 勢い
        CGSize speedSize = [self getHeightForAttributedString:speedFramesetter
                                                    withWidth:speedWidth
                                                       length:speedAttributedString.length];
        self.speedFrame = CGRectMake(leftOffset, infoTopOffset, speedWidth, speedSize.height);

        self.speedFrameRef = [self createCTFrameRef:self.speedFrame.size
                                    withFramesetter:speedFramesetter
                                             length:speedAttributedString.length];

        leftOffset += speedWidth + 5;

        CGFloat remainWidth = width - leftOffset - rightMargin;

        CGSize otherSize = [self getHeightForAttributedString:otherFramesetter
                                                    withWidth:remainWidth
                                                       length:otherAttributedString.length];
        // 板名・他
        if (self.showBoardName) {
            self.otherFrame = CGRectMake(leftOffset, infoTopOffset, remainWidth, otherSize.height);
            self.otherFrameRef = [self createCTFrameRef:self.otherFrame.size
                                        withFramesetter:otherFramesetter
                                                 length:otherAttributedString.length];

        } else {
            otherSize = CGSizeMake(0, 0);
        }

        CGFloat infoMaxHeight = MAX(speedSize.height, MAX(countSize.height, MAX(otherSize.height,
                                                                                MAX(dateSize.height, newCountSize.height))));
        self.cellHeight = infoTopOffset + infoMaxHeight + bottomMargin;

        // Title Frame
        CGRect rect = CGRectMake(self.flagWidth, bottomMargin + infoMaxHeight + heightMiddle, titleSize.width, titleSize.height);
        self.titleFrame = CGRectMake(0, 0, width, self.cellHeight);
        self.titleFrameRef = [self createCTFrameRefWithRect:rect
                                            withFramesetter:titleFramesetter
                                                     length:titleAttributedString.length];

        CFRelease(titleFramesetter);
        CFRelease(countFramesetter);
        CFRelease(speedFramesetter);
        CFRelease(otherFramesetter);
        CFRelease(newCountFramesetter);
        CFRelease(dateFramesetter);
    }

    return self.cellHeight;
}

- (CGFloat)max:(CGFloat)a b:(CGFloat)b
{
    return a > b ? a : b;
}

- (CTFrameRef)createCTFrameRef:(CGSize)size withFramesetter:(CTFramesetterRef)framesetter length:(NSInteger)length
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    return [self createCTFrameRefWithRect:rect withFramesetter:framesetter length:length];
}

- (CTFrameRef)createCTFrameRefWithRect:(CGRect)rect withFramesetter:(CTFramesetterRef)framesetter length:(NSInteger)length
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);

    CTFrameRef tempFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, length), path, NULL);

    CFRelease(path);

    return tempFrame;
}

- (CGSize)getHeightForAttributedString:(CTFramesetterRef)framesetter withWidth:(CGFloat)width length:(NSInteger)length
{
    // 描画に必要なサイズを取得
    CGSize titleContentSize = CTFramesetterSuggestFrameSizeWithConstraints(
        framesetter, CFRangeMake(0, length), nil, CGSizeMake(width, CGFLOAT_MAX), nil);
    return titleContentSize;
}

- (NSAttributedString *)genTitleAttributedString
{
    return [self generateTitleAttributeString:self.th.title ? self.th.title : @""];
}

- (NSAttributedString *)generateTitleAttributeString:(NSString *)title
{

    if (title == nil) {
        title = @"";
    }

    NSString *rawTitle = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc] init];
    ThemeManager *tm = [ThemeManager sharedManager];

    UIColor *normalColor = [tm colorForKey:ThemeNormalColor];
    UIColor *subColor = [tm colorForKey:ThemeSubTextColor];

    UIFont *font = [UIFont systemFontOfSize:[Env getThreadTitleSize]];

    NSString *targetPrefix = @"[転載禁止]";
    if ([rawTitle hasPrefix:targetPrefix]) {
        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:targetPrefix
                                                attributes:@{
                                                    NSForegroundColorAttributeName : subColor,
                                                    NSFontAttributeName : font
                                                }]];

        rawTitle = [rawTitle substringFromIndex:[targetPrefix length]];
    }

    NSString *targetSuffix = nil;

    if ([rawTitle hasSuffix:@"[無断転載禁止]©2ch.net"]) {
        targetSuffix = @"[無断転載禁止]©2ch.net";
    } else if ([rawTitle hasSuffix:@"[転載禁止]©2ch.net"]) {
        targetSuffix = @"[転載禁止]©2ch.net";
    } else if ([rawTitle hasSuffix:@"©2ch.net"]) {
        targetSuffix = @"©2ch.net";
    } else if ([rawTitle hasSuffix:@"[無断転載禁止]©bbspink.com"]) {
        targetSuffix = @"[無断転載禁止]©bbspink.com";
    } else if ([rawTitle hasSuffix:@"[転載禁止]©bbspink.com"]) {
        targetSuffix = @"[転載禁止]©bbspink.com";
    } else if ([rawTitle hasSuffix:@"©bbspink.com"]) {
        targetSuffix = @"©bbspink.com";
    } else {
        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:rawTitle
                                                attributes:@{
                                                    NSForegroundColorAttributeName : normalColor,
                                                    NSFontAttributeName : font
                                                }]];
    }
    if (targetSuffix != nil) {
        NSRange range = [rawTitle rangeOfString:targetSuffix];
        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:[rawTitle substringToIndex:range.location]
                                                attributes:@{
                                                    NSForegroundColorAttributeName : normalColor,
                                                    NSFontAttributeName : font
                                                }]];
        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:targetSuffix
                                                attributes:@{
                                                    NSForegroundColorAttributeName : subColor,
                                                    NSFontAttributeName : font
                                                }]];
    }

    return mutable;
}

- (NSAttributedString *)genSpeedAttributedString:(CGFloat)baseFontSize
{
    NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc] init];
    UIColor *foregroundColor = [[ThemeManager sharedManager] colorForKey:ThemeThListSpeedColor];

    float speed = [self.th calcSpeed];
    CTParagraphStyleRef rightPara = [self getRightAlignmentAttr];

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(rightPara),
                                                                          (id)kCTParagraphStyleAttributeName, [UIFont systemFontOfSize:baseFontSize], NSFontAttributeName, foregroundColor, NSForegroundColorAttributeName, nil];

    [mutable appendAttributedString:
                 [[NSMutableAttributedString alloc]
                     initWithString:[NSString stringWithFormat:((speed < 100) ? @"%.1f" : @"%.0f"), speed]
                         attributes:attributes]];

    CFRelease(rightPara);

    attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:baseFontSize - 1.f], NSFontAttributeName, [[ThemeManager sharedManager] colorForKey:ThemeSubTextColor], NSForegroundColorAttributeName, nil];

    [mutable appendAttributedString:
                 [[NSMutableAttributedString alloc]
                     initWithString:@"/"
                         attributes:attributes]];

    attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:baseFontSize - 2.5f], NSFontAttributeName, [[ThemeManager sharedManager] colorForKey:ThemeSubTextColor], NSForegroundColorAttributeName, nil];

    [mutable appendAttributedString:
                 [[NSMutableAttributedString alloc]
                     initWithString:@"日"
                         attributes:attributes]];
    return mutable;
}

- (CTParagraphStyleRef)getRightAlignmentAttr
{
    CTTextAlignment theAlignment = kCTRightTextAlignment;
    CFIndex theNumberOfSettings = 1;
    CTParagraphStyleSetting theSettings[1] = {{kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &theAlignment}};
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, theNumberOfSettings);
    return theParagraphRef;
}

- (NSAttributedString *)genCountAttributedString:(CGFloat)baseFontSize
{
    NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc] init];
    UIColor *foregroundColor = [[ThemeManager sharedManager] colorForKey:ThemeThListCountColor];

    CTTextAlignment theAlignment = kCTRightTextAlignment;
    CFIndex theNumberOfSettings = 1;
    CTParagraphStyleSetting theSettings[1] = {{kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &theAlignment}};
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, theNumberOfSettings);
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(theParagraphRef), (id)kCTParagraphStyleAttributeName, [UIFont systemFontOfSize:baseFontSize], NSFontAttributeName, foregroundColor, NSForegroundColorAttributeName, nil];

    [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                        initWithString:[NSString stringWithFormat:@"%lu", (unsigned long)self.th.count]
                                            attributes:attributes]];
    CFRelease(theParagraphRef);
    return mutable;
}

- (NSAttributedString *)genOtherAttributedString:(CGFloat)baseFontSize
{
    NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc] init];

    UIColor *foregroundColor = [[ThemeManager sharedManager] colorForKey:ThemeSubTextColor];

    CTTextAlignment theAlignment = kCTRightTextAlignment;
    CFIndex theNumberOfSettings = 1;
    CTParagraphStyleSetting theSettings[1] = {{kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &theAlignment}};
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, theNumberOfSettings);
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(theParagraphRef), (id)kCTParagraphStyleAttributeName, [UIFont systemFontOfSize:baseFontSize], NSFontAttributeName, foregroundColor, NSForegroundColorAttributeName, nil];

    NSString *boardString = (self.th.board && self.th.board.boardName) ? self.th.board.boardName : self.th.boardKey;

    [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                        initWithString:[NSString stringWithFormat:@"%@", boardString]
                                            attributes:attributes]];
    CFRelease(theParagraphRef);
    return mutable;
}

- (NSAttributedString *)genNewCountAttributedString:(CGFloat)baseFontSize
{
    NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc] init];
    if ([self.th unreadCount] <= 0 || self.th.lastReadTime == 0) {
        return mutable;
    }

    UIColor *foregroundColor = [[ThemeManager sharedManager] colorForKey:ThemeThListUnreadCountColor];

    CTTextAlignment theAlignment = kCTRightTextAlignment;
    CFIndex theNumberOfSettings = 1;
    CTParagraphStyleSetting theSettings[1] = {{kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &theAlignment}};
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, theNumberOfSettings);
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(theParagraphRef), (id)kCTParagraphStyleAttributeName, [UIFont systemFontOfSize:baseFontSize], NSFontAttributeName, foregroundColor, NSForegroundColorAttributeName, nil];

    [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                        initWithString:[NSString stringWithFormat:@"%d", (int)([self.th unreadCount])]
                                            attributes:attributes]];

    CFRelease(theParagraphRef);
    return mutable;
}

- (NSAttributedString *)genDateAttributedString:(CGFloat)baseFontSize
{
    NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc] init];

    UIColor *foregroundColor = [[ThemeManager sharedManager] colorForKey:ThemeSubTextColor];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.th.key];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

    if ([self isThisYear:date]) {
        [formatter setDateFormat:@"M/d H:mm"];
    } else {
        [formatter setDateFormat:@"yyyy/M/d"];
    }

    NSString *date_string = [formatter stringFromDate:date];

    [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                        initWithString:date_string
                                            attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:baseFontSize], NSForegroundColorAttributeName : foregroundColor}]];

    if (self.th.isFav && self.showFavState) {
        UIColor *yellowColor = [[ThemeManager sharedManager] colorForKey:ThemeThListFavMarkColor];
        [mutable appendAttributedString:[[NSMutableAttributedString alloc]
                                            initWithString:@" ★"
                                                attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:baseFontSize], NSForegroundColorAttributeName : yellowColor}]];
    }

    return mutable;
}

- (BOOL)isThisYear:(NSDate *)date
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:NSYearCalendarUnit fromDate:date];
    NSInteger year = [components year];

    NSDate *now = [NSDate date];
    NSCalendar *cal2 = [NSCalendar currentCalendar];
    NSDateComponents *components2 = [cal2 components:NSYearCalendarUnit fromDate:now];
    return [components2 year] == year;
}

@end
