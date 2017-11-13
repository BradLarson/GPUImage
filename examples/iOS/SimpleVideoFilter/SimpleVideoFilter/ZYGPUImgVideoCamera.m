//
//  ZYGPUImgVideoCamera.m
//  SimpleVideoFilter
//
//  Created by zhangyun on 2017/11/9.
//  Copyright © 2017年 Cell Phone. All rights reserved.
//

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
GLfloat kColorConversion601FullRangeDefault[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

#import "ZYGPUImgVideoCamera.h"
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>


@interface ZYGPUImgVideoCamera()<AVCaptureVideoDataOutputSampleBufferDelegate> {
    dispatch_queue_t cameraProcessQueue;
    dispatch_queue_t audioProcessQueue;
    dispatch_semaphore_t frameRenderSemaphore;
    const CGFloat *preferredConvertion;
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
    
    frameRenderSemaphore =  dispatch_semaphore_create(1);
    
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
// 处理视频帧，通过opengl fsh gpu 代码 把 yuv 纹理转换成rgb纹理，在把最终的纹理保存传递下去
- (void)processVideoFrame:(CMSampleBufferRef)sampleBuf{
    // 1. 确定yuv->rgba 转换需要的变换矩阵
    CVImageBufferRef imageBuf = CMSampleBufferGetImageBuffer(sampleBuf);
    CFTypeRef colorAttchments = CVBufferGetAttachment(imageBuf, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttchments) {
        if (CFStringCompare(colorAttchments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0)== kCFCompareEqualTo) {
            preferredConvertion = kColorConversion601FullRangeDefault;
        }
    }
    int  bufferW = (int)CVPixelBufferGetWidth(imageBuf);
    int bufferH = (int)CVPixelBufferGetHeight(imageBuf);
    
    // 2. 把视频帧添加到纹理中,
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuf);
    [[ZYGPUImgCtx shareCtx] userCurrentCtx];
    
    size_t planeCount = CVPixelBufferGetPlaneCount(imageBuf);
    if (planeCount < 0) {
        NSLog(@"get plane count failed");
        return;
    }else{
        NSLog(@"plane count =%ld",planeCount);
    }
    
    // 枷锁 ，开始操作数据
    CVPixelBufferLockBaseAddress(imageBuf, 0);
    
    //
    // TODO: 为何使用4？
    glActiveTexture(GL_TEXTURE4);
    
    CVOpenGLESTextureRef luminanceTexture;
    CVOpenGLESTextureRef  chrominanceTextureRef;
    
    CVOpenGLESTextureCacheRef  videoTexuteCache;
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL,[[ZYGPUImgCtx shareCtx] currentCtx], NULL, &videoTexuteCache);
    if (err) {
        NSLog(@"create texture cache failed %d",err);
    }
    
    err =  CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTexuteCache, imageBuf, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferW, bufferH, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTexture);
    if (err) {
        NSLog(@"create texture from image failed %d",err);
        return;
    }
    GLuint luminanceTextureId = CVOpenGLESTextureGetName(luminanceTexture);
    if (luminanceTextureId <= 0) {
        NSLog(@"get l texuture id failed");
        return;
    }
    
    glBindTexture(GL_TEXTURE_2D, luminanceTextureId);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTexuteCache, imageBuf, NULL, GL_TEXTURE_2D,GL_LUMINANCE_ALPHA, bufferW / 4, bufferH / 4,GL_LUMINANCE_ALPHA ,GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
    if (err) {
        NSLog(@"create texture from chrom %d",err);
        return;
    }
    
    GLuint chrominanceTextureId = CVOpenGLESTextureGetName(chrominanceTextureRef);
    if (chrominanceTextureId <= 0) {
        NSLog(@" get c id failed");
        return;
    }

    
    
    
    
    
    
    
    
    
    
    // 3. 执行gl绘制，把yuv->rgba ,结果数据保存都framebuffer中
}

#pragma mark - samplebuffer callback
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if(dispatch_semaphore_wait(frameRenderSemaphore, DISPATCH_TIME_NOW) != 0){
        return;
    }
    
    // 开启新线程异步处理视频帧数据,转换成rgba数据 传给下一个target
    runAsynchronouslyOnVideoProcessQueue(^{
        CFRetain(sampleBuffer);
        [self processVideoFrame:sampleBuffer];
        CFRelease(sampleBuffer);
    });
}

#pragma mark - output delegate
- (void)addTarget:(id)target {
    
}

- (NSArray *)targets {
    return nil;
}
@end



