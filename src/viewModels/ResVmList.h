
#import <Foundation/Foundation.h>
#import "../models/nodes/ResNodeBase.h"
#import "../models/Res.h"
#import "../models/Th.h"
#import "NGManager.h"

@class ResVm;

// ツリー化・レス順化の切替をサポートし、
// ここまで読んだのインデックスも考慮する

@interface ResVmList : NSObject 

@property (nonatomic) CGFloat width;
@property (nonatomic) BOOL treeMode;
@property (nonatomic) BOOL showNGRes;
@property (nonatomic, copy) NSArray *originalResArray;
@property (nonatomic) NSUInteger lastResNumber;
@property (nonatomic) NSUInteger lastReadNumber;
@property (nonatomic) NSInteger readMarkRow;
@property (nonatomic) NSMutableArray *serializedResVmArray; //アウトプット一次元配列
@property (nonatomic) NSMutableDictionary *resVmMap;
@property (nonatomic) NSMutableDictionary *baseResVmMapForNew;
@property (nonatomic) NSMutableArray *treeResVmArray;
@property (nonatomic) NSInteger highlightResNumber;
@property (nonatomic) NSInteger highlightType;
@property (nonatomic, weak) Th *th;

- (BOOL)getTreeMode;
- (void)rebuild;

- (NSUInteger)count;
- (void)addResList:(NSArray *)resList;
- (id)init;
- (ResVm *)resVmAtIndex:(NSInteger)number;

- (void)removeAllObjects;
- (NSInteger)rowAtOriginResNumber:(NSInteger)originResNumber;
- (void)changeReadMarkNumber:(NSInteger)num;
- (void)setBottomCellNoBottomLine:(BOOL)enabled;
- (void)popupTree:(NSMutableArray *)resList targetResList:(NSArray *)targetResList;
@end
