//
//  ImageUploadVC.m
//  Forest
//

#import "CTAssetsPickerController.h"
#import "ImageUploadVC.h"
#import "ImageUploadManager.h"
#import "BaseModalNavigationVC.h"
#import "ThemeManager.h"
#import <SDWebImage/SDWebImageManager.h>
#include <stdlib.h>

@interface ImageUploadVC ()
@property (nonatomic) NSMutableArray *historyImageList;
@property (nonatomic) NSMutableDictionary *cacheImageDict;
@property (nonatomic, copy) NSArray *prevUploadEntries;

@end

@implementation ImageUploadVC


- (void)backPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.title = @"画像アップロード";

    self.cacheImageDict = [NSMutableDictionary dictionary]; // sdWebImageUrl -> UIImage

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.historyImageList = [[ImageUploadManager sharedManager] historyEntries];

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"戻る"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(backPressed:)];
    self.navigationItem.leftBarButtonItem = backButton;

    [self.insertButton setAction:@selector(onInsertButton:)];
    [self.cloneButton setAction:@selector(onCopiiButton:)];
    [self.deleteButton setAction:@selector(onDeleteButton:)];

    [self setToolButtonsEnabled:NO];

    self.view.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
    [self.tableView setBackgroundColor:[[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor]];
    [self.selectImageButton setBackgroundColor:[[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor]];

    [self.tableView setSeparatorColor:[[ThemeManager sharedManager] colorForKey:ThemeTableSeparatorColor]];
    self.toolbar.barStyle = [[ThemeManager sharedManager] barStyle];

    [self setEditing:YES animated:NO];
}

- (void)setToolButtonsEnabled:(BOOL)enabled
{
    [self.insertButton setEnabled:enabled];
    [self.cloneButton setEnabled:enabled];
    [self.deleteButton setEnabled:enabled];
}

// The editButtonItem will invoke this method.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:YES];
}

- (IBAction)onInsertButton:(id)sender
{
    NSArray *indexPathes = [self.tableView indexPathsForSelectedRows];
    NSMutableString *text = [NSMutableString string];
    for (NSIndexPath *indexPath in indexPathes) {
        ImageUploadEntry *entry = [self.historyImageList objectAtIndex:indexPath.row];
        [text appendString:entry.webUrl];
        [text appendString:@"\n"];
    }

    [self.navigationController dismissViewControllerAnimated:YES
                                                  completion:^{
                                                    if (self.onAddedText) {
                                                        self.onAddedText(text);
                                                        self.onAddedText = nil;
                                                    }
                                                  }];
}

- (IBAction)onCopiiButton:(id)sender
{
    //[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onDeleteButton:(id)sender
{
    // 複数行で書くタイプ（複数ボタンタイプ）
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.delegate = self;
    alert.title = @"確認";
    alert.message = @"アップローダから削除しますか？";
    [alert addButtonWithTitle:@"キャンセル"];
    [alert addButtonWithTitle:@"削除"];
    [alert show];
}

// アラートのボタンが押された時に呼ばれるデリゲート例文
- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex
{

    switch (buttonIndex) {
    case 0:
        //Cancel
        break;
    case 1: {
        //削除
        self.prevUploadEntries = nil;
        NSArray *indexPathes = [self.tableView indexPathsForSelectedRows];

        for (NSIndexPath *indexPath in indexPathes) {
            ImageUploadEntry *entry = [self.historyImageList objectAtIndex:indexPath.row];
            [[ImageUploadManager sharedManager] deleteImage:entry
                                                 completion:^(BOOL success) {
                                                   dispatch_sync(dispatch_get_main_queue(), ^{
                                                     [self reloadDataWithSelectionSaved:nil];
                                                   });
                                                 }];
        }

    } break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    //row 0 : ライブラリから選択してアップロード
    //row 1 : 写真を撮って追加してアップロード
    //それ以外は過去にアップロードした写真のリスト
    return YES; //indexPath.row != 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"アップロード済み画像";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.historyImageList == nil ? 0 : [self.historyImageList count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ng_cell"];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"ng_cell"];
        cell.textLabel.textColor = [[ThemeManager sharedManager] colorForKey:ThemeNormalColor];
        cell.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];
        cell.textLabel.backgroundColor = [[ThemeManager sharedManager] colorForKey:ThemeMainBackgroundColor];

        UIView *selectedBackgroundViewForCell = [UIView new];
        [selectedBackgroundViewForCell setBackgroundColor:[[ThemeManager sharedManager] colorForKey:ThemeTableSelectedBackgroundColor]];
        cell.selectedBackgroundView = selectedBackgroundViewForCell;
    }

    ImageUploadEntry *entry = [self.historyImageList objectAtIndex:indexPath.row];
    cell.textLabel.text = entry.webUrl;
    cell.tag = arc4random_uniform(740000000);

    UIImage *cacheImage = [self.cacheImageDict objectForKey:entry.sdWebImageUrl];
    if (cacheImage) {
        cell.imageView.image = cacheImage;
    } else {
        cell.imageView.image = nil;
        if (entry.sdWebImageUrl || entry.webUrl) {
            [self fetchImage:entry fromWeb:NO];
        }
    }

    if (entry.uploadedTime > 0) {

        NSDate *date = [NSDate dateWithTimeIntervalSince1970:entry.uploadedTime];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

        //  NSDateComponents comps = [NSDateComponents alloc]

        [formatter setDateFormat:@"yyyy年M月d日 H:mm"];
        NSString *date_string = [formatter stringFromDate:date];

        cell.detailTextLabel.text = date_string;
    } else {
        cell.detailTextLabel.text = @"";
    }

    cell.textLabel.text = entry.imageKey ? entry.imageKey : @"アップロード中です";

    return cell;
}

