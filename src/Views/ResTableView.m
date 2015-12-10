//
//  ResTableView.m
//  Forest
//

#import "ResTableView.h"
#import "GestureManager.h"

@interface ResTableView ()


@property (nonatomic) GestureManager *gesture;

@end

@implementation ResTableView

- (id)init
{
    self = [super init];
    if (self) {
        // _gesture = [[GestureManager alloc] init];
    }
    return self;
}

@end
