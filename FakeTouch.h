typedef enum {
    STTouchMove = 0,
    STTouchDown,
    STTouchUp
} STTouchType;

@interface FakeTouch

//  Screen point: Absolute point (Portrait point)
//  Window point: Orientated point

//  Sreen point to window point. Portrait to 'orientation'
+(CGPoint)STScreenToWindowPoint:(CGPoint)point withOrientation:(int)orientation;

//  Window point to screen point. 'orientation' to Portrait.
+(CGPoint)STWindowToScreenPoint:(CGPoint)point withOrientation:(int)orientation;


//  if pathIndex is 0, SimulateTouch alloc its pathIndex.
//  retrun value is pathIndex. if 0, touch was failed.

//  Class methods' point is screen point.
+(int)simulateTouch:(int)pathIndex atPoint:(CGPoint)point withType:(STTouchType)type;
+(int)simulateSwipeFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(float)duration;
+(int)simulateMoveFromArray:(NSArray *)array duration:(float)duration;
@end