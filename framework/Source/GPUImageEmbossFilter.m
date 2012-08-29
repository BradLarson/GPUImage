#import "GPUImageEmbossFilter.h"

@implementation GPUImageEmbossFilter

@synthesize intensity = _intensity; 

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    self.intensity = 1.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setIntensity:(CGFloat)newValue;
{
//    [(GPUImage3x3ConvolutionFilter *)filter setConvolutionMatrix:(GPUMatrix3x3){
//        {-2.0f, -1.0f, 0.0f},
//        {-1.0f,  1.0f, 1.0f},
//        { 0.0f,  1.0f, 2.0f}
//    }];
    
    _intensity = newValue;
    
    GPUMatrix3x3 newConvolutionMatrix;
    newConvolutionMatrix.one.one = _intensity * (-2.0);
    newConvolutionMatrix.one.two = -_intensity;    
    newConvolutionMatrix.one.three = 0.0f;

    newConvolutionMatrix.two.one = -_intensity;
    newConvolutionMatrix.two.two = 1.0;    
    newConvolutionMatrix.two.three = _intensity;
    
    newConvolutionMatrix.three.one = 0.0f;
    newConvolutionMatrix.three.two = _intensity;    
    newConvolutionMatrix.three.three = _intensity * 2.0;

    self.convolutionKernel = newConvolutionMatrix;
}


@end
