//
//  MyNavigationViewController.m
//  Forest
//

#import "MyNavigationVC.h"
#import "ThemeManager.h"
#import "ResVC.h"
#import "Transaction.h"
#import "AppDelegate.h"
#import "UIView+NSObjectProperty.h"
#import "PostNaviVC.h"
#import "Views.h"
#import "MySplitVC.h"

static MyNavigationVC *_instance;

NSInteger getRetainCount(__strong id obj) {

    return CFGetRetainCount((__bridge CFTypeRef)obj); 
} 


@interface ResVCCache : NSObject

@property (nonatomic) NSMutableSet *cachedResVCSet;

@end

@implementation ResVCCache 

- (id) init {
    if (self = [super init]) {
        _cachedResVCSet = [NSMutableSet set];
    }

    return self;
}


static const NSInteger kMaxCachedResVC = 2;

- (ResVC *)dequeueReusableResViewController:(DynamicBaseVC *)usedHeadVC
{
    return [self dequeueReusableResViewController:usedHeadVC canUseUsed:YES];
}

- (ResVC *)dequeueReusableResViewController:(DynamicBaseVC *)usedHeadVC canUseUsed:(BOOL)canUseUsed
{
    @synchronized(self.cachedResVCSet)
    {
        NSSet *oldsSet = [NSSet setWithSet:self.cachedResVCSet];
        //追加
        DynamicBaseVC *nextVC = usedHeadVC;
        if (nextVC) {
            if ([nextVC isKindOfClass:[ResVC class]]) {
                ResVC *resVC = (ResVC *)nextVC;

                if ([self.cachedResVCSet count] < kMaxCachedResVC) {
                    [self.cachedResVCSet addObject:resVC];
                
                }
                
                [resVC detach];
            }

            DynamicBaseVC* tempVC = nextVC;
            nextVC = nextVC.nextViewController;
            tempVC.nextViewController = nil;
        }

        if ([self.cachedResVCSet count] > 0) {
            for (ResVC *resVC in self.cachedResVCSet) {
                if (canUseUsed == NO && ![oldsSet containsObject:resVC]) {
                    continue;
                }
                [self.cachedResVCSet removeObject:resVC];

               return resVC;
            }
        }

        ResVC *resViewController = [[ResVC alloc] init];

        return resViewController;
    }
}



@end

@interface MyNavigationVC ()


@property (nonatomic) ResVCCache *resVCCache;


@end



@implementation MyNavigationVC

+ (MyNavigationVC *)instance
{
    return _instance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    _instance = self;
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
  
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)updateViewConstraints
{
    [super updateViewConstraints];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void)viewDidLoad
{
    _instance = self;
    self.resVCCache = [[ResVCCache alloc] init];
    
    [super viewDidLoad];
}

- (void)didChangedOrientation:(NSNotification *)notification
{

}


#pragma mark - Res

- (void)popMyViewController
{
    [self popViewControllerAnimated:YES];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    return [self popViewControllerAnimated:animated canRetry:YES];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated canRetry:(BOOL)canRetry
{
    if ([self canNavigate:nil] == NO) {
        if (canRetry) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
              [NSThread sleepForTimeInterval:0.27];
              dispatch_async(dispatch_get_main_queue(), ^{
                [self popViewControllerAnimated:animated canRetry:NO];
              });
            });
        }

        return nil;
    }

    return [super popViewControllerAnimated:animated];
}

- (void)pushNexViewController
{
    DynamicBaseVC *dynaVC = nil;
    if ([self.topViewController isKindOfClass:[DynamicBaseVC class]]) {
        dynaVC = (DynamicBaseVC *)self.topViewController;
        dynaVC = dynaVC.nextViewController;
    } else if (self.firstDynamicVC) {
        dynaVC = self.firstDynamicVC;
    }

    if (dynaVC) {
        [self pushMyViewController:dynaVC];
    }
}

- (void)pushMyViewController:(DynamicBaseVC *)nextViewController
{
    [self pushMyViewController:nextViewController canRetry:YES withTransaction:nil];
}

- (void)pushMyViewController:(DynamicBaseVC *)nextViewController withTransaction:(Transaction *)exceptTransaction
{
    [self pushMyViewController:nextViewController canRetry:YES withTransaction:exceptTransaction];
}

- (void)pushMyViewController:(DynamicBaseVC *)nextViewController canRetry:(BOOL)canRetry withTransaction:(Transaction *)exceptTransaction
{
    if ([self canNavigate:exceptTransaction] == NO) {
        if (canRetry) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
              [NSThread sleepForTimeInterval:0.27];
              dispatch_async(dispatch_get_main_queue(), ^{
                [self pushMyViewController:nextViewController canRetry:NO withTransaction:exceptTransaction];
              });
            });
        }
        return;
    }
    
    

    if (self.topViewController != nextViewController) {
        if ([self.topViewController isKindOfClass:[DynamicBaseVC class]]) {
          
            DynamicBaseVC *currentViewController = (DynamicBaseVC *)self.topViewController;
            currentViewController.nextViewController = nextViewController;
        } else {
          
            self.firstDynamicVC = nextViewController;
        }
        

        [self pushViewController:nextViewController animated:YES];
    }

}

