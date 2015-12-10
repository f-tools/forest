#import "TextUtils.h"
#import <iconv.h>
//#import "iconv.h"
@implementation TextUtils

+ (NSString *)encodeBase64Data:(NSData *)data
{

    NSString *encoded_data;
    if ([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        encoded_data = [data base64EncodedStringWithOptions:kNilOptions]; // iOS7 and later
    } else {
        // encoded_data = [data base64Encoding]; // iOS6 and prior
    }

    return encoded_data;
}

+ (NSString *)encodeBase64:(NSString *)text
{
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    return [TextUtils encodeBase64Data:data];
}

+ (NSData *)decodeBase64:(NSString *)str
{
    // base64 decoding
    NSData *decoded_data;
    if ([NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)]) {
        decoded_data = [[NSData alloc] initWithBase64EncodedString:str options:kNilOptions];
    } else {
        // decoded_data = [[NSData alloc] initWithBase64Encoding:encoded_data];
    }

    return decoded_data;
}

+ (NSString *)decodeBase64:(NSString *)str encoding:(NSStringEncoding)encoding
{
    return @"";
}


+ (NSString *)decodeString:(NSData *)data encoding:(NSStringEncoding)encoding substitution:(NSString *)subs
{
    NSString *a = [[NSString alloc] initWithData:data encoding:encoding];
    if (a != nil) return a;

    if (encoding == NSShiftJISStringEncoding) {
        a = [self data2str:data encoding:encoding];
        if (a != nil) {
            return a;
        }
    }

    NSData *partialData;
    NSString *partialStringByDecodingPartialData;
    NSInteger dataLength = [data length];
    NSInteger location = 0;

    NSMutableString *mutable = [[NSMutableString alloc] init];
    [mutable setString:@""];

    while (location < dataLength) {

        partialData = [NSData dataWithBytesNoCopy:(char *)[data bytes] + location length:1 freeWhenDone:NO];

        partialStringByDecodingPartialData = [[NSString alloc] initWithData:partialData encoding:encoding];
        if (partialStringByDecodingPartialData != nil && [partialStringByDecodingPartialData length] == 1) {
            [mutable appendString:partialStringByDecodingPartialData];
            location += 1;
        } else {
            if (location + 1 < dataLength) {
                partialData = [NSData dataWithBytesNoCopy:(char *)[data bytes] + location length:2 freeWhenDone:NO];
                partialStringByDecodingPartialData = [[NSString alloc] initWithData:partialData encoding:encoding];
                if (partialStringByDecodingPartialData != nil) {
                    [mutable appendString:partialStringByDecodingPartialData];
                    location += 2;
                } else {
                    [mutable appendString:subs];
                    location += 1;
                }
            } else {
                [mutable appendString:subs];
                location += 1;
            }
        }
    }
    return mutable;
}

