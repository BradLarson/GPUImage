#import "GPUImageFilterGroup.h"

@class GPUImageGaussianBlurFilter;
@class GPUImageXYDerivativeFilter;
@class GPUImageGrayscaleFilter;
@class GPUImageFastBlurFilter;
@class GPUImageNonMaximumSuppressionFilter;

/** Harris corner detector
 
 First pass: reduce to luminance and take the derivative of the luminance texture (GPUImageXYDerivativeFilter)
 
 Second pass: blur the derivative (GPUImageFastBlurFilter)
 
 Third pass: apply the Harris corner detection calculation
 
 This is the Harris corner detector, as described in 
 C. Harris and M. Stephens. A Combined Corner and Edge Detector. Proc. Alvey Vision Conf., Univ. Manchester, pp. 147-151, 1988.
 */
@interface GPUImageHarrisCornerDetectionFilter : GPUImageFilterGroup
{
    GPUImageXYDerivativeFilter *derivativeFilter;
//    GPUImageGaussianBlurFilter *blurFilter;
    GPUImageFastBlurFilter *preblurFilter, *blurFilter;
    GPUImageFilter *harrisCornerDetectionFilter;
    GPUImageNonMaximumSuppressionFilter *nonMaximumSuppressionFilter;
    GPUImageFilter *simpleThresholdFilter;
    GLfloat *cornersArray;
    GLubyte *rawImagePixels;
}

/** A multiplier for the underlying blur size, ranging from 0.0 on up, with a default of 1.0
 */
@property(readwrite, nonatomic) CGFloat blurSize;

// This changes the dynamic range of the Harris corner detector by amplifying small cornerness values. Default is 10.0.
@property(readwrite, nonatomic) CGFloat sensitivity;

// A threshold value at which a point is recognized as being a corner after the non-maximum suppression. Default is 0.05.
@property(readwrite, nonatomic) CGFloat threshold;

// This block is called on the detection of new corner points, usually on every processed frame. A C array containing normalized coordinates in X, Y pairs is passed in, along with a count of the number of corners detected
@property(nonatomic, copy) void(^cornersDetectedBlock)(GLfloat* cornerArray, NSUInteger cornersDetected);

// Initialization and teardown
- (id)initWithCornerDetectionFragmentShader:(NSString *)cornerDetectionFragmentShader;

@end
