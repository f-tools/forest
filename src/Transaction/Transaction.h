//
//  Transaction.h
//  Forest
//

#import <Foundation/Foundation.h>

@class Transaction;

@protocol TransactionDelegate <NSObject>
@required
- (void)progressChanged:(Transaction*)transaction withProgress:(CGFloat)progress;
- (void)titleChanged:(Transaction*)transaction;
@end



@interface Transaction : NSObject


@property (nonatomic) BOOL isNavigationTransaction;
@property (nonatomic) CGFloat progress;

@property (nonatomic) BOOL isCanceled;
@property (nonatomic) NSUInteger prevProgressChangeTime;

@property (nonatomic, copy) NSString* title;

@property (nonatomic, weak) UINavigationBar* navigationBar;
@property (nonatomic, weak) UIProgressView* progressView;
@property (nonatomic, weak) UINavigationItem * navItem;
@property (nonatomic, weak) UIView* navBorder;
@property (nonatomic, weak) UIBarButtonItem *cancelRightButton;
@property (nonatomic, weak) UILabel* navigationTitleLabel;

@property (weak, nonatomic) id<TransactionDelegate> delegate;

//リクエストしたコントローラー
@property(nonatomic) UIViewController* viewController;


+ (id) navigationTransaction;
+ (id) progressTransaction;

- (void) changeProgress:(CGFloat)progress;
- (void) changeTitle:(NSString*) title;
- (void) performCancel;
- (void) didCancel:(Transaction*)transaction;


@end