//データ→文字列
+ (NSString *)data2str:(NSData *)in_data encoding:(NSStringEncoding)encoding
{

    char *fromEncoding = encoding == NSShiftJISStringEncoding ? "SHIFT_JIS" : "EUC-JP";
    in_data = [self cleanUTF8:in_data iconvFromEncoding:fromEncoding iconvToEncoding:"SHIFT_JIS"];

    NSString *str = [[NSString alloc] initWithData:in_data encoding:NSShiftJISStringEncoding];

    if (str != nil) {
        myLog(@"clean succuess");
        return str;
    }

    myLog(@"clean failure");
    //return nil;

    // 変換エラーなので自前で１文字毎に変換する
    NSMutableString *str2 = [NSMutableString stringWithString:@""];
    // NSMutableData* async_data = [[NSMutableData alloc] initWithData:in_data];
    NSUInteger length = [in_data length];
    // unsigned char abuf[length];
    unsigned char *buf = (unsigned char *)[in_data bytes]; //(unsigned char*)[in_data mutableBytes];
    NSData *async_data = in_data;
    NSUInteger len = length; //[async_data length];

    NSData *pickup;
    NSString *str999;

    //NSMutableData* mutableData = [NSMutableData dataWithData:in_data];
    //unsigned char* mutableBytes = [mutableData mutableBytes];

    //  347+1 ：JKB48 [↓] ：2012/05/17(木) 13:34:25.24 ID:YE5Ahd9B0 (2/5) [PC]
    for (int i = 0; i < len; i++) {

        if (*buf == 0x0a || *buf == 0x00) {
            // 制御文字
            pickup = [async_data subdataWithRange:NSMakeRange(i, 1)];
            str999 = [[NSString alloc] initWithData:pickup encoding:NSShiftJISStringEncoding];
            if (str999 == nil) {
                myLog(@"convert error %x kana", *buf);
                str999 = @"?";
            }
            [str2 appendString:str999];
            buf++;
            continue;
        }

        //    348+1 ：JKB48 [↓] ：2012/05/17(木) 13:34:50.07 ID:YE5Ahd9B0 (3/5) [PC]

        if (*buf >= 0x20 && *buf <= 0x7e) {
            // ASCII文字
            pickup = [async_data subdataWithRange:NSMakeRange(i, 1)];
            str999 = [[NSString alloc] initWithData:pickup encoding:NSShiftJISStringEncoding];
            if (str999 == nil) {
                myLog(@"convert error %x ASCII", *buf);
                str999 = @"?";
            }
            [str2 appendString:str999];
            buf++;
            continue;
        }

        if (*buf >= 0xA1 && *buf <= 0xDF) {
            // 半角カタカナ
            pickup = [async_data subdataWithRange:NSMakeRange(i, 1)];
            str999 = [[NSString alloc] initWithData:pickup encoding:NSShiftJISStringEncoding];
            if (str999 == nil) {
                myLog(@"convert error %x KANA", *buf);
                str999 = @"?";
            }
            [str2 appendString:str999];
            buf++;
            continue;
        }

        //    349 ：JKB48 [↓] ：2012/05/17(木) 13:35:09.78 ID:YE5Ahd9B0 (4/5) [PC]
        if ((*buf >= 0x81 && *buf <= 0x9f) ||
            (*buf >= 0xe0 && *buf <= 0xfc)) {
            // 漢字１バイト目
            if ((*(buf + 1) >= 0x40 && *(buf + 1) <= 0xfc) && (*(buf + 1) != 0x7f)) {
                // 漢字２バイト目
                pickup = [async_data subdataWithRange:NSMakeRange(i, 2)];
                str999 = [[NSString alloc] initWithData:pickup encoding:NSShiftJISStringEncoding];
                if (str999 == nil) {
                    myLog(@"convert error %x %x", *buf, *(buf + 1));
                    str999 = @"??";
                }
            } else {
                myLog(@"convert error 2 %x %x", *buf, *(buf + 1));
                str999 = @"??";
                myLog(@"%x %x", *buf, *(buf + 1));
            }
            [str2 appendString:str999];
            buf++;
            buf++;
            i++;
            continue;
        }

        myLog(@"not sjis %x", *buf);
        str999 = @"?";
        [str2 appendString:str999];
    }

    return str2;
}

+ (NSData *)cleanUTF8:(NSData *)data iconvFromEncoding:(char *)iconvFromEncoding iconvToEncoding:(char *)iconvToEncoding
{

    iconv_t cd = iconv_open(iconvFromEncoding, iconvToEncoding); //"SHIFT_JIS", "SHIFT_JIS"); // convert to UTF-8 from UTF-8
    int one = 1;
    iconvctl(cd, ICONV_SET_DISCARD_ILSEQ, &one); // discard invalid characters
    size_t inbytesleft, outbytesleft;
    inbytesleft = outbytesleft = data.length;
    char *inbuf = (char *)data.bytes;
    char *outbuf = malloc(sizeof(char) * data.length);
    char *outptr = outbuf;
    if (iconv(cd, &inbuf, &inbytesleft, &outptr, &outbytesleft) == (size_t)-1) {
        myLog(@"this should not happen, seriously");
        return nil;
    }
    NSData *result = [NSData dataWithBytes:outbuf length:data.length - outbytesleft];
    iconv_close(cd);
    free(outbuf);
    return result;
}

