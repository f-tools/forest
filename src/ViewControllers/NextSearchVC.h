//
//  NextSearchVC.h
//  Forest
//

#import "ThListBaseVC.h"
#import "BaseModalNavigationVC.h"

@class Th;

@interface NextSearchNaviVC : BaseModalNavigationVC

@property (nonatomic, copy) NSArray *thList;
@property (nonatomic) Th *th;

@end



@interface NextSearchVC : ThListBaseVC

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, copy) NSArray *thList;
@property (nonatomic) Th *th;

- (IBAction)backButtonAction:(id)sender;

@end
