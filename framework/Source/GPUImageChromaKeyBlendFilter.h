#import "GPUImageFilter.h"

@interface GPUImageChromaKeyBlendFilter : GPUImageFilter
{
    GLint colorToReplaceUniform, thresholdSensitivityUniform, smoothingUniform;
}

// The threshold sensitivity controls how similar pixels need to be colored to be replaced, default of 0.3
@property(readwrite, nonatomic) GLfloat thresholdSensitivity;

// The degree of smoothing controls how gradually similar colors are replaced in the image, default of 0.1
@property(readwrite, nonatomic) GLfloat smoothing;

// The color to be replaced is specified using individual red, green, and blue components (normalized to 1.0). The default is green: (0.0, 1.0, 0.0).
- (void)setColorToReplaceRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;

@end
