//
//  PostConfirmVC.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "PostNaviVC.h"
#import "BBSItemBase.h"

@protocol PostSessionResultDelegate <NSObject>

- (void)onPostResult:(NSInteger)statusCode resultType:(PostResultType)type resultBody:(NSString *)body;

@end

@interface PostConfirmVC : UIViewController <PostSessionResultDelegate>
@property (nonatomic) PostNaviVC *postNaviVC;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *mail;
@property (nonatomic, copy) NSString *threadTitle;

@property (nonatomic, copy) NSString *text;

@property (weak, nonatomic) IBOutlet UITextView *contentTextView;

@property (weak, nonatomic) IBOutlet UIButton *proceedButton;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (weak, nonatomic) IBOutlet UIWebView *contentWebView;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIView *borderView;
@property (weak, nonatomic) IBOutlet UIView *middleBorderView;

@end

@interface PostSession : NSObject {
}

@property (nonatomic) Th *th;
@property (nonatomic) Board *board;
@property (nonatomic) BOOL createThreadMode;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *mail;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *threadTitle;

@property (weak, nonatomic) id<PostSessionResultDelegate> delegate;

- (void)startPost;

@end
