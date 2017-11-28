//
// Created by zhangyun on 2017/11/28.
// Copyright (c) 2017 Cell Phone. All rights reserved.
//

#import "ZYFrameBuffer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "ZYGPUImgCtx.h"

@interface ZYFrameBuffer(){
    GLuint  frameBuffer;
}
@end

@implementation ZYFrameBuffer

- (instancetype)initWithSize:(CGSize)size {
    if(self = [super init]){
        [self generateFrameBuffer];
    }
    return self;
}

- (void)generateFrameBuffer{

    glGenFramebuffers(1,&frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);

    // corevideo  fast 创建texture
    CVOpenGLESTextureCacheRef textureCacheRef;
    CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [ZYGPUImgCtx shareCtx].currentCtx, NULL,&textureCacheRef);

    CFDictionaryRef empty;
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0,
            &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1,
            &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);

    CVPixelBufferRef pixelBufferRef;
    CVReturn  err = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height,
            kCVPixelFormatType_32ARGB, attrs, pixelBufferRef);
    if(err){
        NSLog(@"create pixel buffer failed");
        return;
    }

    CVOpenGLESTextureRef  textureRef;
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCacheRef, NULL,
            NULL, GL_TEXTURE_2D, GL_RGBA, size.width, size.height,GL_BGRA,GL_UNSIGNED_BYTE,0,&textureRef);

    if(err){
        NSLog(@"create texture from cache");
        return;
    }

    CFRelease(attrs);
    CFRelease(empty);
    glBindTexture(CVOpenGLESTextureGetTarget(textureRef), CVOpenGLESTextureGetName(textureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    renderTexture = CVOpenGLESTextureGetName(textureRef);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, renderTexture, 0);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)destoryFramebuffer{

}


- (GLuint)renderTextureId {
    return renderTexture;
}
@end