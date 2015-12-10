#import "CookieManager.h"
#import "Th.h"
#import "ThUpdater.h"
#import "BoardMenuParser.h"
#import "Env.h"
#import "Category.h"
#import "Board.h"



@interface CookieManager ()


@property (nonatomic) NSMutableDictionary *domainDictionary;
@property (nonatomic) NSMutableDictionary *serverDictionary;

@end

//
// クッキーの情報を管理する
//
@implementation CookieManager

static CookieManager *_sharedCookieManager = nil;

static NSString *_cookiesPath;

+ (CookieManager *)sharedManager
{
    @synchronized(self)
    {
        if (!_sharedCookieManager) {
            NSString *docPath = [Env documentPath];
            _cookiesPath = [docPath stringByAppendingPathComponent:@"cookies"];

            _sharedCookieManager = [[self alloc] init];
        }
    }
    return _sharedCookieManager;
}

- (id)init
{
    if (self = [super init]) {
        _domainDictionary = [[NSMutableDictionary alloc] init];
        _serverDictionary = [[NSMutableDictionary alloc] init];
        [self loadCookies];
    }
    return self;
}

- (void)deleteAllCookie
{
    _domainDictionary = [[NSMutableDictionary alloc] init];
    _serverDictionary = [[NSMutableDictionary alloc] init];
    [self saveCookies];
}

- (void)saveCookies
{
    @synchronized(self)
    {
        NSDictionary *cookies = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  _serverDictionary, @"server",
                                                  _domainDictionary, @"domain", nil];
        BOOL successful = [NSKeyedArchiver archiveRootObject:cookies toFile:_cookiesPath];
        if (successful) {
            //myLog(@"%@", @"データの保存に成功しました。");
        }
    }
}

- (void)loadCookies
{
    @synchronized(self)
    {
        @try {
            NSDictionary *cookies = [NSKeyedUnarchiver unarchiveObjectWithFile:_cookiesPath];
            if (cookies) {
                NSMutableDictionary *serverCookies = [cookies objectForKey:@"server"];
                if (serverCookies) {
                    _serverDictionary = serverCookies;
                }
                
                NSMutableDictionary *domainCookies = [cookies objectForKey:@"domain"];
                if (domainCookies) {
                    _domainDictionary = domainCookies;
                }
            }

        }
        @catch (NSException *exception) {
         
        }
        @finally {
         
        }
    }
}

- (NSString *)cookieForServer:(NSString *)server
{
    NSMutableString *mutable = [[NSMutableString alloc] init];

    // ドメイン対応
    for (NSString *domainName in [self.domainDictionary allKeys]) {
        if ([server hasSuffix:domainName]) {
            NSMutableDictionary *domainCookies = [self.domainDictionary objectForKey:domainName];


            // TODO: DMDMとMDMD
            for (NSString *domainName in self.domainDictionary.allKeys) {
                NSMutableDictionary *cookies = [self.domainDictionary objectForKey:domainName];
                for (NSString *key in cookies) {
                    NSDictionary *entry = [cookies objectForKey:key];

                    if ([key isEqualToString:@"DMDM"] || [key isEqualToString:@"MDMD"]) {
                        [mutable appendString:key];
                        [mutable appendString:@"="];

                        [mutable appendString:[entry objectForKey:@"value"]];
                        [mutable appendString:@";"];
                    }
                }
            }
            /*
             for (NSString * key in [domainCookies allKeys]) {
             if ([key isEqualToString:@"DMDM"]  || [key isEqualToString:@"MDMD"]) {
             [mutable appendString:key];
             [mutable appendString:@"="];
             NSDictionary* entry = [domainCookies objectForKey:key];
             [mutable appendString:[entry objectForKey:@"value"]];
             [mutable appendString:@";"];
             }
             }*/

            for (NSString *key in [domainCookies allKeys]) {
                if ([key isEqualToString:@"DMDM"] == NO && [key isEqualToString:@"MDMD"] == NO) {
                    [mutable appendString:key];
                    [mutable appendString:@"="];
                    NSDictionary *entry = [domainCookies objectForKey:key];
                    [mutable appendString:[entry objectForKey:@"value"]];
                    [mutable appendString:@";"];
                }
            }
        }
    }

    // サーバー対応
    NSMutableDictionary *serverCookies = [self.serverDictionary objectForKey:server];
    if (serverCookies) {
        for (NSString *key in [serverCookies allKeys]) {
            [mutable appendString:key];
            [mutable appendString:@"="];
            NSDictionary *entry = [serverCookies objectForKey:key];
            [mutable appendString:[entry objectForKey:@"value"]];
            [mutable appendString:@";"];
        }
    }

    return mutable;
}

