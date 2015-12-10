//
//  Transaction.m
//  Forest
//

#import "Transaction.h"

@implementation Transaction

+ (id)navigationTransaction
{
    Transaction *transaction = [[self alloc] init];
    transaction.isNavigationTransaction = YES;

    return transaction;
}

+ (id)progressTransaction
{
    Transaction *transaction = [[self alloc] init];
    return transaction;
}

- (void)dealloc
{
    self.delegate = nil;
}

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

// Transaction -> Delegate
- (void)changeProgress:(CGFloat)progress
{
    if (self.delegate) {
        [self.delegate progressChanged:self withProgress:progress];
    }
}

// Transaction -> Delegate
- (void)changeTitle:(NSString *)progress
{
    self.title = progress;
    if (self.delegate) {
        [self.delegate titleChanged:self];
    }
}

// Delegate -> Transaction
- (void)performCancel
{
    [self didCancel:self];
}

@end
