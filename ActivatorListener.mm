#import <libactivator/libactivator.h>
#import "CaptureMyScreen.h"
#import "BoardSolver.h"
#import "FakeTouch.h"

@interface CaptureMyScreenListener : NSObject<LAListener, UIAlertViewDelegate> {}
@end

@implementation CaptureMyScreenListener

+(void)load {
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.cloudycliff.gamesolver"];
}

- (void)activator:(LAActivator *)listener receiveEvent:(LAEvent *)event
{
	// UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Title" message:@"Message" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	// [error show];
	// [error release];
	[self captureAndSolve];

	[event setHandled:YES];
}

-(void)activator:(LAActivator *)listener abortEvent:(LAEvent *)event
{
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 1) {
		
	}
}

-(void)captureAndSolve
{
	CaptureMyScreen *_screenCapturer = [[CaptureMyScreen alloc] init];
        
    CGImageRef cgImage = [_screenCapturer captureMyScreen];

    BoardSolver *_boardSolver = [[BoardSolver alloc] init];
    NSArray *array = [_boardSolver solve:cgImage];

    float duration = 4.0f;

        // NSArray *array = [NSArray arrayWithObjects:
        //     [NSValue valueWithCGPoint:CGPointMake(29,401)],
        //     [NSValue valueWithCGPoint:CGPointMake(81,401)],
        //     [NSValue valueWithCGPoint:CGPointMake(81,349)],
        //     [NSValue valueWithCGPoint:CGPointMake(81,296)],
        //     [NSValue valueWithCGPoint:CGPointMake(134,296)],
        //     [NSValue valueWithCGPoint:CGPointMake(134,244)],
        //     [NSValue valueWithCGPoint:CGPointMake(186,244)],
        //     [NSValue valueWithCGPoint:CGPointMake(186,296)],
        //     [NSValue valueWithCGPoint:CGPointMake(186,349)],
        //     [NSValue valueWithCGPoint:CGPointMake(239,349)],
        //     [NSValue valueWithCGPoint:CGPointMake(291,349)],
        //     [NSValue valueWithCGPoint:CGPointMake(291,296)],
        //     [NSValue valueWithCGPoint:CGPointMake(239,296)],
        //     [NSValue valueWithCGPoint:CGPointMake(239,244)],
        //     [NSValue valueWithCGPoint:CGPointMake(291,244)],
        //      nil];

    [FakeTouch simulateMoveFromArray:array duration:duration];

    CGImageRelease(cgImage);
    [_screenCapturer release];

        //CFRunLoopRunInMode(kCFRunLoopDefaultMode , duration+0.1f, NO);
}

@end;