+ (BOOL)ambiguitySearchText:(NSString *)text searchKey:(NSString *)searchKey
{
    if (text == nil || searchKey == nil) return NO;

    NSString *str1 = [self replaceAmbiguityString:text];
    NSString *str2 = [self replaceAmbiguityString:searchKey];

    NSRange range = [str1 rangeOfString:str2];
    return range.location != NSNotFound;
}

static NSMutableDictionary *_searchAmbiguityDict;

+ (NSString *)replaceAmbiguityString:(NSString *)text
{
    if (text == nil) return text;

    if (_searchAmbiguityDict == nil) {
        _searchAmbiguityDict = [NSMutableDictionary dictionary];

        [_searchAmbiguityDict setObject:@"A" forKey:@"Ａ"];
        [_searchAmbiguityDict setObject:@"A" forKey:@"a"];
        [_searchAmbiguityDict setObject:@"A" forKey:@"ａ"];
        [_searchAmbiguityDict setObject:@"B" forKey:@"Ｂ"];
        [_searchAmbiguityDict setObject:@"B" forKey:@"b"];
        [_searchAmbiguityDict setObject:@"B" forKey:@"ｂ"];
        [_searchAmbiguityDict setObject:@"C" forKey:@"Ｃ"];
        [_searchAmbiguityDict setObject:@"C" forKey:@"c"];
        [_searchAmbiguityDict setObject:@"C" forKey:@"ｃ"];
        [_searchAmbiguityDict setObject:@"D" forKey:@"Ｄ"];
        [_searchAmbiguityDict setObject:@"D" forKey:@"d"];
        [_searchAmbiguityDict setObject:@"D" forKey:@"ｄ"];
        [_searchAmbiguityDict setObject:@"E" forKey:@"Ｅ"];
        [_searchAmbiguityDict setObject:@"E" forKey:@"e"];
        [_searchAmbiguityDict setObject:@"E" forKey:@"ｅ"];
        [_searchAmbiguityDict setObject:@"F" forKey:@"Ｆ"];
        [_searchAmbiguityDict setObject:@"F" forKey:@"f"];
        [_searchAmbiguityDict setObject:@"F" forKey:@"ｆ"];
        [_searchAmbiguityDict setObject:@"G" forKey:@"Ｇ"];
        [_searchAmbiguityDict setObject:@"G" forKey:@"g"];
        [_searchAmbiguityDict setObject:@"G" forKey:@"ｇ"];
        [_searchAmbiguityDict setObject:@"H" forKey:@"Ｈ"];
        [_searchAmbiguityDict setObject:@"H" forKey:@"h"];
        [_searchAmbiguityDict setObject:@"H" forKey:@"ｈ"];
        [_searchAmbiguityDict setObject:@"I" forKey:@"Ｉ"];
        [_searchAmbiguityDict setObject:@"I" forKey:@"i"];
        [_searchAmbiguityDict setObject:@"I" forKey:@"ｉ"];
        [_searchAmbiguityDict setObject:@"J" forKey:@"Ｊ"];
        [_searchAmbiguityDict setObject:@"J" forKey:@"j"];
        [_searchAmbiguityDict setObject:@"J" forKey:@"ｊ"];
        [_searchAmbiguityDict setObject:@"K" forKey:@"Ｋ"];
        [_searchAmbiguityDict setObject:@"K" forKey:@"k"];
        [_searchAmbiguityDict setObject:@"K" forKey:@"ｋ"];
        [_searchAmbiguityDict setObject:@"L" forKey:@"Ｌ"];
        [_searchAmbiguityDict setObject:@"L" forKey:@"l"];
        [_searchAmbiguityDict setObject:@"L" forKey:@"ｌ"];
        [_searchAmbiguityDict setObject:@"M" forKey:@"Ｍ"];
        [_searchAmbiguityDict setObject:@"M" forKey:@"m"];
        [_searchAmbiguityDict setObject:@"M" forKey:@"ｍ"];
        [_searchAmbiguityDict setObject:@"N" forKey:@"Ｎ"];
        [_searchAmbiguityDict setObject:@"N" forKey:@"n"];
        [_searchAmbiguityDict setObject:@"N" forKey:@"ｎ"];
        [_searchAmbiguityDict setObject:@"O" forKey:@"Ｏ"];
        [_searchAmbiguityDict setObject:@"O" forKey:@"o"];
        [_searchAmbiguityDict setObject:@"O" forKey:@"ｏ"];
        [_searchAmbiguityDict setObject:@"P" forKey:@"Ｐ"];
        [_searchAmbiguityDict setObject:@"P" forKey:@"p"];
        [_searchAmbiguityDict setObject:@"P" forKey:@"ｐ"];
        [_searchAmbiguityDict setObject:@"Q" forKey:@"Ｑ"];
        [_searchAmbiguityDict setObject:@"Q" forKey:@"q"];
        [_searchAmbiguityDict setObject:@"Q" forKey:@"ｑ"];
        [_searchAmbiguityDict setObject:@"R" forKey:@"Ｒ"];
        [_searchAmbiguityDict setObject:@"R" forKey:@"r"];
        [_searchAmbiguityDict setObject:@"R" forKey:@"ｒ"];
        [_searchAmbiguityDict setObject:@"S" forKey:@"Ｓ"];
        [_searchAmbiguityDict setObject:@"S" forKey:@"s"];
        [_searchAmbiguityDict setObject:@"S" forKey:@"ｓ"];
        [_searchAmbiguityDict setObject:@"T" forKey:@"Ｔ"];
        [_searchAmbiguityDict setObject:@"T" forKey:@"t"];
        [_searchAmbiguityDict setObject:@"T" forKey:@"ｔ"];
        [_searchAmbiguityDict setObject:@"U" forKey:@"Ｕ"];
        [_searchAmbiguityDict setObject:@"U" forKey:@"u"];
        [_searchAmbiguityDict setObject:@"U" forKey:@"ｕ"];
        [_searchAmbiguityDict setObject:@"V" forKey:@"Ｖ"];
        [_searchAmbiguityDict setObject:@"V" forKey:@"v"];
        [_searchAmbiguityDict setObject:@"V" forKey:@"ｖ"];
        [_searchAmbiguityDict setObject:@"W" forKey:@"Ｗ"];
        [_searchAmbiguityDict setObject:@"W" forKey:@"w"];
        [_searchAmbiguityDict setObject:@"W" forKey:@"ｗ"];
        [_searchAmbiguityDict setObject:@"X" forKey:@"Ｘ"];
        [_searchAmbiguityDict setObject:@"X" forKey:@"x"];
        [_searchAmbiguityDict setObject:@"X" forKey:@"ｘ"];
        [_searchAmbiguityDict setObject:@"Y" forKey:@"Ｙ"];
        [_searchAmbiguityDict setObject:@"Y" forKey:@"y"];
        [_searchAmbiguityDict setObject:@"Y" forKey:@"ｙ"];
        [_searchAmbiguityDict setObject:@"Z" forKey:@"Ｚ"];
        [_searchAmbiguityDict setObject:@"Z" forKey:@"z"];
        [_searchAmbiguityDict setObject:@"Z" forKey:@"ｚ"];
        [_searchAmbiguityDict setObject:@"-" forKey:@"ー"];
        [_searchAmbiguityDict setObject:@"-" forKey:@"－"];
        [_searchAmbiguityDict setObject:@"-" forKey:@"―"];
        [_searchAmbiguityDict setObject:@"あ" forKey:@"ア"];
        [_searchAmbiguityDict setObject:@"あ" forKey:@"ｱ"];
        [_searchAmbiguityDict setObject:@"あ" forKey:@"ぁ"];
        [_searchAmbiguityDict setObject:@"あ" forKey:@"ァ"];
        [_searchAmbiguityDict setObject:@"い" forKey:@"イ"];
        [_searchAmbiguityDict setObject:@"い" forKey:@"ｲ"];
        [_searchAmbiguityDict setObject:@"い" forKey:@"ぃ"];
        [_searchAmbiguityDict setObject:@"い" forKey:@"ィ"];
        [_searchAmbiguityDict setObject:@"う" forKey:@"ウ"];
        [_searchAmbiguityDict setObject:@"う" forKey:@"ｳ"];
        [_searchAmbiguityDict setObject:@"う" forKey:@"ぅ"];
        [_searchAmbiguityDict setObject:@"う" forKey:@"ゥ"];
        [_searchAmbiguityDict setObject:@"え" forKey:@"エ"];
        [_searchAmbiguityDict setObject:@"え" forKey:@"ｴ"];
        [_searchAmbiguityDict setObject:@"え" forKey:@"ぇ"];
        [_searchAmbiguityDict setObject:@"え" forKey:@"ェ"];
        [_searchAmbiguityDict setObject:@"お" forKey:@"オ"];
        [_searchAmbiguityDict setObject:@"お" forKey:@"ｵ"];
        [_searchAmbiguityDict setObject:@"お" forKey:@"ぉ"];
        [_searchAmbiguityDict setObject:@"お" forKey:@"ォ"];
        [_searchAmbiguityDict setObject:@"か" forKey:@"カ"];
        [_searchAmbiguityDict setObject:@"か" forKey:@"ｶ"];
        [_searchAmbiguityDict setObject:@"か" forKey:@"ヵ"];
        [_searchAmbiguityDict setObject:@"き" forKey:@"キ"];
        [_searchAmbiguityDict setObject:@"き" forKey:@"ｷ"];
        [_searchAmbiguityDict setObject:@"く" forKey:@"ク"];
        [_searchAmbiguityDict setObject:@"く" forKey:@"ｸ"];
        [_searchAmbiguityDict setObject:@"け" forKey:@"ケ"];
        [_searchAmbiguityDict setObject:@"け" forKey:@"ｹ"];
        [_searchAmbiguityDict setObject:@"こ" forKey:@"コ"];
        [_searchAmbiguityDict setObject:@"こ" forKey:@"ｺ"];
        [_searchAmbiguityDict setObject:@"さ" forKey:@"サ"];
        [_searchAmbiguityDict setObject:@"さ" forKey:@"ｻ"];
        [_searchAmbiguityDict setObject:@"し" forKey:@"シ"];
        [_searchAmbiguityDict setObject:@"し" forKey:@"ｼ"];
        [_searchAmbiguityDict setObject:@"す" forKey:@"ス"];
        [_searchAmbiguityDict setObject:@"す" forKey:@"ｽ"];
        [_searchAmbiguityDict setObject:@"せ" forKey:@"セ"];
        [_searchAmbiguityDict setObject:@"せ" forKey:@"ｾ"];
        [_searchAmbiguityDict setObject:@"そ" forKey:@"ソ"];
        [_searchAmbiguityDict setObject:@"そ" forKey:@"ｿ"];
        [_searchAmbiguityDict setObject:@"た" forKey:@"タ"];
        [_searchAmbiguityDict setObject:@"た" forKey:@"ﾀ"];
        [_searchAmbiguityDict setObject:@"ち" forKey:@"チ"];
        [_searchAmbiguityDict setObject:@"ち" forKey:@"ﾁ"];
        [_searchAmbiguityDict setObject:@"つ" forKey:@"ツ"];
        [_searchAmbiguityDict setObject:@"つ" forKey:@"ﾂ"];
        [_searchAmbiguityDict setObject:@"て" forKey:@"テ"];
        [_searchAmbiguityDict setObject:@"て" forKey:@"ﾃ"];
        [_searchAmbiguityDict setObject:@"と" forKey:@"ト"];
        [_searchAmbiguityDict setObject:@"と" forKey:@"ﾄ"];
        [_searchAmbiguityDict setObject:@"な" forKey:@"ナ"];
        [_searchAmbiguityDict setObject:@"な" forKey:@"ﾅ"];
        [_searchAmbiguityDict setObject:@"に" forKey:@"ニ"];
        [_searchAmbiguityDict setObject:@"に" forKey:@"ﾆ"];
        [_searchAmbiguityDict setObject:@"ぬ" forKey:@"ヌ"];
        [_searchAmbiguityDict setObject:@"ぬ" forKey:@"ﾇ"];
        [_searchAmbiguityDict setObject:@"ね" forKey:@"ネ"];
        [_searchAmbiguityDict setObject:@"ね" forKey:@"ﾈ"];
        [_searchAmbiguityDict setObject:@"の" forKey:@"ノ"];
        [_searchAmbiguityDict setObject:@"の" forKey:@"ﾉ"];
        [_searchAmbiguityDict setObject:@"は" forKey:@"ハ"];
        [_searchAmbiguityDict setObject:@"は" forKey:@"ﾊ"];
        [_searchAmbiguityDict setObject:@"ひ" forKey:@"ヒ"];
        [_searchAmbiguityDict setObject:@"ひ" forKey:@"ﾋ"];
        [_searchAmbiguityDict setObject:@"ふ" forKey:@"フ"];
        [_searchAmbiguityDict setObject:@"ふ" forKey:@"ﾌ"];
        [_searchAmbiguityDict setObject:@"へ" forKey:@"ヘ"];
        [_searchAmbiguityDict setObject:@"へ" forKey:@"ﾍ"];
        [_searchAmbiguityDict setObject:@"ほ" forKey:@"ホ"];
        [_searchAmbiguityDict setObject:@"ほ" forKey:@"ﾎ"];
        [_searchAmbiguityDict setObject:@"ま" forKey:@"マ"];
        [_searchAmbiguityDict setObject:@"ま" forKey:@"ﾏ"];
        [_searchAmbiguityDict setObject:@"み" forKey:@"ミ"];
        [_searchAmbiguityDict setObject:@"み" forKey:@"ﾐ"];
        [_searchAmbiguityDict setObject:@"む" forKey:@"ム"];
        [_searchAmbiguityDict setObject:@"む" forKey:@"ﾑ"];
        [_searchAmbiguityDict setObject:@"め" forKey:@"メ"];
        [_searchAmbiguityDict setObject:@"め" forKey:@"ﾒ"];
        [_searchAmbiguityDict setObject:@"も" forKey:@"モ"];
        [_searchAmbiguityDict setObject:@"も" forKey:@"ﾓ"];
        [_searchAmbiguityDict setObject:@"や" forKey:@"ヤ"];
        [_searchAmbiguityDict setObject:@"や" forKey:@"ﾔ"];
        [_searchAmbiguityDict setObject:@"や" forKey:@"ゃ"];
        [_searchAmbiguityDict setObject:@"や" forKey:@"ャ"];
        [_searchAmbiguityDict setObject:@"ゆ" forKey:@"ユ"];
        [_searchAmbiguityDict setObject:@"ゆ" forKey:@"ﾕ"];
        [_searchAmbiguityDict setObject:@"よ" forKey:@"ヨ"];
        [_searchAmbiguityDict setObject:@"よ" forKey:@"ﾖ"];
        [_searchAmbiguityDict setObject:@"ら" forKey:@"ラ"];
        [_searchAmbiguityDict setObject:@"ら" forKey:@"ﾗ"];
        [_searchAmbiguityDict setObject:@"り" forKey:@"リ"];
        [_searchAmbiguityDict setObject:@"り" forKey:@"ﾘ"];
        [_searchAmbiguityDict setObject:@"る" forKey:@"ル"];
        [_searchAmbiguityDict setObject:@"る" forKey:@"ﾙ"];
        [_searchAmbiguityDict setObject:@"れ" forKey:@"レ"];
        [_searchAmbiguityDict setObject:@"れ" forKey:@"ﾚ"];
        [_searchAmbiguityDict setObject:@"ろ" forKey:@"ロ"];
        [_searchAmbiguityDict setObject:@"ろ" forKey:@"ﾛ"];
        [_searchAmbiguityDict setObject:@"わ" forKey:@"ワ"];
        [_searchAmbiguityDict setObject:@"わ" forKey:@"ﾜ"];
        [_searchAmbiguityDict setObject:@"わ" forKey:@"ゎ"];
        [_searchAmbiguityDict setObject:@"わ" forKey:@"ヮ"];
        [_searchAmbiguityDict setObject:@"を" forKey:@"ヲ"];
        [_searchAmbiguityDict setObject:@"を" forKey:@"ｦ"];
        [_searchAmbiguityDict setObject:@"ん" forKey:@"ン"];
        [_searchAmbiguityDict setObject:@"ん" forKey:@"ﾝ"];
        [_searchAmbiguityDict setObject:@"ガ" forKey:@"が"];
        [_searchAmbiguityDict setObject:@"ガ" forKey:@"ｶﾞ"];
        [_searchAmbiguityDict setObject:@"ギ" forKey:@"ぎ"];
        [_searchAmbiguityDict setObject:@"ギ" forKey:@"ｷﾞ"];
        [_searchAmbiguityDict setObject:@"グ" forKey:@"ぐ"];
        [_searchAmbiguityDict setObject:@"グ" forKey:@"ｸﾞ"];
        [_searchAmbiguityDict setObject:@"ゲ" forKey:@"げ"];
        [_searchAmbiguityDict setObject:@"ゲ" forKey:@"ｹﾞ"];
        [_searchAmbiguityDict setObject:@"ゴ" forKey:@"ご"];
        [_searchAmbiguityDict setObject:@"ゴ" forKey:@"ｺﾞ"];
        [_searchAmbiguityDict setObject:@"ザ" forKey:@"ざ"];
        [_searchAmbiguityDict setObject:@"ザ" forKey:@"ｻﾞ"];
        [_searchAmbiguityDict setObject:@"ジ" forKey:@"じ"];
        [_searchAmbiguityDict setObject:@"ジ" forKey:@"ｼﾞ"];
        [_searchAmbiguityDict setObject:@"ズ" forKey:@"ず"];
        [_searchAmbiguityDict setObject:@"ズ" forKey:@"ｽﾞ"];
        [_searchAmbiguityDict setObject:@"ゼ" forKey:@"ぜ"];
        [_searchAmbiguityDict setObject:@"ゼ" forKey:@"ｾﾞ"];
        [_searchAmbiguityDict setObject:@"ゾ" forKey:@"ぞ"];
        [_searchAmbiguityDict setObject:@"ゾ" forKey:@"ｿﾞ"];
        [_searchAmbiguityDict setObject:@"ダ" forKey:@"だ"];
        [_searchAmbiguityDict setObject:@"ダ" forKey:@"ﾀﾞ"];
        [_searchAmbiguityDict setObject:@"ヂ" forKey:@"ぢ"];
        [_searchAmbiguityDict setObject:@"ヂ" forKey:@"ﾁﾞ"];
        [_searchAmbiguityDict setObject:@"ヅ" forKey:@"ﾂﾞ"];
        [_searchAmbiguityDict setObject:@"デ" forKey:@"で"];
        [_searchAmbiguityDict setObject:@"デ" forKey:@"ﾃﾞ"];
        [_searchAmbiguityDict setObject:@"ド" forKey:@"ど"];
        [_searchAmbiguityDict setObject:@"ド" forKey:@"ﾄﾞ"];
        [_searchAmbiguityDict setObject:@"バ" forKey:@"ば"];
        [_searchAmbiguityDict setObject:@"バ" forKey:@"ﾊﾞ"];
        [_searchAmbiguityDict setObject:@"ビ" forKey:@"び"];
        [_searchAmbiguityDict setObject:@"ビ" forKey:@"ﾋﾞ"];
        [_searchAmbiguityDict setObject:@"ブ" forKey:@"ぶ"];
        [_searchAmbiguityDict setObject:@"ブ" forKey:@"ﾌﾞ"];
        [_searchAmbiguityDict setObject:@"ベ" forKey:@"べ"];
        [_searchAmbiguityDict setObject:@"ベ" forKey:@"ﾍﾞ"];
        [_searchAmbiguityDict setObject:@"ボ" forKey:@"ぼ"];
        [_searchAmbiguityDict setObject:@"ボ" forKey:@"ﾎﾞ"];
        [_searchAmbiguityDict setObject:@"パ" forKey:@"ぱ"];
        [_searchAmbiguityDict setObject:@"パ" forKey:@"ﾊﾟ"];
        [_searchAmbiguityDict setObject:@"ピ" forKey:@"ぴ"];
        [_searchAmbiguityDict setObject:@"ピ" forKey:@"ﾋﾟ"];
        [_searchAmbiguityDict setObject:@"プ" forKey:@"ぷ"];
        [_searchAmbiguityDict setObject:@"プ" forKey:@"ﾌﾟ"];
        [_searchAmbiguityDict setObject:@"ペ" forKey:@"ぺ"];
        [_searchAmbiguityDict setObject:@"ペ" forKey:@"ﾍﾟ"];
        [_searchAmbiguityDict setObject:@"ポ" forKey:@"ぽ"];
        [_searchAmbiguityDict setObject:@"ポ" forKey:@"ﾎﾟ"];
        [_searchAmbiguityDict setObject:@"０" forKey:@"0"];
        [_searchAmbiguityDict setObject:@"０" forKey:@"〇"];
        [_searchAmbiguityDict setObject:@"１" forKey:@"1"];
        [_searchAmbiguityDict setObject:@"１" forKey:@"一"];
        [_searchAmbiguityDict setObject:@"１" forKey:@"Ⅰ"];
        [_searchAmbiguityDict setObject:@"１" forKey:@"ⅰ"];
        [_searchAmbiguityDict setObject:@"２" forKey:@"2"];
        [_searchAmbiguityDict setObject:@"２" forKey:@"二"];
        [_searchAmbiguityDict setObject:@"２" forKey:@"Ⅱ"];
        [_searchAmbiguityDict setObject:@"２" forKey:@"ⅱ"];
        [_searchAmbiguityDict setObject:@"３" forKey:@"3"];
        [_searchAmbiguityDict setObject:@"３" forKey:@"三"];
        [_searchAmbiguityDict setObject:@"３" forKey:@"Ⅲ"];
        [_searchAmbiguityDict setObject:@"３" forKey:@"ⅲ"];
        [_searchAmbiguityDict setObject:@"４" forKey:@"4"];
        [_searchAmbiguityDict setObject:@"４" forKey:@"四"];
        [_searchAmbiguityDict setObject:@"４" forKey:@"Ⅳ"];
        [_searchAmbiguityDict setObject:@"４" forKey:@"ⅳ"];
        [_searchAmbiguityDict setObject:@"５" forKey:@"5"];
        [_searchAmbiguityDict setObject:@"５" forKey:@"五"];
        [_searchAmbiguityDict setObject:@"５" forKey:@"Ⅴ"];
        [_searchAmbiguityDict setObject:@"５" forKey:@"ⅴ"];
        [_searchAmbiguityDict setObject:@"６" forKey:@"6"];
        [_searchAmbiguityDict setObject:@"６" forKey:@"六"];
        [_searchAmbiguityDict setObject:@"６" forKey:@"Ⅵ"];
        [_searchAmbiguityDict setObject:@"６" forKey:@"ⅵ"];
        [_searchAmbiguityDict setObject:@"７" forKey:@"7"];
        [_searchAmbiguityDict setObject:@"７" forKey:@"七"];
        [_searchAmbiguityDict setObject:@"７" forKey:@"Ⅶ"];
        [_searchAmbiguityDict setObject:@"７" forKey:@"ⅶ"];
        [_searchAmbiguityDict setObject:@"８" forKey:@"8"];
        [_searchAmbiguityDict setObject:@"８" forKey:@"八"];
        [_searchAmbiguityDict setObject:@"８" forKey:@"Ⅷ"];
        [_searchAmbiguityDict setObject:@"８" forKey:@"ⅷ"];
        [_searchAmbiguityDict setObject:@"９" forKey:@"9"];
        [_searchAmbiguityDict setObject:@"９" forKey:@"九"];
        [_searchAmbiguityDict setObject:@"９" forKey:@"Ⅸ"];
        [_searchAmbiguityDict setObject:@"９" forKey:@"ⅸ"];
    }

    NSMutableString *mutableStr = [NSMutableString string];
    for (NSInteger start = 0; start < [text length]; start++) {
        NSString *part = [text substringWithRange:NSMakeRange(start, 1)];
        NSString *replacement = [_searchAmbiguityDict objectForKey:part];

        [mutableStr appendString:replacement ? replacement : part];
    }

    return mutableStr;
}

@end