- (NSString *)getCookieForDomain:(NSString *)domain
{
    NSMutableDictionary *domainCookiesDictionary = [self.domainDictionary objectForKey:domain];

    NSMutableString *mutable = [[NSMutableString alloc] init];
    if (domainCookiesDictionary) {
        for (NSString *key in [domainCookiesDictionary allKeys]) {
            [mutable appendString:key];
            [mutable appendString:@"="];
            NSDictionary *entry = [domainCookiesDictionary objectForKey:key];
            [mutable appendString:[entry objectForKey:@"value"]];
            [mutable appendString:@";"];
        }
    }

    return mutable;
}

- (void)setCookie:(NSString *)fieldValue forServer:(NSString *)server
{
    if (fieldValue == nil) return;

    NSArray *fragments = [fieldValue componentsSeparatedByString:@","];
    for (NSString *fragment in fragments) {
        myLog(@"fragment = %@", fragment);

        NSArray *termsByPeriod = [fragment componentsSeparatedByString:@";"];

        NSString *cookieName = nil;
        NSString *cookieValue = nil;
        NSString *expires = nil;
        NSString *path = nil;
        NSString *domain = nil;

        for (NSString *term in termsByPeriod) {
            NSArray *nameAndValue = [term componentsSeparatedByString:@"="];
            if ([nameAndValue count] < 2) {
                continue;
            }

            NSString *name = [nameAndValue objectAtIndex:0];
            NSString *value = [nameAndValue objectAtIndex:1];
            value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
            name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];

            if (cookieName == nil) {
                cookieName = name;
                cookieValue = value;
            } else if ([name isEqualToString:@"expires"]) {
                expires = value;
            } else if ([name isEqualToString:@"path"]) {
                path = value;
            } else if ([name isEqualToString:@"domain"]) {
                domain = value;
            }
        }

        if (cookieName == nil) continue;

        NSMutableDictionary *cookieEntry = [[NSMutableDictionary alloc] init];
        if (domain) {
            [cookieEntry setObject:domain forKey:@"domain"];
        }
        if (path) [cookieEntry setObject:path forKey:@"path"];
        if (cookieName) [cookieEntry setObject:cookieName forKey:@"name"];
        if (cookieValue) [cookieEntry setObject:cookieValue forKey:@"value"];
        if (expires) [cookieEntry setObject:expires forKey:@"expires"];

    
        if (domain != nil) {
            NSMutableDictionary *dict = [self.domainDictionary objectForKey:domain];
            if (dict) {
                [dict setObject:cookieEntry forKey:cookieName];
            } else {
                dict = [[NSMutableDictionary alloc] init];
                [dict setObject:cookieEntry forKey:cookieName];
                [self.domainDictionary setObject:dict forKey:domain];
            }
        } else {
            NSMutableDictionary *dict = [self.serverDictionary objectForKey:server];
            if (dict) {
                [dict setObject:cookieEntry forKey:cookieName];
            } else {
                dict = [[NSMutableDictionary alloc] init];
                [dict setObject:cookieEntry forKey:cookieName];
                [self.serverDictionary setObject:dict forKey:server];
            }
        }
    }
    [self saveCookies];
}

- (BOOL)hasBECookie
{
    return [self hasDomainCookieOfName:@"DMDM"] && [self hasDomainCookieOfName:@"MDMD"];
}

- (void)removeBECookie
{
    [self removeDomainCookieOfName:@"DMDM"];
    [self removeDomainCookieOfName:@"MDMD"];
    [self saveCookies];
}

- (BOOL)hasDomainCookieOfName:(NSString *)name
{
    for (NSString *domainName in [self.domainDictionary allKeys]) {
        NSMutableDictionary *domainCookies = [self.domainDictionary objectForKey:domainName];
        NSObject *entry = [domainCookies objectForKey:name];
        if (entry) {
            return YES;
        }
    }
    return NO;
}

- (void)removeDomainCookieOfName:(NSString *)name
{
    for (NSString *domainName in [self.domainDictionary allKeys]) {
        NSMutableDictionary *domainCookies = [self.domainDictionary objectForKey:domainName];
        [domainCookies removeObjectForKey:name];
    }
}

@end
