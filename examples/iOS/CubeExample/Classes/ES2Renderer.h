#import "ESRenderer.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImage.h"

@class PVRTexture;

@interface ES2Renderer : NSObject <ESRenderer, GPUImageTextureOutputDelegate>
{
@private
    EAGLContext *context;

	GLuint textureForCubeFace, outputTexture;
    
    // The pixel dimensions of the CAEAGLLayer
    GLint backingWidth;
    GLint backingHeight;

    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view
    GLuint defaultFramebuffer, colorRenderbuffer, depthBuffer;

	CATransform3D currentCalculatedMatrix;

    GLuint program;
    
    GPUImageVideoCamera *videoCamera;
    GPUImageFilter *inputFilter, *outputFilter;
    GPUImageTextureOutput *textureOutput;

}

@property(readonly) GLuint outputTexture;
@property(nonatomic, copy) void(^newFrameAvailableBlock)(void);

- (id)initWithSize:(CGSize)newSize;

- (void)renderByRotatingAroundX:(float)xRotation rotatingAroundY:(float)yRotation;
- (void)convert3DTransform:(CATransform3D *)transform3D toMatrix:(GLfloat *)matrix;
- (void)startCameraCapture;

@end

