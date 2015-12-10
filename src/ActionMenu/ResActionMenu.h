
//
//  ResActionMenu.h
//  Forest
//

#import "ActionMenuBase.h"
#import "ResVC.h"

@class NGItem;
@class Th;
@class ThumbnailInfo;
@class LinkNode;

@interface ResActionMenu : ActionMenuBase

@property (nonatomic) ResVC *resVC;
@property (nonatomic) Res *res;
@property (nonatomic) Th *th;
@property (nonatomic) BOOL forID;

@property (nonatomic) BOOL forNG;

@property (nonatomic) BOOL forLink; //linkのロングタップ
@property (nonatomic) LinkNode *linkNode;
@property (nonatomic) NSString *linkUrl;

@property (nonatomic) BOOL forThumbnail;
@property (nonatomic) ThumbnailInfo *thumbnailInfo;

@property (nonatomic) BOOL forCopy;

@property (nonatomic) BOOL forAll;

@property (nonatomic) BOOL forIDInText;
@property (nonatomic) NSString *idText;

@property (nonatomic) BOOL forNGItem;
@property (nonatomic) NGItem *ngItem;

@end
