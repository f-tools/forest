

#include "Category.h"

@implementation ArkCategory

@synthesize boards = _boards;
@synthesize name = _name;

- (id)init
{
    if (self = [super init]) {
        _boards = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _name = [decoder decodeObjectForKey:@"name"];
        _boards = [decoder decodeObjectForKey:@"boards"];
        if (_boards == nil) {
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.boards
                   forKey:@"boards"];
}

- (id)initWithName:(NSString *)name
{
    if (self = [super init]) {
        _boards = [[NSMutableArray alloc] init];
        _name = name;
    }
    return self;
}

- (NSString *)description
{
    return _name;
}

- (void)addBoard:(Board *)board
{
    if (_boards == nil) {
        _boards = [[NSMutableArray alloc] init];
    }

    [_boards addObject:board];
}

- (void)removeBoard:(Board *)board
{
}

@end
