#import <Foundation/Foundation.h>

typedef NSNumber GestureDir;

#define DIRECTION_UP @(0)
#define DIRECTION_DOWN @(1)
#define DIRECTION_LEFT @(2)
#define DIRECTION_RIGHT @(3)


@interface GestureManager : NSObject


- (void)touchesBegan:(CGPoint)point withEvent:(UIEvent *)event;
- (void)touchesMoved:(CGPoint)point withEvent:(UIEvent *)event;
- (void)touchesEnded:(CGPoint)point withEvent:(UIEvent *)event;

- (BOOL)isGesture:(NSArray *)directions;
- (NSArray *)currentGesture;
- (NSString *)gestureString;
- (BOOL)isGestureStarted;
- (void)cancel;

@end
