#import <CommonCrypto/CommonCrypto.h>
#import "SyncCrypt.h"
#import "TextUtils.h"

static int postXorPattern = 154;
static int readXorPattern = 113;
static int nowXorPattern = 212;
static int countXorPattern = 45;

@implementation SyncCrypt

- (id)init
{
    if (self = [super init]) {
        _keyBytes = nil;
        _cryptLevel = 0;
    }

    return self;
}

- (void)setKey:(NSString *)key withCryptLevel:(int)level
{
    if (key == nil) {
        self.keyBytes = nil;
        self.cryptLevel = 0;
        return;
    }

    self.cryptLevel = level;
    self.keyBytes = [self strTo16Bytes:key];
}

- (NSData *)strTo16Bytes:(NSString *)str
{
    NSData *result = nil;
    if ([str length] > 16) {
        result = [[NSData alloc] initWithBytes:[[str dataUsingEncoding:NSUTF8StringEncoding] bytes] length:16];
    } else {
        char keyPtr[kCCKeySizeAES128 + 1];

        bzero(keyPtr, sizeof(keyPtr));
        [str getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
        result = [NSData dataWithBytes:keyPtr length:16];
    }

    return result;
}

- (NSData *) xor:(NSData *)data pattern:(char)pattern
{
    NSUInteger length = [data length];
    char *bytes = (char *)[data bytes];
    for (int i = 0; i < length; i++) {
        bytes[i] = (char)(bytes[i] ^ pattern);
    }
    return [NSData dataWithBytes:bytes length:length];
}

- (NSData *)genIvBytes:(NSString *)str
{
    return [self strTo16Bytes:str];
}

- (NSString *)reverse:(NSString *)source
{

    NSMutableString *reversedString = [NSMutableString string];
    NSInteger charIndex = [source length];
    while (charIndex > 0) {
        charIndex--;
        NSRange subStrRange = NSMakeRange(charIndex, 1);
        [reversedString appendString:[source substringWithRange:subStrRange]];
    }

    return reversedString;
}

- (NSString *)dec:(NSString *)textToDecrypt iv:(NSData *)ivBytes
{
    if (textToDecrypt == nil) return @"";
    if (self.keyBytes == nil) return textToDecrypt;

    NSData *encryptedData = [TextUtils decodeBase64:textToDecrypt];

    size_t bufferSize = [encryptedData length] + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;

    // CCCrypt(CCOperation op,
    //         CCAlgorithm alg,
    //         CCOptions options,
    //         const void *key,
    //         size_t keyLength,
    //         const void *iv,
    //         const void *dataIn,
    //         size_t dataInLength,
    //         void *dataOut,
    //         size_t dataOutAvailable,
    //         size_t *dataOutMoved

    CCCryptorStatus cryptorStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                            [self.keyBytes bytes], kCCKeySizeAES128,
                                            [ivBytes bytes],
                                            [encryptedData bytes], [encryptedData length],
                                            buffer, bufferSize,
                                            &numBytesEncrypted);

    NSString *result = nil;

    if (cryptorStatus == kCCSuccess) {
        NSData *d = [NSData dataWithBytes:buffer length:numBytesEncrypted];
        result = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    } else {
        result = textToDecrypt;
    }

    free(buffer);

    return result;
}

- (NSString *)enc:(NSString *)textToEncrypt iv:(NSData *)ivBytes
{
    // myLog(@"here2");
    if (textToEncrypt == nil) return @"";
    if (self.keyBytes == nil) {
        return textToEncrypt;
    }
    //    myLog(@"joifwa");

    NSData *plainText = [textToEncrypt dataUsingEncoding:NSUTF8StringEncoding];

    size_t bufferSize = [plainText length] + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;

    // CCCrypt(CCOperation op,
    //         CCAlgorithm alg,
    //         CCOptions options,
    //         const void *key,
    //         size_t keyLength,
    //         const void *iv,
    //         const void *dataIn,
    //         size_t dataInLength,
    //         void *dataOut,
    //         size_t dataOutAvailable,
    //         size_t *dataOutMoved

    CCCryptorStatus cryptorStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                            [self.keyBytes bytes], kCCKeySizeAES128,
                                            [ivBytes bytes],
                                            [plainText bytes], [plainText length],
                                            buffer, bufferSize,
                                            &numBytesEncrypted);

    NSData *result = nil;

    if (cryptorStatus == kCCSuccess) {
        result = [NSData dataWithBytes:buffer length:numBytesEncrypted];
    }

    free(buffer);

    if (result) {
        NSString *enced = [TextUtils encodeBase64Data:result];
        return enced;
    } else {
        return textToEncrypt;
    }
}

