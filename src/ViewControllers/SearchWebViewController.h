//
//  SearchWebViewController.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "DynamicBaseVC.h"

@interface SearchWebViewController : DynamicBaseVC <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *border;
@property (weak, nonatomic) IBOutlet UIView *webViewContainer;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIView *topBorder;
@property (nonatomic, copy) NSString *searchUrl;

- (IBAction)backAction:(id)sender;
- (IBAction)backBrowseAction:(id)sender;
- (IBAction)refreshAction:(id)sender;
- (IBAction)forwardAction:(id)sender;

@end
