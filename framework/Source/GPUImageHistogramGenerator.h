#import "GPUImageFilter.h"

@interface GPUImageHistogramGenerator : GPUImageFilter
{
    GLint colorForGraphUniform;
}

// The color for the graph, in individual red, green, and blue components (normalized to 1.0). The default is white: (1.0, 1.0, 1.0).
- (void)setColorForGraphRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;

@end
