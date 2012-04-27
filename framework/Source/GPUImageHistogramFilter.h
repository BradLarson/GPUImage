#import "GPUImageFilter.h"

typedef enum { kGPUImageHistogramRed, kGPUImageHistogramGreen, kGPUImageHistogramBlue, kGPUImageHistogramLuminance} GPUImageHistogramType;

@interface GPUImageHistogramFilter : GPUImageFilter
{
    GPUImageHistogramType histogramType;
    
    GLfloat *vertexSamplingCoordinates, *textureSamplingCoordinates;
    GLint scalingFactorUniform;
}

// These properties control the density of the grid overlaid on the image which is used to sample the colors for the histogram. By default, this is set to 100 in either direction
@property(readwrite, nonatomic) NSUInteger samplingDensityInX, samplingDensityInY;

// This dictates the scaling of the histogram heights. By default this is 0.004 (1/255)
@property(readwrite, nonatomic) CGFloat scalingFactor;

// Rather than sampling every pixel, this dictates what fraction of the image is sampled. By default, this is 8 with a minimum of 1.
@property(readwrite, nonatomic) NSUInteger downsamplingFactor;

// Initialization and teardown
- (id)initWithHistogramType:(GPUImageHistogramType)newHistogramType;

// Rendering
- (void)generatePointCoordinates;

@end
