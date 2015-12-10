#import <Foundation/Foundation.h>
#import "Board.h"
#import "BoardManager.h"
#import "Th.h"
#import "Category.h"

@interface ThManager : NSObject

+ (ThManager *)sharedManager;

- (void)saveThAsync:(Th *)th;
- (void)deleteThDataAsync:(Th *)th;

- (Board *)thForUniqueKey:(NSString *)threadUniqueKey;
- (Th *)registerTh:(Th *)th;
- (Th *)registerTh:(Th *)th canLoadFile:(BOOL)canLoadFile;
- (BOOL)isRegisteredTh:(Th *)th;

@end
