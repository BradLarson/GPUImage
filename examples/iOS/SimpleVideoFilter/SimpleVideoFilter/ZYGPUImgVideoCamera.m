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
#import "ZYGLProgram.h"
#import "ZYFrameBuffer.h"

@interface ZYGPUImgVideoCamera()<AVCaptureVideoDataOutputSampleBufferDelegate> {
    dispatch_queue_t cameraProcessQueue;
    dispatch_queue_t audioProcessQueue;
    dispatch_semaphore_t frameRenderSemaphore;
    const CGFloat *preferredConvertion;
    ZYGLProgram *yuv2rgbProgram;
    GLuint  luminanceTextureId;
    GLuint  chrominanceTextureId;

    GLuint  yUnifromIndex,uvUnifromIndex,colorMatrixIndex,postionAttriIndex,inputTextureAttriIndex;

    GLint  imgW,imgH;
}
@property (nonatomic,strong) AVCaptureSession  *session;
@property (nonatomic, strong) NSMutableArray<ZYFrameBuffer *> *frameBufferArys;
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
    yuv2rgbProgram = [[ZYGLProgram alloc]
            initWithVertexShaderFile:[[NSBundle mainBundle] pathForResource:@"vertexShader.glsl" ofType:nil]
                      fragShaderFile:[[NSBundle mainBundle] pathForResource:@"fragShader.glsl" ofType:nil]];


    [yuv2rgbProgram addAttribute:@"position"];
    [yuv2rgbProgram addAttribute:@"inputTextureCoord"];

    [yuv2rgbProgram link];
    if(NO == [yuv2rgbProgram validate]){
        NSLog(@"prgram validate failed.......%@\n-%@\n-%@\n",
                yuv2rgbProgram.programLog,yuv2rgbProgram.vertexShaderLog,yuv2rgbProgram.fragShaderLog);
    }
    postionAttriIndex = [yuv2rgbProgram attributeIndex:@"position"];
    inputTextureAttriIndex = [yuv2rgbProgram attributeIndex:@"inputTextureCoord"];
    yUnifromIndex = [yuv2rgbProgram uniformIndex:@"luminanceTexture"];
    uvUnifromIndex = [yuv2rgbProgram uniformIndex:@"chrominaceTexture"];
    colorMatrixIndex = [yuv2rgbProgram uniformIndex:@"colorConversionMatrix"];

    glEnableVertexAttribArray(postionAttriIndex);
    glEnableVertexAttribArray(inputTextureAttriIndex);

    [yuv2rgbProgram use];


    self.frameBufferArys = [NSMutableArray array];
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
    [videoOutput setVideoSettings:[NSDictionary dictionaryWithObjectsAndKeys
    :[NSNumber numberWithInteger:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
                    kCVPixelBufferPixelFormatTypeKey, nil]];
    
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

    imgW = bufferW;
    imgH = bufferH;
    
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
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
            NULL,[[ZYGPUImgCtx shareCtx] currentCtx], NULL, &videoTexuteCache);
    if (err) {
        NSLog(@"create texture cache failed %d",err);
    }
    
    err =  CVOpenGLESTextureCacheCreateTextureFromImage
            (kCFAllocatorDefault, videoTexuteCache, imageBuf, NULL, GL_TEXTURE_2D, GL_LUMINANCE,
                    bufferW, bufferH, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTexture);
    if (err) {
        NSLog(@"create texture from image failed %d",err);
        return;
    }
    luminanceTextureId = CVOpenGLESTextureGetName(luminanceTexture);
    if (luminanceTextureId <= 0) {
        NSLog(@"get l texuture id failed");
        return;
    }
    
    glBindTexture(GL_TEXTURE_2D, luminanceTextureId);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            videoTexuteCache, imageBuf, NULL, GL_TEXTURE_2D,GL_LUMINANCE_ALPHA,
            bufferW / 2, bufferH / 2,GL_LUMINANCE_ALPHA ,GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
    if (err) {
        NSLog(@"create texture from chrom %d",err);
        return;
    }
    
    chrominanceTextureId = CVOpenGLESTextureGetName(chrominanceTextureRef);
    if (chrominanceTextureId <= 0) {
        NSLog(@" get c id failed");
        return;
    }
    glBindTexture(GL_TEXTURE_2D, chrominanceTextureId);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 3. 执行gl绘制，把yuv->rgba ,结果数据保存都framebuffer中
    // program ,设置program 纹理参数，几何参数。
    [self convertYUV2RGB];
}

// 过程就是开启绘制，通过program把YUV数据转成rgb数据，然后数据保存在framebuffer中。
- (void)convertYUV2RGB{

    // context
    [[ZYGPUImgCtx shareCtx] userCurrentCtx];

    // framebuffer renderbuffer
//    GLuint  framebufferId;
//    GLuint  renderbufferId;

//    glGenFramebuffers(1, &framebufferId);
//    glGenRenderbuffers(1, &renderbufferId);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbufferId);


//    glBindFramebuffer(GL_FRAMEBUFFER, framebufferId);
//    glViewport(0, 0, imgW, imgH);

    // program使用
    [yuv2rgbProgram use];

    // framebuffer
    ZYFrameBuffer *fbo;
    if([self.frameBufferArys count] > 0){
         fbo = [self.frameBufferArys lastObject];
    }else{
         fbo = [[ZYFrameBuffer alloc] initWithSize:CGSizeMake(imgW, imgH)];
    }

    glBindFramebuffer(GL_FRAMEBUFFER, [fbo renderTextureId]);
    glViewport(0, 0, imgW, imgH);

    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // 设置顶点 纹理坐标，uniform 数据
   static const GLfloat vertexArray[] = {
           -1,-1,
           1,-1,
           -1,1,
           1,1
    };

    static  const GLfloat textureCoord[]= {
            0,0,
            1,0,
            0,1,
            1,1
    };

    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D,luminanceTextureId);
    glUniform1i(yUnifromIndex, 4);

    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, chrominanceTextureId);
    glUniform1i(uvUnifromIndex, 5);

    glUniformMatrix3fv(colorMatrixIndex, 1, GL_FALSE, kColorConversion601FullRangeDefault);

    glVertexAttribPointer(postionAttriIndex, 2, GL_FLOAT, NO, 0, vertexArray);
    glVertexAttribPointer(inputTextureAttriIndex, 2, GL_FLOAT, NO, 0,textureCoord);

    // 绘制
    glDrawArrays(GL_STATIC_DRAW, 0, 4);

}

#pragma mark - samplebuffer callback
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
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



