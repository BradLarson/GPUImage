#import "RawDataTestAppDelegate.h"

@implementation RawDataTestAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    GLubyte *rawDataBytes = calloc(10 * 10 * 4, sizeof(GLubyte));
    for (unsigned int yIndex = 0; yIndex < 10; yIndex++)
    {
        for (unsigned int xIndex = 0; xIndex < 10; xIndex++)
        {
            rawDataBytes[yIndex * 10 * 4 + xIndex * 4] = xIndex;
            rawDataBytes[yIndex * 10 * 4 + xIndex * 4 + 1] = yIndex;
            rawDataBytes[yIndex * 10 * 4 + xIndex * 4 + 2] = 255;
            rawDataBytes[yIndex * 10 * 4 + xIndex * 4 + 3] = 0;            
        }
    }
    
    GPUImageRawDataInput *rawDataInput = [[GPUImageRawDataInput alloc] initWithBytes:rawDataBytes size:CGSizeMake(10.0, 10.0)];    
    GPUImageFilter *customFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"CalculationShader"];
    GPUImageRawDataOutput *rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(10.0, 10.0) resultsInBGRAFormat:YES];
    
    [rawDataInput addTarget:customFilter];
    [customFilter addTarget:rawDataOutput];
    
    [rawDataOutput setNewFrameAvailableBlock:^{
        GLubyte *outputBytes = [rawDataOutput rawBytesForImage];
        NSInteger bytesPerRow = [rawDataOutput bytesPerRowInOutput];
        NSLog(@"Bytes per row: %d", bytesPerRow);
        for (unsigned int yIndex = 0; yIndex < 10; yIndex++)
        {
            for (unsigned int xIndex = 0; xIndex < 10; xIndex++)
            {
                NSLog(@"Byte at (%d, %d): %d, %d, %d, %d", xIndex, yIndex, outputBytes[yIndex * bytesPerRow + xIndex * 4], outputBytes[yIndex * bytesPerRow + xIndex * 4 + 1], outputBytes[yIndex * bytesPerRow + xIndex * 4 + 2], outputBytes[yIndex * bytesPerRow + xIndex * 4 + 3]);
            }
        }
    }];
    
    [rawDataInput processData];
    
    free(rawDataBytes);

    return YES;
}

@end
