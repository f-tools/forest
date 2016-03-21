//
//  SearchWebViewController.m
//  Forest
//



#import "SearchWebViewController.h"
#import "ResTransaction.h"
#import "Th.h"
#import "ThManager.h"
#import "AppDelegate.h"
#import "MyNavigationVC.h"
#import "Views.h"
#import "ThemeManager.h"
#import "BaseModalNavigationVC.h"
#import "Env.h"
#import "MySplitVC.h"

@interface SearchWebViewController ()

//@property (nonatomic) BOOL shouldDismiss;
@property (nonatomic) WKWebView *webView;

@end

@implementation SearchWebViewController

- (IBAction)backAction:(id)sender
{
    
    if ([self.navigationController.viewControllers count] > 1) {
        [self.navigationController popViewControllerAnimated:YES];

//      [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [super dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)backBrowseAction:(id)sender
{
    [self.webView goBack];
}

- (IBAction)refreshAction:(id)sender
{
    [self.webView reload];
}

- (IBAction)forwardAction:(id)sender
{
    [self.webView goForward];
}


- (id)init
{
    self = [super initWithNibName:@"SearchWebViewController" bundle:nil];

    if (self) {
    }

    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Webブラウザ";

    if ([MySplitVC instance].isTabletMode == NO) {
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
    }
    [Views makeSeparator:self.topBorder];
    [Views makeSeparator:self.border];
    UIColor *tabBackgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBackgroundColor];
    UIColor *tabBorderColor = [[ThemeManager sharedManager] colorForKey:ThemeTabBorderColor];

    self.border.backgroundColor = tabBorderColor;
    self.topBorder.backgroundColor = tabBorderColor;

    [self.toolbar setBackgroundImage:[UIImage new]
                  forToolbarPosition:UIBarPositionAny
                          barMetrics:UIBarMetricsDefault];

    [self.toolbar setShadowImage:[UIImage new] forToolbarPosition:UIToolbarPositionAny];

    self.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];
    self.toolbar.backgroundColor = tabBackgroundColor;
    self.automaticallyAdjustsScrollViewInsets = NO;

    // WKWebViewのインスタンス化
    CGRect rect = self.view.frame;
    WKWebView  *webView = [[WKWebView alloc] initWithFrame:rect];
    [self.webViewContainer addSubview:webView];

    webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView = webView;
    [self.webViewContainer addConstraints:@[

        [NSLayoutConstraint constraintWithItem:webView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.webViewContainer
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:0],

        [NSLayoutConstraint constraintWithItem:webView
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.webViewContainer
                                     attribute:NSLayoutAttributeLeft
                                    multiplier:1.0
                                      constant:0],

        [NSLayoutConstraint constraintWithItem:webView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.webViewContainer
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:0],

        [NSLayoutConstraint constraintWithItem:webView
                                     attribute:NSLayoutAttributeRight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.webViewContainer
                                     attribute:NSLayoutAttributeRight
                                    multiplier:1
                                      constant:0],
    ]];

    //webView.scalesPageToFit = YES;
    //webView.delegate = self;
    webView.navigationDelegate = self;
	webView.allowsBackForwardNavigationGestures = YES;


    NSURL *url = [NSURL URLWithString:self.searchUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([MySplitVC instance].isTabletMode == NO) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }
}

-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (self.presentedViewController){
        [super dismissViewControllerAnimated:flag completion:completion];
    }
}

- (void)webView:(WKWebView *)webView
 decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler
{
	//NSURLの取得
	NSURL *url = [webView URL];
	myLog(@"URL = %@", url);

	Th *th = [Th thFromUrl:[url absoluteString]];

	if (th) {
		th = [[ThManager sharedManager] registerTh:th];
		ResTransaction *man = [[ResTransaction alloc] init];
		man.th = th;
		if ([man startOpenThTransaction]) {
		}

		//キャンセル
		decisionHandler(WKNavigationActionPolicyCancel);
		return;
	}

	decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
