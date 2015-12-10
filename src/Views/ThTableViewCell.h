//
//  ThTableViewCell.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "ThTextView.h"

@interface ThTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet ThTextView *titleTextView;
@property (weak, nonatomic) IBOutlet ThTextView *speedTextView;
@property (weak, nonatomic) IBOutlet ThTextView *countTextView;
@property (weak, nonatomic) IBOutlet ThTextView *otherTextView;
@property (weak, nonatomic) IBOutlet ThTextView *newsCountTextView;
@property (weak, nonatomic) IBOutlet ThTextView *dateTextView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

- (void)maskCellFromTop:(CGFloat)margin;

@end
