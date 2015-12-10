#import "ResVC.h"
#import "ThemeManager.h"
#import "ThManager.h"
#import "AppDelegate.h"

#import "Env.h"
#import "UpdateAllTransaction.h"
#import "TabContextMenu.h"
#import <FMDatabase.h>
#import "ThListSectionVC.h"

@interface ThListSectionVC ()


@property (nonatomic) NSMutableSet *sectionSet;
@property (nonatomic) NSMutableArray *thVmList;

@end

@implementation ThListSectionVC

- (NSMutableArray *)sectionList
{
    return nil;
}

- (NSString *)sectionTitle:(NSObject *)sectionObject
{
    return nil;
}

- (NSMutableArray *)thVmListInSection:(NSObject *)sectionObject
{
    return nil;
}

- (CGFloat)sectionHeight
{
    return 22;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self sectionHeight];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)canEditing
{
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self sectionList] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSUInteger sectionHeight = [self sectionHeight];
    NSObject *sectionObj = [[self sectionList] objectAtIndex:section];
    NSString *sectionTitle = [self sectionTitle:sectionObj];

    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, sectionHeight)];

    UIColor *foregroundColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];
    UIColor *backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadSectionRowBackgroundColor];
    sectionView.backgroundColor = backgroundColor;

    int leftMargin = 0;
    tableView.sectionHeaderHeight = sectionView.frame.size.height;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, 0, sectionView.frame.size.width - leftMargin, sectionHeight)];
    label.text = [NSString stringWithFormat:@"     %@", sectionTitle];
    label.font = [UIFont boldSystemFontOfSize:12.5];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = foregroundColor;

    [sectionView addSubview:label];

    return sectionView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSObject *sectionObj = [[self sectionList] objectAtIndex:section];
    return [[self thVmListInSection:sectionObj] count];
}

@end
