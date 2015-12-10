//
//  ResView.h
//  Forest
//

#import <UIKit/UIKit.h>
#import "Res.h"
#import "ResVm.h"

@interface ThumbnailView : UIView

@property (weak, nonatomic) ResVm *resVm;

@end

@interface ResView : UIView

@property (weak, nonatomic) ResVm *resVm;

@property (nonatomic) ThumbnailView *thumbnailView;


- (void)onCellShown;
- (void)prepareForReuse;

- (ResNodeBase *)notifyLongTap:(UITouch *)touch;
- (ResNodeBase *)notifyTap:(UITouch *)touch;
- (ResNodeBase *)notifyTapEstablished:(UITouch *)touch;
- (void)notifyTapCancel:(UITouch *)touch;

@end
