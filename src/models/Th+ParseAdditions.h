
#import <Foundation/Foundation.h>
#import "Th.h"

@interface Th (ParseAdditions)

- (void)clearResponses;
- (void)addRes:(Res *)res;
- (void)loadResponsesFromLocalFile;
- (BOOL)existsDatFile;
- (void)checkNG:(Res *)res;
- (void)updateMyResInfo:(Res *)res isMine:(BOOL)isMine;
@end
