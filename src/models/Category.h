
#import <Foundation/Foundation.h>
#import "Board.h"

@interface ArkCategory : NSObject <NSCoding> {
    NSString *_name;
    BOOL _is2ch;
    BOOL _isSelected;
    NSMutableArray *_boards;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSMutableArray *boards;

- (id)init;
- (id)initWithName:(NSString *)name;
- (NSString *)description;

- (void)addBoard:(Board *)board;
- (void)removeBoard:(Board *)board;
@end
