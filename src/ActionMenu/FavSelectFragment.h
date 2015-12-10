//
//  FavSelectFragment.h
//  Forest
//

#import <Foundation/Foundation.h>
#import "FavVC.h"
#import "Th.h"

/* お気に入り選択用の共通部品 */

@interface FavSelectFragment : NSObject

@property (nonatomic, weak) UIView *view;

@property (nonatomic) FavFolder *targetFavFolder;
@property (nonatomic) Th *th;

- (void)onLayoutCompleted;
- (void)changeFavFolder:(FavFolder *)favFolder;
- (void)changeTh:(Th *)th;

@end
