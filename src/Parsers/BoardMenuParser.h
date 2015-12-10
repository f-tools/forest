#import <Foundation/Foundation.h>
#import "DatParser.h"

//
// 解析中に情報をやりとりする
//
@interface BoardMenuParser : BaseScanner

// Categoryの一覧を返す
- (NSArray *)parse:(NSString *)text;

@end
