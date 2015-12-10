//
//  NGListVC.m
//  Forest
//

#import "NGListVC.h"
#import "NGManager.h"
#import "ThemeManager.h"
#import "BoardVC.h"
#import "NGItemEditVC.h"

@implementation NGListNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"戻る"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(backPressed:)];

    NGListVC *ngListVC = [[NGListVC alloc] initWithNibName:@"NGListVC" bundle:nil];

    ngListVC.navigationItem.leftBarButtonItem = backButton;

    [self pushViewController:ngListVC animated:YES];
}

- (void)backPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

@interface NGListVC ()

@property (nonatomic, copy) NSArray *ngItemList;
@property (nonatomic) NSInteger currentType; // 0: ID 1: word
@end

@implementation NGListVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"NG管理";

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    UIBarButtonItem *newNGButton = [[UIBarButtonItem alloc] initWithTitle:@"追加"
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(addNew:)];

    self.navigationItem.rightBarButtonItem = newNGButton;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];
    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    [self.tableView setBackgroundColor:[[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor]];

    [self.tableView setSeparatorColor:[[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor]];
    self.toolbar.barStyle = [[ThemeManager sharedManager] barStyle];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.currentType == 0) {
        [self idButtonAction:nil];
    } else if (self.currentType == 1) {
        [self wordToolButtonAction:nil];
    } else if (self.currentType == 2) {
        [self threadToolButtonAction:nil];
    } else if (self.currentType == 3) {
        [self nameToolButtonAction:nil];
    }
}

- (void)addNew:(id)sender
{
    NGItemEditVC *ngItemEditVC = [[NGItemEditVC alloc] initWithNibName:@"NGItemEditVC" bundle:nil];
    NGItem *ngItem = nil;
    if (self.currentType == 0) {
        ngItem = [NGItem ngIdItem];
    } else if (self.currentType == 1) {
        ngItem = [NGItem ngWordItem];
    } else if (self.currentType == 2) {
        ngItem = [NGItem ngThreadItem];
    } else if (self.currentType == 3) {
        ngItem = [NGItem ngNameItem];
    }
    ngItemEditVC.ngItem = ngItem;
    ngItemEditVC.initialMode = YES;
    //ngItem.board = [[BoardManager sharedManager] boardForTh:self.resVC.th];
    //
    [self.navigationController pushViewController:ngItemEditVC animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"NG一覧";
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.ngItemList == nil ? 0 : [self.ngItemList count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ng_cell"];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"ng_cell"];
        cell.textLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
        cell.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
        cell.textLabel.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

        UIView *selectedBackgroundViewForCell = [UIView new];
        [selectedBackgroundViewForCell setBackgroundColor:[[ThemeManager sharedManager] colorForKey:ThemeTableSelectedBackgroundColor]];
        cell.selectedBackgroundView = selectedBackgroundViewForCell;
    }

    NGItem *ngItem = [self.ngItemList objectAtIndex:indexPath.row];
    cell.textLabel.text = ngItem.value;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (tableView.isEditing) {
        //return;
    }

    // UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    NGItem *ngItem = [self.ngItemList objectAtIndex:indexPath.row];

    NGItemEditVC *ngItemEditVC = [[NGItemEditVC alloc] initWithNibName:@"NGItemEditVC" bundle:nil];
    //ngItem.board = [[BoardManager sharedManager] boardForTh:self.resVC.th];
    ngItemEditVC.ngItem = ngItem;

    [self.navigationController pushViewController:ngItemEditVC animated:YES];
}

- (void)changeSortButton:(UIBarButtonItem *)button
{
    NSArray *buttonArray = @[ self.idToolButton, self.wordToolButton, self.threadToolButton, self.nameToolButton ];

    for (UIBarButtonItem *b in buttonArray) {
        if (b == button) {
            b.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeAccentColor];
        } else {
            b.tintColor = [UIColor grayColor];
        }
    }
}

- (IBAction)idButtonAction:(id)sender
{
    self.currentType = 0;
    [self refreshTable];
    [self changeSortButton:self.idToolButton];
}

- (void)refreshTable
{
    if (self.currentType == 0) {
        self.ngItemList = [[NGManager sharedManager] idNGList];
    } else if (self.currentType == 1) {
        self.ngItemList = [[NGManager sharedManager] wordNGList];
    } else if (self.currentType == 2) {
        self.ngItemList = [[NGManager sharedManager] threadNGList];
    } else if (self.currentType == 3) {
        self.ngItemList = [[NGManager sharedManager] nameNGList];
    }

    [self.tableView reloadData];
}

- (IBAction)wordToolButtonAction:(id)sender
{
    self.currentType = 1;
    [self refreshTable];
    [self changeSortButton:self.wordToolButton];
}

- (IBAction)threadToolButtonAction:(id)sender
{
    self.currentType = 2;
    [self refreshTable];
    [self changeSortButton:self.threadToolButton];
}

- (IBAction)nameToolButtonAction:(id)sender
{
    self.currentType = 3;
    [self refreshTable];
    [self changeSortButton:self.nameToolButton];
}
@end
