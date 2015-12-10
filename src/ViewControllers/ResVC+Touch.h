//
//  ResVC+Touch.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "ResVC.h"
#import "ResVmList.h"

@interface PopupEntry : NSObject <FastTableViewDataSource, FastTableViewDelegate>

@property (nonatomic, copy) NSString *title;
@property (nonatomic) UIView *view;
@property (nonatomic) ResTableView *tableView;
@property (nonatomic) BOOL hidden;
@property (nonatomic) NSInteger type;
@property (nonatomic) BOOL ngOffMode;
@property (nonatomic) PopupEntry *prev;
@property (nonatomic) Th *th;
@property (nonatomic) BOOL odd;
@property (nonatomic) ResVmList *resVmList;
@property (nonatomic) NSInteger currentCellTag;
@property (nonatomic) NSInteger highlightResNumber;
@property (nonatomic) BOOL shouldScrollEnabled;

- (void)setTarget:(ResVmList *)resVmList withTh:(Th *)th withRect:(CGRect)realRect;
- (NSUInteger)extraHeight;
- (NSUInteger)extraWidth;

@end

@interface ResVC (Touch)

- (IBAction)refreshTapAction:(id)sender;
- (IBAction)backButtonAction:(id)sender;

- (void)closeSearchMode:(void (^)(void))completionBlock;
- (void)startSearchWithText:(NSString *)searchText;
- (void)closeOnePopupEntry:(PopupEntry *)stopPopupEntry oneMode:(BOOL)oneMode;
- (void)handleTouchBeganEvent:(UITouch *)touch;
- (void)handleTouchEndedEvent:(UITouch *)touch;
- (void)handleTouchMovedEvent:(UITouch *)touch;
- (void)handleTouchCanceledEvent:(UITouch *)touch;

@end
