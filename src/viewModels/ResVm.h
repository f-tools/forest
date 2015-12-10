#import <Foundation/Foundation.h>
#import "../models/nodes/ResNodeBase.h"
#import "../models/Res.h"
#import "../models/Th.h"
#import <CoreText/CoreText.h>
#import "ResVmList.h"
#import "NGManager.h"
#import "LinkNode.h"
#import <SDWebImage/SDImageCache.h>
#import "FastTableView.h"

@interface ThumbnailInfo : NSObject

@property (nonatomic) UIImage *image;
@property (nonatomic) LinkNode *linkNode;
@property (nonatomic) CGRect frame;
@property (nonatomic, copy) NSString *url;
@property (nonatomic) NSInteger receivedSize;
@property (nonatomic) NSInteger expectedSize;
@property (nonatomic) BOOL loadStarted;
@property (nonatomic) BOOL hasError;
@property (copy, nonatomic) void (^completion)(ThumbnailInfo *info, UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL);
@property (copy, nonatomic) void (^progress)(ThumbnailInfo *info, NSInteger receivedSize, NSInteger expectedSize);
@end


extern const NSInteger kResNumberArea; // -1
extern const NSInteger kResNameArea; // -2
extern const NSInteger kResMailArea; // -4
extern const NSInteger kResIDArea; // -3
extern const NSInteger kResBEIDArea; // -5
extern const NSInteger kResNGReasonArea; // -7


@class ResTableViewCell;

@interface ResVm : FastViewModelBase

@property (nonatomic) BOOL isHiddenAborn;

@property (nonatomic) NSMutableArray *thumbnailList;
@property (nonatomic) CGFloat thumbnailTotalHeight;
@property (nonatomic) CGRect thumbnailFrame;

@property (nonatomic) CTFrameRef headerFrameRef;
@property (nonatomic) CTFrameRef bodyFrameRef;

@property (nonatomic) NSInteger highlightIndex;
@property (weak, nonatomic) ThumbnailInfo *highlightThumbnail;
@property (nonatomic) NSInteger belowDepth; //下線を引く時には、下の階層レベルに合わせて引く
@property (weak, nonatomic) ResVm *nextResVm;     //下線を引く時には、下の階層レベルに合わせて引く

@property (nonatomic) BOOL isReadBody; //ツリー表示時、新着レスのアンカー先が既読の時はグレー化する
@property (nonatomic) BOOL noBottomLine; //下線は引かない
@property (nonatomic) NSInteger belowDepthSeparatorOffset;

@property (nonatomic) CGRect frameRect;
@property (nonatomic) CGRect bodyFrameRect;

@property (nonatomic) NSAttributedString *headerAttributedString;
@property (nonatomic) NSAttributedString *bodyAttributedString;

@property (nonatomic) CGFloat width;

@property (nonatomic) NSInteger originResNumber; //ツリー表示有効時、ツリーの元(最上位参照)となるインデックスを保持する

@property (nonatomic) NSInteger depth;
@property (nonatomic) NSInteger depthSeparatorOffset;
@property (nonatomic, weak) Res *res;
@property (nonatomic) BOOL highlight;
@property (weak) Th *th;
@property (weak) ResVmList *resVmList;

@property NSMutableArray *childs; //子要素のResVm

- (void)drawRect:(CGRect)rect;
- (void)addChild:(ResVm *)child;

- (void)releaseThumbnails;
- (void)releaseFrameRefs;

@end
