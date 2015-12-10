//
//  BaseTableViewController.m
//  Forest
//

#import "BaseTableVC.h"
#import "ThemeManager.h"
#import "AppDelegate.h"
#import "MyNavigationVC.h"

@interface BaseTableVC ()

@property (nonatomic) UITableViewCell *selectedCell;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *cellIdentifier;
@property (nonatomic) int cellIdentifierIndex;

@end

@implementation BaseTableVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    // 通知を解除する
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:@"themeChanged" object:nil]; //
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;

    self.cellIdentifierIndex = 1;
    self.cellIdentifier = [NSString stringWithFormat:@"%d", self.cellIdentifierIndex];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 35;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(onThemeChanged:) name:@"themeChanged" object:nil];
    [self applyTheme];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)applyTheme
{
    UIColor *backgroundColor = self.desiredTableViewBackgroundColor ? self.desiredTableViewBackgroundColor : [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

    self.tableView.backgroundColor = backgroundColor;
    self.tableView.separatorColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor];
    self.cellIdentifierIndex++;

    [self.tableView reloadData];
}

// 通知と値を受けるhogeメソッド
- (void)onThemeChanged:(NSNotification *)center
{
    [self applyTheme];
}

- (void)setSelectedFont:(UITableViewCell *)cell item:(NSObject *)item animated:(BOOL)animated
{
    if (item == self.selectedItem) {
        self.selectedCell = cell;
    }

    UIColor *color;
    UIFont *font;

    if (item == self.selectedItem) {
        color = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];
        font = [UIFont systemFontOfSize:15];

    } else {
        color = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
        font = [UIFont systemFontOfSize:15];
    }

    if (animated) {
        [UIView transitionWithView:cell.textLabel
                          duration:0.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                          cell.textLabel.font = font;
                          cell.textLabel.textColor = color;

                        }
                        completion:nil];

    } else {
        cell.textLabel.font = font;
        cell.textLabel.textColor = color;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:self.cellIdentifier];
    }

    if (cell.tag != self.cellIdentifierIndex) {
        UIView *selectedBackgroundViewForCell = [UIView new];
        selectedBackgroundViewForCell.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeTableSelectedBackgroundColor];
        cell.selectedBackgroundView = selectedBackgroundViewForCell;

        cell.tag = self.cellIdentifierIndex;
    }

    UIColor *cellBackgroundColor = self.overrideTableViewCellBackgroundColor ? self.overrideTableViewCellBackgroundColor : [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    cell.backgroundColor = cellBackgroundColor;

    NSObject *item = [self.itemArray objectAtIndex:indexPath.row];

    [self setSelectedFont:cell item:item animated:NO];

    cell.textLabel.text = [self itemTitle:item];

    return cell;
}

// @virtual
- (NSString *)itemTitle:(NSObject *)item
{
    return @"title";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.name;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.itemArray == nil ? 0 : [self.itemArray count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing) {
        //return;
    }

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    NSObject *prevSelectedItem = self.selectedItem;
    self.selectedItem = [self.itemArray objectAtIndex:indexPath.row];

    if (self.selectedCell) {
        [self setSelectedFont:self.selectedCell
                        item:prevSelectedItem
                     animated:YES];
    }

    [self setSelectedFont:cell item:self.selectedItem animated:YES];
    self.selectedCell = cell;

    [self didSelectAtItem:self.selectedItem];

    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

// @virtual
- (void)didSelectAtItem:(NSObject *)item
{
}

- (CGFloat)sectionHeight
{
    return 22;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self sectionHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSUInteger sectionHeight = [self sectionHeight];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, sectionHeight)];

    UIColor *foregroundColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
    UIColor *backgroundColor = self.desiredSectionBackgroundColor ? self.desiredSectionBackgroundColor : [[ThemeManager sharedManager] colorForKey:ThemeTableSectionBackgroundColor];
    headerView.backgroundColor = backgroundColor;

    int leftMargin = 15;
    //tableView.sectionHeaderHeight = headerView.frame.size.height;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, 0, headerView.frame.size.width - leftMargin, sectionHeight)];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.font = [UIFont boldSystemFontOfSize:12.5];
    //label.shadowOffset = CGSizeMake(0, 1);
    //label.shadowColor = [UIColor grayColor];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = foregroundColor;
    [headerView addSubview:label];

    return headerView;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
