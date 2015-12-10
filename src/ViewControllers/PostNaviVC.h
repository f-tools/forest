#import "BaseModalNavigationVC.h"

#import "Board.h"
#import "Th.h"
#import "ResVC.h"

//書き込みのためのNavigation Controller 「テキスト編集」と「確認＆送信＆承認」２画面構成

@interface PostNaviVC : BaseModalNavigationVC

@property (nonatomic) Th *th;
@property (nonatomic) Th *originThread;
@property (nonatomic) Board *board;
@property (nonatomic) ResVC *resVC;
@property (copy, nonatomic) void (^onPostCompleted)(BOOL success);


- (void)applyOriginThread:(Th *)originThread res1Text:(NSString *)res1Text;

- (void)notifyPostSuccess;
- (void)pushPostEditVC;
- (void)addText:(NSString *)text;

@end


//
//  PostThreadTitleVC.h
//  Forest
//

@interface PostThreadTitleVC : UIViewController

@property PostNaviVC *postNaviVC;

@property (weak, nonatomic) IBOutlet UILabel *prevThreadLabel;
@property (weak, nonatomic) IBOutlet UITextView *prevTitleTextView;
@property (weak, nonatomic) IBOutlet UILabel *nextLabel;
@property (weak, nonatomic) IBOutlet UITextView *nextTextView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UIView *centerSeparator;
@property (weak, nonatomic) IBOutlet UIView *border;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *buttonsContainer;
@property (weak, nonatomic) IBOutlet UIButton *duplicateButton;

- (void)onOriginThreadChanged;

@end

//
// 書き込みのテキスト編集ViewController (新規スレッドも担当)
@interface PostEditVC : UIViewController <UITextViewDelegate> {
}

@property (nonatomic, copy) NSString *
    initialBodyText;

@property (nonatomic, copy) NSString *
    initialThreadTitle;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameBottomBorderHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *threadTitleContainerHeightConstraint;
@property (nonatomic) PostNaviVC *postNaviVC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mailBottomBorderHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *nameBottomBorder;
@property (weak, nonatomic) IBOutlet UIView *mailBottomBorder;
@property (weak, nonatomic) IBOutlet UIView *threadTitleBottomBorder;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *threadTitleBottomBorderHeightConstraint;
- (IBAction)backInToolbar:(id)sender;

- (IBAction)postButtonTapAction:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameTopBorderHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *toolbarTopBorder;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarTopBorderHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *bottomToolbar;
@property (weak, nonatomic) IBOutlet UIView *nameTopBorderView;
- (IBAction)moveRightButtonAction:(id)sender;
- (IBAction)onAccountButtonAction:(id)sender;

- (IBAction)moveLeftButtonAction:(id)sender;
- (void)clearBodyText;
- (void)addText:(NSString *)text;

@property (weak, nonatomic) IBOutlet UIButton *accountButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
- (IBAction)onMoreAction:(id)sender;

@end
