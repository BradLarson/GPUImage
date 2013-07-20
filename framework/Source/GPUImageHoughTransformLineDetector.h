#import "GPUImageFilterGroup.h"
#import "GPUImageThresholdEdgeDetectionFilter.h"
#import "GPUImageParallelCoordinateLineTransformFilter.h"
#import "GPUImageThresholdedNonMaximumSuppressionFilter.h"
#import "GPUImageCannyEdgeDetectionFilter.h"
#import "GPUImageFastBlurFilter.h"

// This applies a Hough transform to detect lines in a scene. It starts with a thresholded Sobel edge detection pass,
// then takes those edge points in and applies a Hough transform to convert them to lines. The intersection of these lines
// is then determined via blending and accumulation, and a non-maximum suppression filter is applied to find local maxima.
// These local maxima are then converted back into lines in normal space and returned via a callback block.
//
// Rather than using one of the standard Hough transform types, this filter uses parallel coordinate space which is far more efficient
// to rasterize on a GPU.
//
// This approach is based entirely on the PC lines process developed by the Graph@FIT research group at the Brno University of Technology
// and described in their publications:
//
// M. Dubská, J. Havel, and A. Herout. Real-Time Detection of Lines using Parallel Coordinates and OpenGL. Proceedings of SCCG 2011, Bratislava, SK, p. 7.
// http://medusa.fit.vutbr.cz/public/data/papers/2011-SCCG-Dubska-Real-Time-Line-Detection-Using-PC-and-OpenGL.pdf
// M. Dubská, J. Havel, and A. Herout. PClines — Line detection using parallel coordinates. 2011 IEEE Conference on Computer Vision and Pattern Recognition (CVPR), p. 1489- 1494.
// http://medusa.fit.vutbr.cz/public/data/papers/2011-CVPR-Dubska-PClines.pdf

//#define DEBUGLINEDETECTION

@interface GPUImageHoughTransformLineDetector : GPUImageFilterGroup
{
    GPUImageOutput<GPUImageInput> *thresholdEdgeDetectionFilter;
    
//    GPUImageThresholdEdgeDetectionFilter *thresholdEdgeDetectionFilter;
    GPUImageParallelCoordinateLineTransformFilter *parallelCoordinateLineTransformFilter;
    GPUImageThresholdedNonMaximumSuppressionFilter *nonMaximumSuppressionFilter;
    
    GLfloat *linesArray;
    GLubyte *rawImagePixels;
}

// A threshold value for which a point is detected as belonging to an edge for determining lines. Default is 0.9.
@property(readwrite, nonatomic) CGFloat edgeThreshold;

// A threshold value for which a local maximum is detected as belonging to a line in parallel coordinate space. Default is 0.20.
@property(readwrite, nonatomic) CGFloat lineDetectionThreshold;

// This block is called on the detection of lines, usually on every processed frame. A C array containing normalized slopes and intercepts in m, b pairs (y=mx+b) is passed in, along with a count of the number of lines detected and the current timestamp of the video frame
@property(nonatomic, copy) void(^linesDetectedBlock)(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime);

// These images are only enabled when built with DEBUGLINEDETECTION defined, and are used to examine the intermediate states of the Hough transform
@property(nonatomic, readonly, strong) NSMutableArray *intermediateImages;

@end
