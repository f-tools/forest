#import <Foundation/Foundation.h>
#import "Board.h"
#import "Th.h"
#import "Category.h"

@interface CookieManager : NSObject

+ (CookieManager *)sharedManager;

- (id)init;

- (NSString *)cookieForServer:(NSString *)server;
- (void)setCookie:(NSString *)fieldValue forServer:(NSString *)server;
- (void)deleteAllCookie;
- (BOOL)hasBECookie;
- (void)removeBECookie;

@end
