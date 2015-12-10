//
//  ResTableViewCell.h
//  Forest
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "ResView.h"

@interface ResTableViewCell : UITableViewCell

@property (nonatomic) IBOutlet UIView *containerView;
@property (nonatomic) IBOutlet ResView *resView;

@end
