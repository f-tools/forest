//
//  Log.h
//  Forest
//

#import <Foundation/Foundation.h>
// file Log.h

#define myLog(args...) _Log(@"DEBUG ", __FILE__, __LINE__, __PRETTY_FUNCTION__, args);

@interface Log : NSObject
void _Log(NSString *prefix, const char *file, int lineNumber, const char *funcName, NSString *format, ...);

@end