- (IBAction)selectImageACtion:(id)sender
{
    [self startSelectImages];
}

- (void)startSelectImages
{
    // ライブラリから選択してアップロード
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.delegate = self;

    [self.navigationController presentViewController:picker
                                            animated:YES
                                          completion:^{
                                            if ([picker.childNavigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
                                                picker.childNavigationController.interactivePopGestureRecognizer.delegate = nil;
                                            }
                                          }];
}

- (void)fetchImage:(ImageUploadEntry *)entry fromWeb:(BOOL)fromWeb
{
    //画像の取得
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    NSString *urlString = fromWeb ? entry.webUrl : entry.sdWebImageUrl;
    if (urlString == nil) {
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    [manager downloadImageWithURL:url
        options:SDWebImageRetryFailed
        progress:^(NSInteger receivedSize, NSInteger expectedSize) {
          //                                 if (asset.progress) {
          //                                     asset.progress(asset, receivedSize, expectedSize);
          //                                 }

        }
        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
          if (image) {
              NSLog(@"1");
              if (fromWeb) {
                  NSLog(@"2");
                  [[SDImageCache sharedImageCache] storeImage:image forKey:entry.sdWebImageUrl];
              }

              // 上限超えたら一つ消す
              if ([self.cacheImageDict count] > 20) {
                  id key = [[self.cacheImageDict allKeys] objectAtIndex:0];
                  [self.cacheImageDict removeObjectForKey:key];
              }
              [self.cacheImageDict setObject:image forKey:entry.sdWebImageUrl];

              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                  NSArray *indexPathList = [self.tableView indexPathsForVisibleRows];

                  for (NSIndexPath *path in indexPathList) {
                      ImageUploadEntry *visibleEntry = [self.historyImageList objectAtIndex:path.row];
                      if (entry == visibleEntry) {

                          BOOL selected = [[self.tableView indexPathsForSelectedRows] containsObject:path];
                          [self.tableView reloadRowsAtIndexPaths:@[ path ] withRowAnimation:UITableViewRowAnimationNone];

                          if (selected) {
                              [self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
                              [self setToolButtonsEnabled:YES];
                          }

                          break;
                      }
                  }

                });
              });
          } else {
              NSLog(@"4");
              if (fromWeb == NO) {
                  NSLog(@"5");
                  [self fetchImage:entry fromWeb:YES];
              }
          }

        }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{

    NSMutableArray *requests = [NSMutableArray array];
    for (ALAsset *alAsset in assets) {
        //すべてアップロード
        ImageUploadEntry *entry = [[ImageUploadEntry alloc] init];
        entry.asset = alAsset;
        entry.completion = ^(ImageUploadEntry *uploadEntry) {
          uploadEntry.completion = nil;
          [self onUploadCompleted:uploadEntry];
        };
        [requests addObject:entry];
    }

    self.prevUploadEntries = requests;

    [picker dismissViewControllerAnimated:YES
                               completion:^{
                                 [[ImageUploadManager sharedManager] addRequests:requests];
                                 //[self reloadDataWithSelectionSaved:nil];
                               }];
}

- (void)reloadDataWithSelectionSaved:(ImageUploadEntry *)focusEntry
{

    NSArray *indexPathes = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *selectedEntries = [NSMutableArray array];
    for (NSIndexPath *path in indexPathes) {
        ImageUploadEntry *ent = [self.historyImageList objectAtIndex:path.row];
        [selectedEntries addObject:ent.webUrl];
    }

    self.historyImageList = [[ImageUploadManager sharedManager] historyEntries];
    [self.tableView reloadData];

    if (self.prevUploadEntries) {
        //アップロードしたのを選択状態にしておく。
        for (int i = 0; i < [self.historyImageList count]; i++) {
            ImageUploadEntry *refEntry = [self.historyImageList objectAtIndex:i];

            if ([selectedEntries containsObject:refEntry.webUrl]) {
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
                [self setToolButtonsEnabled:YES];
                continue;
            }

            for (ImageUploadEntry *requestEntry in self.prevUploadEntries) {
                if ([refEntry.webUrl isEqualToString:requestEntry.webUrl]) {
                    NSLog(@"equeal request entry");
                    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:focusEntry == refEntry ? UITableViewScrollPositionTop : UITableViewScrollPositionNone];
                    [self setToolButtonsEnabled:YES];
                    break;
                }
            }
        }
    }
}

- (void)onUploadCompleted:(ImageUploadEntry *)entry
{

    [self reloadDataWithSelectionSaved:entry];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *indexPathes = [self.tableView indexPathsForSelectedRows];
    if ([indexPathes count] < 1) {
        [self setToolButtonsEnabled:NO];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing) {
        //return;
    }

    [self setToolButtonsEnabled:YES];

}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
