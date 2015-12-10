#import <Foundation/Foundation.h>

#import "BBSItemBase.h"
#import "ResNodeBase.h"
#import "TextNode.h"
#import "LinkNode.h"
#import "AnchorNode.h"
#import "LineBreakNode.h"
#import "IDNode.h"
#import "Res.h"

NSDictionary *charRefMap;
void initCharRefMap();

@class ReferScanner;
@class TagScanner;
@class URLScanner;
@class IDScanner;
@class BaseScanner;

//
// 解析中に情報をやりとりする
//
@interface ScanContext : NSObject {
  @public
    Res *res;
    NSMutableArray *resList;
    BaseScanner *firstScanner; // 改行後、最初に来るスキャナー
    BOOL success;
    BOOL endOfLine;
    BOOL endOfText;
    BOOL nextOfTag;
    int nextStartIndex;
    unichar *chars;
    NSUInteger charsLength;
    NSArray *genNodes; //generated nodes

    ReferScanner *referScanner;
    TagScanner *tagScanner;
    IDScanner *idScanner;
    URLScanner *urlScanner;

    unichar firstOfSpace;
    unichar secondOfSpace;
}

@end

//
// BaseScanner
//
// datを走査する上で様々な文字列を認識・抽出を生成するためのスキャナー
// 一度の走査で、不必要なメモリの配置・取得を行わずにパースすることが主な目的
//
// abstruct
@interface BaseScanner : NSObject {
  @public
    BaseScanner *nextScanner;
}

- (void)run:(ScanContext *)context index:(int)start;
- (void)runRefNext:(ScanContext *)context index:(int)rightOfRef;
- (NSString *)translateReference:(unichar *)chars length:(NSUInteger)length;

- (BOOL)startsWith:(unichar *)chars length:(NSUInteger)length index:(int)index string:(NSString *)string;
- (BOOL)startsWith:(ScanContext *)context index:(int)index string:(NSString *)string;

- (BOOL)isDigit:(unichar)unichar;
//
// <>を検出
//
- (BOOL)isDelimiter:(ScanContext *)context index:(int)start;

// 改行用のコンテキストをセットするだけ
- (BOOL)isEndOfLine:(ScanContext *)context index:(int)start;

- (void)onTermGenerated:(ScanContext *)context text:(NSString *)text;
//
// indexOf
//
- (int)indexOf:(ScanContext *)context unichar:(unichar)uchar index:(int)index;
- (int)indexOf:(unichar *)chars length:(NSUInteger)length unichar:(unichar)uchar index:(int)index;

- (int)indexOf:(ScanContext *)context string:(NSString *)string index:(int)index;
- (int)indexOf:(unichar *)chars length:(NSUInteger)length string:(NSString *)string index:(int)index;

- (int)lastIndexOf:(unichar *)chars
            length:(NSUInteger)length
           unichar:(unichar)unichar
        beginIndex:(int)beginIndex
          endIndex:(int)endIndex;
//
- (NSString *)substringOfCharacters:(unichar *)chars length:(NSUInteger)length;
- (NSString *)substringOfCharacters:(unichar *)chars start:(int)start end:(int)end;
@end

//
// NodeScannerBase
//
// 本文内ノード生成用ベース
// abstruct
//
@interface NodeScannerBase : BaseScanner
@end

//
// AnchorScannerBase
//
// アンカーを解析する共通メソッドを持つ抽象クラス
// abstruct
//
@interface AnchorScannerBase : NodeScannerBase

// 複数のアンカーを検出するためのcontinueメソッド
- (void)runContinueWithAnchor:(ScanContext *)context
                continueIndex:(int)continueIndex
                   anchorNode:(AnchorNode *)anchorNode //すでに出来たアンカーノード
    ;
// アンカーの数値だけを検出
- (int)runNumber:(ScanContext *)context index:(int)startIndex;

@end

//
// TagScanner
//
// '<' ではじまるNodeを解析する
//
@interface TagScanner : AnchorScannerBase

// 走査しAnchorNodeかnilを返す
- (void)run:(ScanContext *)context index:(int)start;
@end

//
// ReferScanner
//
// "&gt;&gt;", "＞＞", ">","＞"ではじまるNodeを解析する
//
@interface ReferScanner : AnchorScannerBase {
}

// context->genNodesに解析したノードを追加する
- (void)run:(ScanContext *)context index:(int)start;

@end

//
// IDScanner
//
// ID:ではじまるNodeを解析する
//
@interface IDScanner : NodeScannerBase

- (BOOL)isIdChar:(unichar)c;

// 走査しAnchorNodeかnilを返す
- (void)parseIdNode:(ScanContext *)context index:(int)i;
@end

//
// URLScanner
// ID:ではじまるNodeを解析する
//
@interface URLScanner : NodeScannerBase

// 走査しAnchorNodeかnilを返す
- (void)run:(ScanContext *)context index:(int)i;

@end

//
// BodyScanner
//
// 本文解析
//
@interface BodyScanner : BaseScanner {
}

- (void)run:(ScanContext *)context index:(int)start;

- (int)isBr:(NSString *)str startIndex:(int)start context:(ScanContext *)context;

@end

//
// DateScanner
//
// 本文解析
//
@interface DateScanner : BaseScanner {
}

// 走査し返す
- (void)run:(ScanContext *)context index:(int)start;

@end

//
// NameScanner
//
// 名前
//
@interface NameScanner : BaseScanner {
}

@end

//
// MailScanner
//
// メール
//
@interface MailScanner : BaseScanner {
}

@end

//
// IDScanner
//
// したらばはIDだけの項目がある
//
@interface ShitarabaIDScanner : BaseScanner {
}
@end

//
// ThreadTitleScanner
//
//
@interface TitleScanner : BaseScanner {
}

@end

//
// ResNumberScanner
//
//
@interface ResNumberScanner : BaseScanner {
}

@end

//
// DatParser
// 複数構成のDatLineに対応するルート解析器
//
//
@interface DatParser : BaseScanner {
    BBSSubType _subType;
    NSString *_delimeter;
    int _delimeterLength;
    ScanContext *_context;
}
- (void)setBBSSubType:(BBSSubType)subType;

// 走査しRes*の配列を返す
- (NSArray *)parse:(NSString *)str;
- (NSArray *)parse:(NSString *)str offset:(int)offset;

@end
