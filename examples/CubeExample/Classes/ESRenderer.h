#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

@protocol ESRenderer <NSObject>

- (void)renderByRotatingAroundX:(float)xRotation rotatingAroundY:(float)yRotation;

@end