- (void)pushResViewControllerWithTh:(Th *)th
{
    [self pushResViewControllerWithTh:th withTransaction:nil];
}

- (BOOL)containsResVCForTh:(Th*)th {
    @synchronized(self.transactions) {
        for (Transaction * transaction in self.transactions) {
            if ([transaction isKindOfClass:[ResTransaction class]]) {
                ResTransaction *resTransaction = (ResTransaction *)transaction;
                if (resTransaction.th == th) {
                    return YES;
                }
            }
        }
    }

    
    if ([MySplitVC instance].isTabletMode) {
        for (UIViewController *vc in self.viewControllers) {
            for (UIViewController *vc2 in vc.childViewControllers) {
                if ([vc2 isKindOfClass:[ResVC class]]) {
                    ResVC *resVC = (ResVC *)vc2;
                    if (resVC.th == th) {
                        return YES;
                    }
                }
            }
        }
    }

    if ([self.firstDynamicVC isKindOfClass:[ResVC class]]) {
        if (((ResVC *) self.firstDynamicVC).th == th) {
            return YES;
        }
    }
    
    for (UIViewController *vc in self.viewControllers) {
        if ([vc isKindOfClass:[DynamicBaseVC class]]) {
            DynamicBaseVC *dynVC = (DynamicBaseVC *)vc;
            while (dynVC) {
                
                if ([dynVC isKindOfClass:[ResVC class]]) {
                    ResVC *resVC = (ResVC *)dynVC;
                    if (resVC.th == th) {
                        return YES;
                    }
                }
                
                dynVC = dynVC.nextViewController;
            }
        }
    }

    return NO;
}


- (void)pushResViewControllerWithTh:(Th *)th withTransaction:(Transaction *)exceptTransaction
{
    if ([self canNavigate:exceptTransaction] == NO) return;
    
    

    if ([MySplitVC instance].isTabletMode) {
        DynamicBaseVC *usedVC =  nil;
        if ([self.topViewController isKindOfClass:[DynamicBaseVC class]]) {
            usedVC = ((DynamicBaseVC *)self.topViewController);
            if ([usedVC isKindOfClass:[ResVC class]]) {
                if (((ResVC *)usedVC).th == th) {
                    [self closeTransaction:exceptTransaction];
                    return;
                }
            }
        }


        ResVC *resVC = [self.resVCCache dequeueReusableResViewController:usedVC canUseUsed:NO];
        [resVC loadThread:th complete:^{ }];
        
        

        if (self.tabletContentVC == nil) {
            self.tabletContentVC = [[UIViewController alloc] init];
            

            [self.tabletContentVC addChildViewController:resVC];
            resVC.view.translatesAutoresizingMaskIntoConstraints = NO;
            [self.tabletContentVC.view addSubview:resVC.view];
            [Views _constraintParentFit:resVC.view withParentView:self.tabletContentVC.view];
            [self setViewControllers: @[self.tabletContentVC] animated: NO];

            [self.view setNeedsDisplay];
            [self updateViewConstraints];
        } else {
            [self __showViewControllerInTabletMode:resVC closeTransaction:exceptTransaction];
        }

    } else {
        DynamicBaseVC *usedVC =  nil;
        if ([self.topViewController isKindOfClass:[DynamicBaseVC class]]) {
            usedVC = ((DynamicBaseVC *)self.topViewController).nextViewController;
        } else if (self.firstDynamicVC) {
            usedVC = self.firstDynamicVC;
        }

        ResVC *resViewController = [self.resVCCache dequeueReusableResViewController:usedVC];
        [resViewController loadThread:th complete:^{ }];

        if (self.topViewController != resViewController) {
            [self pushMyViewController:resViewController withTransaction:exceptTransaction];
        }
    }
}

- (void) __showViewControllerInTabletMode:(UIViewController*)nextTabVC closeTransaction:(Transaction *)transaction
{
    UIViewController *currentVC = [self.tabletContentVC.childViewControllers objectAtIndex:0];
    if ([currentVC isKindOfClass:[ResVC class]]) {
        [((ResVC *)currentVC) callViewWillDisappear];
    }

    if (currentVC && nextTabVC != currentVC) {
        [self.tabletContentVC addChildViewController:nextTabVC];
        
        [self.tabletContentVC.view addSubview:nextTabVC.view];
        //[nextTabVC didMoveToParentViewController:self.tabletContentVC];
        
        [currentVC removeFromParentViewController];
        [currentVC.view removeFromSuperview];
        
        [Views _constraintParentFit:nextTabVC.view withParentView:self.tabletContentVC.view];
    }

    [self closeTransaction: transaction];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (BOOL)shouldAutorotate
{
    return YES;
}

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
