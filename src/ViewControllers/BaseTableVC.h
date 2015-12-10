//
//  BaseTableViewController.h
//  Forest
//

#import <UIKit/UIKit.h>

// よく使うTableViewをテーマに対応させて、共通化する
@interface BaseTableVC : UITableViewController

@property (nonatomic) NSObject *selectedItem;

@property (nonatomic, copy) NSArray *itemArray;

@property (nonatomic) UIColor *overrideTableViewCellBackgroundColor;
@property (nonatomic) UIColor *desiredSectionBackgroundColor;
@property (nonatomic) UIColor *desiredTableViewBackgroundColor;

@end
