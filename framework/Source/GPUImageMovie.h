#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageOutput.h"

@interface GPUImageMovie : GPUImageOutput

@property (readwrite, retain) NSURL *url;

// Initialization and teardown
- (id)initWithURL:(NSURL *)url;

// Movie processing
- (void)startProcessing;
- (void)endProcessing;
- (void)processMovieFrame:(CMSampleBufferRef)movieSampleBuffer; 

@end
