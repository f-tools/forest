//
//  NextSearchVC.m
//  Forest
//

#import "NextSearchVC.h"
#import "MyNavigationVC.h"
#import "NextThreadSearcher.h"
#import "ThemeManager.h"
#import "MainVC.h"
#import "ThManager.h"
#import "Env.h"
#import "ThreadListParser.h"
#import "MyNavigationVC.h"
#import "ResVC.h"

#import "AppDelegate.h"
#import "ThTableViewCell.h"
#import "ThVm.h"
#import "FavVC.h"
#import "MySplitVC.h"


@interface NextSearchVC ()
@property (nonatomic) NSMutableArray *thVmList;

@end

@implementation NextSearchVC

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

    self.navigationController.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadListPageTintColor];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.title = @"次スレ選択";
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self createThVmList];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([MySplitVC instance].isTabletMode == NO) {
        [[MyNavigationVC instance] setNavigationBarHidden:NO animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadListPageTintColor];
}

- (void)createThVmList
{
    NextThreadSearcher *searcher = [[NextThreadSearcher alloc] init];
    NSArray *nextThreads = [searcher getNextThreads:self.th entries:self.thList];

    self.thVmList = [NSMutableArray array];
    for (Th *th in nextThreads) {
        ThVm *thVm = [[ThVm alloc] initWithTh:th]; //[self genThVm:newTh];

        [self.thVmList addObject:thVm];
    }
}

- (void)onThemeChanged
{
    [super onThemeChanged];

    self.view.tintColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadListPageTintColor];

    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorColor:[[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor]];

    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeUnderneathBackgroundColor];

    UIImage *backgroundImage = [[ThemeManager sharedManager] backgroundImageForKey:ThemeThreadListPageBackgroundImage];
    self.backgroundImageView.image = backgroundImage;
    self.backgroundImageView.contentMode = UIViewContentModeCenter;
    self.backgroundImageView.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeThreadListPageBackgroundColor];
}

- (void)onContextMenuTap
{
}

- (NSArray *)getThVmList
{
    return [NSArray arrayWithArray:self.thVmList];
}

- (BOOL)canUpdateAll
{
    return NO;
}

- (NSString *)getUpdateAllLabel
{
    return @"更新";
}

- (void)updateAll
{
}

- (UITableView *)thisTableView
{
    return self.tableView;
}

- (ThVm *)thVmForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThVm *thVm = [self.thVmList objectAtIndex:indexPath.row];
    return thVm;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.thVmList == nil ? 0 : [self.thVmList count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThVm *thVm = [self thVmForRowAtIndexPath:indexPath];

    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      [NSThread sleepForTimeInterval:0.2];
      dispatch_async(dispatch_get_main_queue(), ^{

        ResTransaction *resTransaction = [[ResTransaction alloc] init];

        FavVC *vc = [FavVC sharedInstance];
        [vc addNextThread:thVm.th base:self.th];

        resTransaction.th = thVm.th;
        if ([resTransaction startOpenThTransaction]) {
        }
      });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
