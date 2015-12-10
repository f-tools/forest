//
//  FastTableView.h
//  Forest
//

#import <UIKit/UIKit.h>

@interface FastViewModelBase : NSObject

@property (nonatomic) CGFloat cellHeight;
@property (nonatomic) NSInteger statusIndex;
@property (nonatomic) CGFloat priorCellWidth;

- (CGFloat)calcHeight;

//@virtual
- (void)regenAttributedStrings;

@end


@class FastTableView;



@protocol FastTableViewDataSource <UITableViewDataSource>

@optional

@required
- (FastViewModelBase *)tableView:(FastTableView *)tableView vmAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol FastTableViewDelegate <UITableViewDelegate>

@end

@interface FastTableView : UITableView <UITableViewDelegate, UITableViewDataSource> {


}

@property (nonatomic, weak) id<FastTableViewDataSource> clientDataSource;
@property (nonatomic, weak) id<FastTableViewDelegate> clientDelegate;


@property (nonatomic) NSInteger statusIndex;
@property (nonatomic) BOOL stability;

- (void)initFastTableView;
- (void)reloadTableViewAtIndexPath:(NSIndexPath *)indexPath
                        withOffset:(NSUInteger)offset
                        completion:(void (^)())completion;

- (void)startBackgroundParse;
- (void)scrollsToTop;
- (void)scrollsToBottom;
- (void)reloadForRedraw;

@end
