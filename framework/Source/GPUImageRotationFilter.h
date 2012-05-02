#import "GPUImageFilter.h"

typedef enum { kGPUImageRotateLeft, kGPUImageRotateRight, kGPUImageFlipVertical, kGPUImageFlipHorizonal, kGPUImageRotateRightFlipVertical} GPUImageRotationMode;

@interface GPUImageRotationFilter : GPUImageFilter
{
    GPUImageRotationMode rotationMode;
}

// Initialization and teardown
- (id)initWithRotation:(GPUImageRotationMode)newRotationMode;

@end
