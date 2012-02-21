#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageOutput.h"

@interface GPUImageMovie : GPUImageOutput {
  CVPixelBufferRef _currentBuffer;
}

@property (readwrite, retain) NSURL *url;

-(id)initWithURL:(NSURL *)url;
-(void)startProcessing;
-(void)endProcessing;

@end
