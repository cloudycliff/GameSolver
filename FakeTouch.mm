#import <mach/mach_time.h>
#import <CoreGraphics/CoreGraphics.h>
#import <rocketbootstrap.h>

#define LOOP_TIMES_IN_SECOND 40
//60
#define MACH_PORT_NAME "kr.iolate.simulatetouch"

typedef enum {
    STTouchMove = 0,
    STTouchDown,
    STTouchUp
} STTouchType;

typedef struct {
    int type;
    int index;
    float point_x;
    float point_y;
} STEvent;

@interface STTouchA : NSObject
{
@public
    int type; //0: move/stay| 1: down| 2: up
    int pathIndex;
    CGPoint startPoint;
    CGPoint endPoint;
    uint64_t startTime;
    float requestedTime;
}
@end
@implementation STTouchA
@end

static CFMessagePortRef messagePort = NULL;
static NSMutableArray* ATouchEvents = nil;
static BOOL FTLoopIsRunning = FALSE;
static int totalCount = 2; //default 2 points for swipes

#pragma mark -

static int simulate_touch_event(int index, int type, CGPoint point) {
    
    if (messagePort && !CFMessagePortIsValid(messagePort)){
        CFRelease(messagePort);
        messagePort = NULL;
    }
    if (!messagePort) {
        messagePort = rocketbootstrap_cfmessageportcreateremote(NULL, CFSTR(MACH_PORT_NAME));
        //messagePort = CFMessagePortCreateRemote(NULL, CFSTR(MACH_PORT_NAME));
    }
    if (!messagePort || !CFMessagePortIsValid(messagePort)) {
        return 0; //kCFMessagePortIsInvalid;
    }
    
    STEvent event;
    event.type = type;
    event.index = index;
    event.point_x = point.x;
    event.point_y = point.y;
    
    CFDataRef cfData = CFDataCreate(NULL, (uint8_t*)&event, sizeof(event));
    CFDataRef rData = NULL;
    
    CFMessagePortSendRequest(messagePort, 1/*type*/, cfData, 1, 1, kCFRunLoopDefaultMode, &rData);
    
    if (cfData) {
        CFRelease(cfData);
    }
    
    int pathIndex;
    [(NSData *)rData getBytes:&pathIndex length:sizeof(pathIndex)];
    
    if (rData) {
        CFRelease(rData);
    }
    
    return pathIndex;

}

double MachTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer / (double)timebase.denom / 1e9;
}

static void _simulateTouchLoop()
{
    if (FTLoopIsRunning == FALSE) {
        return;
    }
    int touchCount = [ATouchEvents count];
    
    if (touchCount == 0) {
        FTLoopIsRunning = FALSE;
        return;
    }
    
    uint64_t curTime = mach_absolute_time();
    
    STTouchA* touch = [ATouchEvents objectAtIndex:0];// always deal with the first move
    
    int touchType = touch->type;
    //0: move/stay 1: down 2: up
    
    if (touchType == 1) {
        //Already simulate_touch_event is called
        touch->type = STTouchMove;
    }else {
        double dif = MachTimeToSecs(curTime - touch->startTime);
        
        float req = touch->requestedTime * (totalCount - touchCount);
        // NSLog(@"Time: %f, %f", dif, req);
        if (dif >= 0 && dif < req) {
            //Move
            float dx = touch->endPoint.x - touch->startPoint.x;
            float dy = touch->endPoint.y - touch->startPoint.y;
            
            double per = (dif - (double)req + touch->requestedTime) / touch->requestedTime;

            CGPoint point = CGPointMake(touch->startPoint.x + (float)(dx * per), touch->startPoint.y + (float)(dy * per));
            // NSLog(@"Point: %f, %f", point.x, point.y);
            simulate_touch_event(touch->pathIndex, STTouchMove, point);
        }else {
            //move to the end point
            simulate_touch_event(touch->pathIndex, STTouchMove, touch->endPoint);
            // NSLog(@"move to end");
            //touch up after moved to the last point
            if (touchCount == 1) {
                // NSLog(@"touch up");
                simulate_touch_event(touch->pathIndex, STTouchUp, touch->endPoint);
            }
            //remove the finished point
            [ATouchEvents removeObject:touch];
        }
    }
    
    //recursive
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / LOOP_TIMES_IN_SECOND);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        _simulateTouchLoop();
    });
}

