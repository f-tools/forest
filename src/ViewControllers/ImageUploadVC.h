//
//  ImageUploadVC.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "CTAssetsPickerController.h"
@interface ImageUploadVC : UIViewController <UITableViewDataSource, UITableViewDelegate, CTAssetsPickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *insertButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cloneButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *webDeleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *selectImageButton;
@property (copy, nonatomic) void (^onAddedText)(NSString *text);

- (IBAction)selectImageACtion:(id)sender;

@end
