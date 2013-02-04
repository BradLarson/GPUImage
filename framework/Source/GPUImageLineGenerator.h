#import "GPUImageFilter.h"

@interface GPUImageLineGenerator : GPUImageFilter
{
    GLint lineWidthUniform, lineColorUniform;
    GLfloat *lineCoordinates;
}

// The width of the displayed lines, in pixels. The default is 1.
@property(readwrite, nonatomic) CGFloat lineWidth;

// The color of the lines is specified using individual red, green, and blue components (normalized to 1.0). The default is green: (0.0, 1.0, 0.0).
- (void)setLineColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;

// Rendering
- (void)renderLinesFromArray:(GLfloat *)lineSlopeAndIntercepts count:(NSUInteger)numberOfLines frameTime:(CMTime)frameTime;

@end