#pragma mark -

@interface FakeTouch : NSObject
@end

@implementation FakeTouch

+(CGPoint)STScreenToWindowPoint:(CGPoint)point withOrientation:(UIInterfaceOrientation)orientation {
    CGSize screen = [[UIScreen mainScreen] bounds].size;
    
    if (orientation == UIInterfaceOrientationPortrait) {
        return point;
    }else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGPointMake(screen.width - point.x, screen.height - point.y);
    }else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        //Homebutton is left
        return CGPointMake(screen.height - point.y, point.x);
    }else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGPointMake(point.y, screen.width - point.x);
    }else return point;
}

+(CGPoint)STWindowToScreenPoint:(CGPoint)point withOrientation:(UIInterfaceOrientation)orientation {
    CGSize screen = [[UIScreen mainScreen] bounds].size;
    
    if (orientation == UIInterfaceOrientationPortrait) {
        return point;
    }else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGPointMake(screen.width - point.x, screen.height - point.y);
    }else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        //Homebutton is left
        return CGPointMake(point.y, screen.height - point.x);
    }else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGPointMake(screen.width - point.y, point.x);
    }else return point;
}

+(int)simulateTouch:(int)pathIndex atPoint:(CGPoint)point withType:(STTouchType)type
{
    int r = simulate_touch_event(pathIndex, type, point);
    
    if (r == 0) {
        NSLog(@"ST Error: simulateTouch:atPoint:withType: index:%d type:%d pathIndex:0", pathIndex, type);
        return 0;
    }
    return r;
}

+(int)simulateSwipeFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(float)duration
{
    if (ATouchEvents == nil) {
        ATouchEvents = [[NSMutableArray alloc] init];
    }
    
    STTouchA* touch = [[STTouchA alloc] init];
    
    touch->type = STTouchMove;
    touch->startPoint = fromPoint;
    touch->endPoint = toPoint;
    touch->requestedTime = duration;
    touch->startTime = mach_absolute_time();
    
    [ATouchEvents addObject:touch];
    
    int r = simulate_touch_event(0, STTouchDown, fromPoint);
    if (r == 0) {
        NSLog(@"ST Error: simulateSwipeFromPoint:toPoint:duration: pathIndex:0");
        return 0;
    }
    touch->pathIndex = r;
    
    if (!FTLoopIsRunning) {
        FTLoopIsRunning = TRUE;
        _simulateTouchLoop();
    }
    
    return r;
}

+(int)simulateMoveFromArray:(NSArray *)array duration:(float)duration
{
    if (ATouchEvents == nil) {
        ATouchEvents = [[NSMutableArray alloc] init];
    }

    uint64_t curTime = mach_absolute_time();
    int count = [array count];
    totalCount = count;

    int r = simulate_touch_event(0, STTouchDown, [[array objectAtIndex:0] CGPointValue]);
    if (r == 0) {
        NSLog(@"ST Error: simulateMoveFromDict:duration: pathIndex:0");
        return 0;
    }

    for (int i = 0; i < count - 1; i++) {
        CGPoint p = [[array objectAtIndex:i] CGPointValue];
        CGPoint p1 = [[array objectAtIndex:(i + 1)] CGPointValue];

        STTouchA* touch = [[STTouchA alloc] init];
    
        touch->type = STTouchMove;
        touch->startPoint = p;
        touch->endPoint = p1;
        touch->requestedTime = (duration / (count - 1));
        touch->pathIndex = r;
        touch->startTime = curTime + (duration / (count - 1)) * i;
        
        [ATouchEvents addObject:touch];
    }
    
    if (!FTLoopIsRunning) {
        FTLoopIsRunning = TRUE;
        _simulateTouchLoop();
    }
    
    return r;
}

@end