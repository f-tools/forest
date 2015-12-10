//
//  FavSelectFragment.m
//  Forest
//

#import "FavSelectFragment.h"
#import "LineBreakNode.h"

#import <QuartzCore/QuartzCore.h>
#import "DatParser.h"
#import "ResTableViewCell.h"
#import "TextUtils.h"
#import "ThUpdater.h"
#import "ResVmList.h"
#import "Th+ParseAdditions.h"
#import "AppDelegate.h"
#import "ThemeManager.h"
#import "ThManager.h"
#import "HistoryVC.h"
#import "FavVC.h"
#import "GestureManager.h"
#import "GestureEntry.h"
#import "TopWindow.h"
#import "ResNodeBase.h"
#import "Env.h"
#import "BaseModalNavigationVC.h"
#import "BaseTableVC.h"
#import "ResTransaction.h"
#import "ThListTransaction.h"
#import "MySplitVC.h"

@interface FavFolderSelectVC : BaseTableVC

@property (nonatomic) FavFolder *currentFavFolder;
@property (nonatomic) FavSelectFragment *callerFavSelectFragment;

@property (nonatomic) Th *targetTh;
@property (nonatomic, copy) NSArray *favFolders;

@end

@implementation FavFolderSelectVC

- (void)viewDidLoad
{

    FavVC *favVC = [FavVC sharedInstance];
    self.favFolders = favVC.favFolders;
    self.itemArray = self.favFolders;

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"戻る"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(backPressed:)];

    self.navigationItem.leftBarButtonItem = backButton;

    [super viewDidLoad];
}

- (void)backPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"お気に入りフォルダ一覧";
}

- (NSString *)itemTitle:(NSObject *)item
{
    FavFolder *favFolder = (FavFolder *)item;
    return favFolder.name;
}

- (void)didSelectAtItem:(NSObject *)item
{
    FavFolder *favFolder = (FavFolder *)item;
    [self.navigationController dismissViewControllerAnimated:YES
                                                  completion:^{
                                                    [self.callerFavSelectFragment changeFavFolder:favFolder];

                                                  }];

}

@end

@interface FavSelectFragment ()

@property (nonatomic) UIButton *targetFavFolderButton;
@property (nonatomic) UIButton *favCheckedImageButton;

@end

@implementation FavSelectFragment

- (id)init
{
    if (self = [super init]) {
        UINib *nib = [UINib nibWithNibName:@"FavSelectFragment" bundle:[NSBundle mainBundle]];
        NSArray *array = [nib instantiateWithOwner:self options:nil];

        UIView *view = [array objectAtIndex:0];

        self.targetFavFolderButton = (UIButton *)[view viewWithTag:1];
        self.favCheckedImageButton = (UIButton *)[view viewWithTag:2];

        UIImage *image = [UIImage imageNamed:@"star_gray_30.png"];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

        [self.favCheckedImageButton setImage:image forState:UIControlStateNormal];
        [self.favCheckedImageButton addTarget:self action:@selector(favFolderImageTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [self.targetFavFolderButton addTarget:self action:@selector(favFolderButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

        [nc addObserver:self
               selector:@selector(onThemeChanged:)
                   name:@"themeChanged"
                 object:nil];

        [self changeTheme];

        self.view = view;
    }
    return self;
}

// 通知と値を受けるonThemeChangedメソッド
- (void)onThemeChanged:(NSNotification *)center
{
    [self changeTheme];
}

- (void)changeTheme
{
    [self.targetFavFolderButton setTitleColor:[[ThemeManager sharedManager] colorForKey:ThemeNormalColor] forState:UIControlStateNormal];
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self
                  name:@"themeChanged"
                object:nil];
}

- (void)onLayoutCompleted
{
    UIView *superView = self.view.superview;
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.view
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0
                                      constant:29]
    ]];
    [superView addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.view
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:superView
                                     attribute:NSLayoutAttributeLeft
                                    multiplier:1.0
                                      constant:0],
        [NSLayoutConstraint constraintWithItem:self.view

                                     attribute:NSLayoutAttributeRight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:superView
                                     attribute:NSLayoutAttributeRight
                                    multiplier:1.0
                                      constant:0]
    ]];

    [self initFolderInfo];
}

- (void)changeTh:(Th *)th
{
    self.th = th;
    [self initFolderInfo];
}

- (void)initFolderInfo
{
    FavVC *favVC = [FavVC sharedInstance];

    NSArray *folderList = [favVC folderListForTh:self.th];
    if (folderList && [folderList count] > 0) {
        FavFolder *firstFolder = [folderList objectAtIndex:0];
        self.targetFavFolder = firstFolder;
    }

    [self updateFavFolderInfo];
}

- (IBAction)favFolderImageTouchUpInside:(id)sender
{
    FavVC *favVC = [FavVC sharedInstance];

    if (self.targetFavFolder == nil) {
        self.targetFavFolder = [favVC.favFolders objectAtIndex:0];
    }

    if (favVC && [favVC containsThread:self.th forFolder:self.targetFavFolder]) {
        //削除処理
        [favVC removeThread:self.th forFolder:self.targetFavFolder];
    } else {
        //追加処理
        [favVC addThread:self.th forFolder:self.targetFavFolder];
    }

    [self updateFavFolderInfo];
}

- (IBAction)favFolderButtonTouchUpInside:(id)sender
{

    BaseModalNavigationVC *navCon = [[BaseModalNavigationVC alloc] init];

    FavFolderSelectVC *favEditCon = [[FavFolderSelectVC alloc] init];
    favEditCon.callerFavSelectFragment = self;

    [navCon pushViewController:favEditCon animated:YES];

    [[MySplitVC instance] presentViewController:navCon
                                            animated:YES
                                          completion:^{ }
    ];
}

- (IBAction)favFolderButton:(id)sender
{
}


- (void)updateFavFolderInfo
{
    FavVC *favVC = [FavVC sharedInstance];

    if (self.targetFavFolder == nil) {
        self.targetFavFolder = [favVC.favFolders objectAtIndex:0];
    }

    [self.targetFavFolderButton setTitle:self.targetFavFolder.name forState:UIControlStateNormal];
    [self.targetFavFolderButton setTitle:self.targetFavFolder.name forState:UIControlStateHighlighted];
    [self.targetFavFolderButton setTitle:self.targetFavFolder.name forState:UIControlStateSelected];
    [self.targetFavFolderButton setTitle:self.targetFavFolder.name forState:UIControlStateReserved];
    [self.targetFavFolderButton.titleLabel setNeedsDisplay];

    UIImage *image = nil;
    if ([favVC containsThread:self.th forFolder:self.targetFavFolder]) {
        image = [UIImage imageNamed:@"star_blue_30.png"];
    } else {
        image = [UIImage imageNamed:@"star_gray_30.png"];
    }
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.favCheckedImageButton setImage:image forState:UIControlStateNormal];
}

- (void)changeFavFolder:(FavFolder *)favFolder
{
    self.targetFavFolder = favFolder;
    [self updateFavFolderInfo];
}

@end
