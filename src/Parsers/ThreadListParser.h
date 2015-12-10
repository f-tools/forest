#import <Foundation/Foundation.h>
#import "DatParser.h"

//
// 解析中に情報をやりとりする
//
@interface ThreadListParser : BaseScanner {
    BBSSubType _subType;
    NSString *_delimeter;
    int _delimeterLength;
}

// スレ一覧を返す
- (NSArray *)parse:(NSData *)data;

- (void)setBBSSubType:(BBSSubType)subType;

@end
