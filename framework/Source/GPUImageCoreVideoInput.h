//
//  GPUImageCoreVideoInput.h
//  GPUImage
//
//  Created by Karl von Randow on 3/11/13.
//  Copyright (c) 2013 Brad Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

#import "GPUImageOutput.h"

extern const GLfloat kColorConversion601[];
extern const GLfloat kColorConversion601FullRange[];
extern const GLfloat kColorConversion709[];
extern NSString *const kGPUImageYUVVideoRangeConversionForRGFragmentShaderString;
extern NSString *const kGPUImageYUVFullRangeConversionForLAFragmentShaderString;
extern NSString *const kGPUImageYUVVideoRangeConversionForLAFragmentShaderString;

//Delegate Protocal for Face Detection.
@protocol GPUImageVideoCameraDelegate <NSObject>

@optional
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end


@interface GPUImageCoreVideoInput : GPUImageOutput <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
@protected
    dispatch_semaphore_t frameRenderingSemaphore;
    
    BOOL captureAsYUV;
    BOOL capturePaused;
    GPUImageRotationMode internalRotation;
    
@private
    NSUInteger numberOfFramesCaptured;
    CGFloat totalFrameTimeDuringCapture;
    
    GPUImageRotationMode outputRotation;
    
    GLuint luminanceTexture, chrominanceTexture;
    BOOL isFullYUVRange;
    
    __unsafe_unretained id<GPUImageVideoCameraDelegate> _delegate;
}

/// This enables the benchmarking mode, which logs out instantaneous and average frame times to the console
@property(readwrite, nonatomic) BOOL runBenchmark;

@property(readwrite, nonatomic) GPUImageRotationMode outputRotation;

@property(readwrite, nonatomic) BOOL capturePaused;

@property(nonatomic, assign) id<GPUImageVideoCameraDelegate> delegate;

- (id)initWithCaptureAsYUV:(BOOL)aCaptureAsYUV fullYUVRange:(BOOL)fullYUVRange;

/** Process a video sample
 @param sampleBuffer Buffer to process
 */
- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/** Process a pixel buffer. This must be called on the video processing
    queue. Alternatively use the capturePixelBuffer method to send buffers
    to the video processing queue.
  */
- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer
        atTime:(CMTime)time;

/** Capture a pixel buffer and then process it on the video processing queue.
    Returns NO if the pixel buffer is dropped as the queue is busy, or returns
    YES if the pixel buffer has been retained and will be processed asynchronously
    on the video processing queue.
 */
- (BOOL)capturePixelBuffer:(CVPixelBufferRef)pixelBuffer atTime:(CMTime)time;

+ (GPUImageRotationMode)rotationForImageOrientation:(UIInterfaceOrientation)imageOrientation
                              captureDevicePosition:(AVCaptureDevicePosition)position
                               horizontallyMirrored:(BOOL)horizontallyMirrored;

/// @name Benchmarking

/** When benchmarking is enabled, this will keep a running average of the time from uploading, processing, and final recording or display
 */
- (CGFloat)averageFrameDurationDuringCapture;

- (void)resetBenchmarkAverage;

@end
