//
//  ZYGPUImgVideoCamera.m
//  SimpleVideoFilter
//
//  Created by zhangyun on 2017/11/9.
//  Copyright © 2017年 Cell Phone. All rights reserved.
//

#import "ZYGPUImgVideoCamera.h"
#import <AVFoundation/AVFoundation.h>


@interface ZYGPUImgVideoCamera()<AVCaptureVideoDataOutputSampleBufferDelegate> {
    dispatch_queue_t cameraProcessQueue;
    dispatch_queue_t audioProcessQueue;
    dispatch_semaphore_t frameRenderSemaphore;
}
@property (nonatomic,strong) AVCaptureSession  *session;
@end

@implementation ZYGPUImgVideoCamera

#pragma mark - public

- (instancetype)init{
    if (self = [super init]) {
        [self configSession];
        [self setupProgram];
    }
    return self;
}

- (void)startCapture{
    
    if ([self.session isRunning]) {
        return;
    }
    [self.session startRunning];
}

#pragma mark - private

- (void)setupProgram{
    
    
}

- (void)configSession{
    cameraProcessQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    audioProcessQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    frameRenderSemaphore =  dispatch_semaphore_create(1)
    
    NSArray *ds = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *camera;
    for (AVCaptureDevice *d in ds) {
        if (d.position == AVCaptureDevicePositionBack) {
            camera = d;
            break;
        }
    }
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:camera error:nil];
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session beginConfiguration];
    self.session = session;
    
    if ([session canAddInput:input]) {
        [session addInput:input];
    }else{
        NSLog(@"add input error;");
    }
    
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setSampleBufferDelegate:self queue:cameraProcessQueue];
    [videoOutput setAlwaysDiscardsLateVideoFrames:NO];
    [videoOutput setVideoSettings:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],kCVPixelBufferPixelFormatTypeKey, nil]];
    
    if ([session canAddOutput:videoOutput]) {
        [session addOutput:videoOutput];
    }else{
         NSLog(@"%@-%s-add videooutput error",[NSThread currentThread],__func__);
    }
    
    [session setSessionPreset:AVCaptureSessionPreset640x480];
    [session commitConfiguration];
}

#pragma mark - samplebuffer callback
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if(dispatch_semaphore_wait(frameRenderSemaphore, DISPATCH_TIME_NOW) != 0){
        return;
    }
    
}

#pragma mark - output delegate
- (void)addTarget:(id)target {
    
}

- (NSArray *)targets {
    return nil;
}
@end



