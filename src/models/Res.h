#import <Foundation/Foundation.h>
#import "nodes/ResNodeBase.h"

@class NGItem;

@interface Res : NSObject


@property (nonatomic, copy) NSString *text;

@property (nonatomic, copy) NSString *nameColor;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger idOrder;
@property (nonatomic, copy) NSString *dateStr;
@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSString *threadTitle;
@property (nonatomic, copy) NSString *ID;
@property (nonatomic) int number;
@property (nonatomic, copy) NSString *mail;
@property (nonatomic) BOOL isAA;
@property (nonatomic) BOOL hasImage;
@property (nonatomic) BOOL hasImageChecked;

@property (nonatomic) BOOL ngChecked;
@property (nonatomic) NGItem *ngItem;

@property (nonatomic) BOOL isMine;
@property (nonatomic) BOOL resToMe;

@property (nonatomic) BOOL isDummy;

@property (nonatomic, copy) NSString *timeStr;
@property (nonatomic, copy) NSArray *bodyNodes;
@property (nonatomic) NSMutableSet *refferedResSet;

@property (nonatomic, copy) NSString *BEID;
@property (nonatomic, copy) NSString *BERank;
@property int BEPoint;

- (id)init;
- (NSString *)naturalText;
- (NSString *)allText;
- (NSString *)naturalTextForCheckMyRes;
- (long long int)basicBEId;
- (NSString *)description;
- (BOOL)checkIsAA;
- (void)checkHasImage;
- (BOOL)hasLink;
@end
