#import "BoardSolver.h"

#define ROWS 5
#define COLS 6

#define LEFT_MARGIN 7
#define RIGHT_MARGIN 8
#define TOP_MARGIN 438
#define BOTTOM_MARGIN 2
#define CELL_H_SPACE 5
#define CELL_V_SPACE 5
#define CELL_HEIGHT 100
#define CELL_WIDTH 100

int pointPositions[ROWS][COLS][2]; //x,y
int pointTypes[ROWS][COLS];

@implementation BoardSolver

-(NSArray *)solve:(CGImageRef)imageRef
{
	[self detectColor:imageRef];

    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:16];
    for (int i = 0; i < ROWS; i++) {
        for (int j = 0; j < COLS; j++) {
            //printf("%d ", pointTypes[i][j]);
            [s appendFormat:@"%d,", pointTypes[i][j]];
        }
    }
    [s deleteCharactersInRange:NSMakeRange([s length] - 1, 1)];

    NSString *urlString = [NSString stringWithFormat:@"http://192.168.1.108:8000/?%@", s];
    NSURL *url = [NSURL URLWithString:urlString];  
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url 
        cachePolicy:NSURLRequestUseProtocolCachePolicy  
        timeoutInterval:10];  
    NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];  
    NSString *str = [[NSString alloc] initWithData:received encoding:NSUTF8StringEncoding];  
    
    NSArray *returnArray = [str componentsSeparatedByString:@","];

    NSArray *initPoint = [NSArray arrayWithObjects:returnArray[0], returnArray[1], nil];
    //0 right
    //1 
    //2 down
    //3 
    //4 left
    //5 
    //6 up
    //7
    NSMutableArray *path = [NSMutableArray arrayWithCapacity:10];
    
    for (int i = 2; i < [returnArray count]; i++) {
        [path addObject:returnArray[i]];
    }

    NSDictionary *solution = [NSDictionary dictionaryWithObjectsAndKeys:initPoint, @"initPoint",
        path, @"path", nil];
    
    NSArray *array = [self calculatePoints:solution];

    return array;
}

-(NSArray *)calculatePoints:(NSDictionary *)solution
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:16];
    int x = [[[solution objectForKey:@"initPoint"] objectAtIndex:0] intValue];
    int y = [[[solution objectForKey:@"initPoint"] objectAtIndex:1] intValue];

    CGPoint p = CGPointMake(pointPositions[x][y][0] / 2, pointPositions[x][y][1] / 2);
    [array addObject:[NSValue valueWithCGPoint:p]];

    NSArray *path = [solution objectForKey:@"path"];

    for (int i = 0; i < [path count]; i++) {
        int direction = [[path objectAtIndex:i] intValue];
        switch (direction) {
            case 0:
                y++;
                break;
            case 2:
                x++;
                break;
            case 4:
                y--;
                break;
            case 6:
                x--;
                break;
            default:
                break;
        }
        p = CGPointMake(pointPositions[x][y][0] / 2, pointPositions[x][y][1] / 2);
        [array addObject:[NSValue valueWithCGPoint:p]];
    }

    return array;
}

-(void)detectColor:(CGImageRef)imageRef
{
	[self generatePointPositions];

    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    for (int yy=0;yy<ROWS; yy++)
    {
        for (int xx=0; xx<COLS; xx++)
        {
            int x = pointPositions[yy][xx][0];
            int y = pointPositions[yy][xx][1];

            int byteIndex = (bytesPerRow * y) + x * bytesPerPixel;

//          CGFloat red   = (rawData[byteIndex]     * 1.0) ;
//          CGFloat green = (rawData[byteIndex + 1] * 1.0) ;
            CGFloat blue  = (rawData[byteIndex + 2] * 1.0) ; //only use blue color to detect types now
            
//          int redValue = (int)red;
//          int greenValue = (int)green;
            int blueValue = (int)blue;
            
            switch (blueValue) {
                case 68:
                    pointTypes[yy][xx] = 0;
                    break;
                case 255:
                    pointTypes[yy][xx] = 1;
                    break;
                case 115:
                    pointTypes[yy][xx] = 2;
                    break;
                case 136:
                    pointTypes[yy][xx] = 3;
                    break;
                case 187:
                    pointTypes[yy][xx] = 4;
                    break;
                case 119:
                    pointTypes[yy][xx] = 5;
                    break;
                default:
                    pointTypes[yy][xx] = 0;//ERROR
                    break;
            }
        }
    }
    
    free(rawData);
}

-(void)generatePointPositions
{
    int initY = (int)([UIScreen mainScreen].bounds.size.height * 2 - BOTTOM_MARGIN - CELL_HEIGHT * 5 - CELL_V_SPACE * 4 + CELL_HEIGHT / 2);
    int initX = (int)(1 + LEFT_MARGIN + CELL_WIDTH / 2);
    for (int i = 0; i < ROWS; i++) {
        for (int j = 0; j < COLS; j++) {
            pointPositions[i][j][0] = initX + CELL_WIDTH * j + CELL_H_SPACE * j;
            pointPositions[i][j][1] = initY + CELL_HEIGHT * i + CELL_V_SPACE * i;
        }
    }
}

@end