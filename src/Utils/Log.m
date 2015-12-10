//
//  Log.m
//  Forest
//

#import "Log.h"
#import "Env.h"

@implementation Log

void _Log(NSString *prefix, const char *file, int lineNumber, const char *funcName, NSString *format, ...)
{
    va_list ap;
    va_start(ap, format);
    format = [format stringByAppendingString:@"\n"];
    NSString *msg = [[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%@", format] arguments:ap];
    if ([Env isMine]) { //myLog
        NSLog(@"%@ (%s, #%d)", msg, funcName, lineNumber);
    }

    va_end(ap);
    // fprintf(stdout,"%s%50s:%3d - %s",[prefix UTF8String], funcName, lineNumber, [msg UTF8String]);
}

@end
