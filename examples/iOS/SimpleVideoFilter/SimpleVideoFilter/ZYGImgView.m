//
// Created by zhangyun on 2017/11/29.
// Copyright (c) 2017 Cell Phone. All rights reserved.
//

#import "ZYGImgView.h"
#import "ZYFrameBuffer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <AVFoundation/AVFoundation.h>
#import "ZYGLProgram.h"

static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
};

@interface ZYGImgView()
@property (nonatomic, assign) CGSize imgSize; // 接收的视频帧的大小
@property (nonatomic, strong) ZYGLProgram *program;
@property (nonatomic, assign) CGSize sizeInPixel;
@end
@implementation ZYGImgView {
    ZYFrameBuffer *frameBuffer;
    GLuint fboId,rboId,attrPositionIndex,attrInputTextureIndex,uniformTextureIndex;
    EAGLContext *ctx;
    CGFloat imgVertex[8];

}


#pragma mark - gl
+ (Class)layerClass {
    return [CAEAGLLayer class];
}


- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]){
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)commonInit {
    [self contextInit];
    [self programInit];
    [self genDisplayFrameBuffer];
}

- (void)contextInit{
    CAEAGLLayer *layer = self.layer;
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    ctx = context;
    [EAGLContext setCurrentContext:ctx];
    layer.opaque = YES;
    layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys
    :[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)genDisplayFrameBuffer{
    GLuint displayFbo,displayRbo;
    glGenFramebuffers(1, &displayFbo);
    glGenRenderbuffers(1, &displayRbo);
    glBindFramebuffer(GL_FRAMEBUFFER, displayFbo);
    glBindRenderbuffer(GL_RENDERBUFFER, displayRbo);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, displayRbo);

    CAEAGLLayer *layer = self.layer;
    [ctx renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];

    GLint backW,backH;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backW);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER_WIDTH, GL_RENDERBUFFER_HEIGHT, &backH);

    self.sizeInPixel.width = backW;
    self.sizeInPixel.height = backH;

    glBindFramebuffer(GL_FRAMEBUFFER, displayFbo);
    glViewport(0, 0, backW, backW);

    __unused GLuint framebufferCreationStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(framebufferCreationStatus == GL_FRAMEBUFFER_COMPLETE,
            @"Failure with display framebuffer generation for display of size: %f, %f",
            self.bounds.size.width, self.bounds.size.height);
}

- (void)programInit{
    NSString *vPath  = [[NSBundle mainBundle] pathForResource:@"ImgViewVertexShader.glsl" ofType:nil];
    NSString *fPath  = [[NSBundle mainBundle] pathForResource:@"ImgViewFragShader.glsl" ofType:nil];
    ZYGLProgram *program = [[ZYGLProgram alloc] initWithVertexShaderFile:vPath fragShaderFile:fPath];
    self.program = program;
    // 添加属性字段
    [program addAttribute:@"position"];
    [program addAttribute:@"intputTextureCoord"];

    [program link];
    if(![program validate]){
        NSLog(@" image view program faile --%@-\n-%@-\n-%@"
                ,program.programLog,program.vertexShaderLog,program.fragShaderLog);
        return;
    }

    attrPositionIndex = [program attributeIndex:@"position"];
    attrInputTextureIndex = [program attributeIndex:@"intputTextureCoord"];
    uniformTextureIndex = [program uniformIndex:@"imgTexture"];

    glEnableVertexAttribArray(attrPositionIndex);
    glEnableVertexAttribArray(attrInputTextureIndex);
}

// 根据当前的contentMode就算绘制的时候几何顶点的位置，
- (void)caculategeometry{

    CGFloat scalingW,scalingH;
    CGRect ratioRect = AVMakeRectWithAspectRatioInsideRect(self.imgSize, self.bounds);

    scalingW = ratioRect.size.width / self.bounds.size.width;
    scalingH = ratioRect.size.height / self.bounds.size.height;

    imgVertex[0] = -scalingW;
    imgVertex[1] = -scalingH;
    imgVertex[2] = scalingW;
    imgVertex[3] = -scalingH;
    imgVertex[4] = -scalingW;
    imgVertex[5] = scalingH;
    imgVertex[6] = scalingW;
    imgVertex[7] = scalingH;
}

- (void)presentFrame{
    glBindFramebuffer(GL_FRAMEBUFFER, fboId);
    [ctx presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Delegate
- (void)newFrame:(ZYFrameBuffer *)frame imgSize:(CGSize)size{
    self.imgSize = size;

    [self caculategeometry];
    [self.program use];

    //
    glBindFramebuffer(GL_FRAMEBUFFER, fboId);
    glViewport(0, 0, self.sizeInPixel.width, self.sizeInPixel.height);

    //
    glClearColor(0.1, 0.2, 0.3, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    //
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, frame.renderTextureId);
    glUniform1i(uniformTextureIndex, 4);

    glVertexAttribPointer(attrPositionIndex, 2, GL_FLOAT, 0, 0, imgVertex);
    glVertexAttribPointer(attrInputTextureIndex, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}
@end