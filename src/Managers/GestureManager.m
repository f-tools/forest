/**
 *
 * GestureManager
 *
 * ListViewにおけるジェスチャー機能を実装します。 水平フリック操作から始まります。
 */

#import "GestureManager.h"

@interface GestureManager () {
    float _downY;
    float _downX;
    BOOL _isCanceled;
    BOOL _isGestureStarted;
    float _verticalOriginPoint;
    float _farPoint; // 現在のジェスチャー方向の最も奥の値

    NSMutableArray *_directions;
    GestureDir *_currentDirection;
}


@end

@implementation GestureManager


- (id)init
{
    if (self = [super init]) {
        _directions = [NSMutableArray array];
    }
    return self;
}

- (void)initDirections
{
    [_directions removeAllObjects];
    _isCanceled = NO;
    _isGestureStarted = NO;
}

- (void)touchesBegan:(CGPoint)point withEvent:(UIEvent *)event
{
    _downX = point.x;
    _downY = point.y;

    [self initDirections];
}

- (void)cancel
{
    _isCanceled = YES;
}


- (void)touchesMoved:(CGPoint)cgpoint withEvent:(UIEvent *)event
{
    if (_isCanceled)
        return;

    float x = cgpoint.x;
    float y = cgpoint.y;

    if (_isGestureStarted) { //ジェスチャーがすでに始まっている。

        float point = [self getPoint:_currentDirection x:x y:y];                 //現在の方向のポイント
        float verticalPoint = [self getVerticalPoint:_currentDirection x:x y:y]; //垂直方向のポイント

        // 最奥地点の更新
        _farPoint = [self getFarPoint:_currentDirection
                                    p:_farPoint
                                    q:[self getPoint:_currentDirection
                                                   x:x
                                                   y:y]];

        if ([self abs:_farPoint - point] > 60) {
            // 反対側ジェスチャー
            _verticalOriginPoint = verticalPoint;
            _farPoint = point;

            _currentDirection = [self getOppositeDirection:_currentDirection];
            [_directions addObject:_currentDirection];

        } else if ([self abs:_verticalOriginPoint - verticalPoint] > 50) {
            // 真横側ジェスチャ
            _currentDirection = [self getVerticalDierction:_currentDirection
                                                      from:_verticalOriginPoint
                                                        to:verticalPoint];
            _farPoint = verticalPoint;
            _verticalOriginPoint = point;

            [_directions addObject:(_currentDirection)];
        }
    } else {

        if ([self abs:y - _downY] < 30) {
            if ([self abs:x - _downX] > 56) {
                _isGestureStarted = YES;

                _farPoint = x;
                _verticalOriginPoint = y;

                [_directions removeAllObjects];
                _currentDirection = x > _downX ? DIRECTION_RIGHT : DIRECTION_LEFT;
                [_directions addObject:_currentDirection];
            }
        } else {
            _isCanceled = YES;
        }
    }
}

- (float)abs:(float)v
{
    return v < 0 ? -v : v;
}

- (void)touchesEnded:(CGPoint)point withEvent:(UIEvent *)event
{
    //UITouch *touch = [[event allTouches] anyObject];
    //CGPoint point = [touch locationInView:self.view];
    //myLog(@"touchesEnded:%f,%f", point.x, point.y);
}

/**
 * 現在の方向に垂直な方向の値を返します。
 */
- (float)getVerticalPoint:(GestureDir *)direction x:(float)x y:(float)y
{
    return [self isYAxis:direction] ? x : y;
}

- (NSString *)getDirectionString:(GestureDir *)direction
{
    if ([direction  isEqual: DIRECTION_UP])
        return @"↑";
    if ([direction  isEqual: DIRECTION_DOWN])
        return @"↓";
    if ([direction  isEqual: DIRECTION_LEFT])
        return @"←";
    return @"→";
}

/**
 * 方向にとって最も遠い値を返す。
 */
- (float)getFarPoint:(GestureDir *)direction p:(float)q q:(float)p
{
    if ([direction isEqual: DIRECTION_RIGHT] || [direction  isEqual: DIRECTION_DOWN])
        return p > q ? p : q; // 大きいほうが遠い
    else
        return p < q ? p : q; // 小さいほうが遠い
}

- (float)getPoint:(NSNumber *)a x:(float)x y:(float)y
{
    return [self isYAxis:a] ? y : x;
}

- (BOOL)isYAxis:(GestureDir *)direction
{
    return [direction  isEqual: DIRECTION_UP] || [direction  isEqual: DIRECTION_DOWN];
}

- (GestureDir *)getVerticalDierction:(GestureDir *)direction from:(float)from to:(float)to
{
    if ([self isYAxis:direction]) {
        return from < to ? DIRECTION_RIGHT : DIRECTION_LEFT;
    } else {
        return from < to ? DIRECTION_DOWN : DIRECTION_UP;
    }
}

- (GestureDir *)getOppositeDirection:(GestureDir *)direction
{
    if ([direction  isEqual: DIRECTION_DOWN]) return DIRECTION_UP;
    if ([direction  isEqual: DIRECTION_UP]) return DIRECTION_DOWN;
    if ([direction  isEqual: DIRECTION_LEFT]) return DIRECTION_RIGHT;
    return DIRECTION_LEFT;
}

// 引数のジェスチャーが実行されているかを返します。
- (BOOL)isGesture:(NSArray *)directions
{
    if ([directions count] != [_directions count])
        return NO;

    int i = 0;
    for (GestureDir *direction in _directions) {
        if ([directions objectAtIndex:i++] != direction) {
            return NO;
        }
    }

    return YES;
}

/**
 * 現在のジェスチャーの方向リストを返します。
 */
- (NSArray *)currentGesture
{
    return _directions;
}

- (NSString *)gestureString
{
    NSMutableString *mutable = [[NSMutableString alloc] init];
    for (GestureDir *d in _directions) {
        [mutable appendString:[self getDirectionString:d]];
    }
    return mutable;
}

/**
 * 次のジェスチャーに進んだかどうかを返します。
 * 
 * @return
 */
- (BOOL)isNext
{
    return YES;
}

- (BOOL)isGestureStarted
{
    return _isGestureStarted;
}

@end
