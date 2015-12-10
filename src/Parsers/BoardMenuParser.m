#import "BoardMenuParser.h"
#import "Category.h"

@implementation BoardMenuParser

- (NSArray *)parse:(NSString *)text
{
    int length = (int)[text length];
    unichar chars[length];

    [text getCharacters:chars range:NSMakeRange(0, length)];
    BOOL lt = NO; //前の文字が'<'かどうか

    NSMutableArray *categories = [NSMutableArray array];
    ArkCategory *category = nil;
    NSSet *excludeCategorySet = [NSSet setWithObjects:@"おすすめ", nil]; //チャット",@"特別企画",@"ツール類"];
    NSSet *excludeUrls = [NSSet setWithObjects:
                                    @"http://info.2ch.net/rank/", @"http://www.bbspink.com/", @"http://www.machi.to/", @"mailto:2ch@2ch.net", @"http://info.2ch.net/guide/adv.html", @"http://info.2ch.net/mag.html", @"http://www.yakin.cc/", @"http://2ch.tora3.net/", @"mailto:2ch@2ch.net", @"http://newsnavi.2ch.net/", @"http://info.2ch.net/wiki/", @"General Motors", nil];

    for (int i = 0; i < length; i++) {
        unichar letter = chars[i];
        if (lt) {
            //<BR><BR><B>まちＢＢＳ</B><BR>
            //<A HREF=http://www.machi.to/ TARGET=_blank>TOPページ</A><br>

            //カテゴリの検出
            if (letter == 'B' && chars[i + 1] == '>') {
                int indexOfLT = [self indexOf:chars length:length unichar:'<' index:i + 2];
                if (indexOfLT != -1) {
                    NSString *categoryName = [self substringOfCharacters:chars + i + 2 length:indexOfLT - (i + 2)];

                    if (![excludeCategorySet containsObject:categoryName]) {
                        if (category && [category.boards count] == 0) {
                            [categories removeLastObject];
                        }
                        category = [[ArkCategory alloc] initWithName:categoryName];
                        [categories addObject:category];
                    }
                    i = indexOfLT; //i+2;
                }

            } else if ([self startsWith:chars length:length index:i string:@"A HREF"]) {

                //板のURLと名前の検出
                int indexOfGT = [self indexOf:chars length:length unichar:'>' index:i + 7];
                if (indexOfGT != -1) {
                    int urlLast = [self lastIndexOf:chars
                                             length:length
                                            unichar:'/'
                                         beginIndex:i + 7
                                           endIndex:indexOfGT];
                    if (urlLast != -1) {
                        NSString *url = [self substringOfCharacters:chars + i + 7 length:urlLast - (i + 7) + 1];
                        int indexOfLT = [self indexOf:chars
                                               length:length
                                              unichar:'<'
                                                index:indexOfGT];

                        if (indexOfLT != -1) {
                            NSString *boardName = [self substringOfCharacters:chars + indexOfGT + 1
                                                                       length:indexOfLT - (indexOfGT + 1)];
                            if (![excludeUrls containsObject:url]) {
                                Board *board = [Board boardFromUrl:url];
                                board.boardName = boardName;
                                if (board.boardKey != nil && category != nil) {
                                    [category addBoard:board];
                                }
                            }
                            i = indexOfLT;
                        }
                    }
                }
            }
        }

        lt = letter == '<';
    }
    if (category && [category.boards count] == 0) {
        [categories removeLastObject];
    }
    return categories;
}

@end
