

#import <Foundation/Foundation.h>
#import "ResNodeBase.h"

@interface IDNode : ResNodeBase 

@property(nonatomic, copy) NSString* idText;
@property(nonatomic, copy) NSString* suffix;

- (id)initWithString:(NSString *)id_;
- (id)initWithString:(NSString *)id_ withSuffix:(NSString*)suffix;

- (NSString *)getText;
- (NSString *)description;
@end