- (NSString *)encUrl:(NSString *)url
{
    return self.cryptLevel < 3 ? url : [self enc:[self reverse:url] iv:self.zeroIv];
}

- (NSString *)decUrl:(NSString *)text
{
    return self.cryptLevel < 3 ? text : [self reverse:[self dec:text iv:self.zeroIv]];
}

- (NSString *)encTitle:(NSString *)title url:(NSString *)url
{
    return self.cryptLevel < 2 ? title : [self enc:title iv:[self genIvBytes:[self reverse:url]]];
}

- (NSString *)decTitle:(NSString *)text url:(NSString *)url
{
    return self.cryptLevel < 2 ? text : [self dec:text iv:[self genIvBytes:[self reverse:url]]];
}

- (NSString *)encFolder:(NSString *)folderName
{
    return self.cryptLevel < 4 ? folderName : [self enc:folderName iv:self.zeroIv];
}

- (NSString *)decFolder:(NSString *)text
{
    return self.cryptLevel < 4 ? text : [self dec:text iv:self.zeroIv];
}

- (NSString *)encRead:(NSInteger)readNum url:(NSString *)url
{
    NSString *readNumStr = [NSString stringWithFormat:@"%ld", (long)readNum];
    return self.cryptLevel < 5 ? readNumStr : [self enc:readNumStr iv:[self xor:[self genIvBytes:[self reverse:url]] pattern:readXorPattern]];
}

- (NSString *)decRead:(NSString *)text url:(NSString *)url
{
    return self.cryptLevel < 5 ? text : [self dec:text iv:[self xor:[self genIvBytes:[self reverse:url]] pattern:readXorPattern]];
}

- (NSString *)encNow:(NSInteger)readNum url:(NSString *)url
{
    NSString *readNumStr = [NSString stringWithFormat:@"%ld", (long)readNum];
    return self.cryptLevel < 5 ? readNumStr : [self enc:readNumStr iv:[self xor:[self genIvBytes:[self reverse:url]] pattern:nowXorPattern]];
}

- (NSString *)decNow:(NSString *)text url:(NSString *)url
{
    return self.cryptLevel < 5 ? text : [self dec:text iv:[self xor:[self genIvBytes:[self reverse:url]] pattern:nowXorPattern]];
}

- (NSString *)encCount:(NSInteger)readNum url:(NSString *)url
{
    NSString *readNumStr = [NSString stringWithFormat:@"%ld", (long)readNum];
    return self.cryptLevel < 5 ? readNumStr : [self enc:readNumStr iv:[self xor:[self genIvBytes:[self reverse:url]] pattern:countXorPattern]];
}

- (NSString *)decCount:(NSString *)text url:(NSString *)url
{
    return self.cryptLevel < 5 ? text : [self dec:text iv:[self xor:[self genIvBytes:[self reverse:url]] pattern:countXorPattern]];
}

- (NSString *)encPosts:(NSArray *)posts url:(NSString *)url
{
    if (posts == nil) return @"";

    NSMutableString *strList = [NSMutableString string];

    NSData *ivBytes = [self xor:[self genIvBytes:[self reverse:url]] pattern:postXorPattern];
    BOOL first = YES;

    for (NSNumber *post in posts) {
        NSString *postStr = [NSString stringWithFormat:@"%ld", (long)[post integerValue]];
        NSString *st = self.cryptLevel > 0 ? [self enc:postStr iv:ivBytes] : postStr;

        if (!first) {
            [strList appendString:@","];
        }
        [strList appendString:st];

        if (first) first = NO;
    }

    return strList;
}

//return NSNumber array
- (NSArray *)decPosts:(NSString *)postsStr url:(NSString *)url
{

    NSMutableArray *postList = [NSMutableArray array];
    if (postsStr == nil) return postList;

    NSData *ivBytes = [self xor:[self genIvBytes:[self reverse:url]] pattern:postXorPattern];

    NSArray *array = [postsStr componentsSeparatedByString:@","];
    for (NSString *component in array) {
        NSString *target = component;
        if (self.cryptLevel > 0) {
            target = [self dec:component iv:ivBytes];
        }

        [postList addObject:[NSNumber numberWithInteger:[target intValue]]];
    }

    return postList;
}

@end
