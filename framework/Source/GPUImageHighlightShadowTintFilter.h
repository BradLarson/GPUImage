//
//  GPUImageHighlightShadowTintFilter.h
//
//
//  Created by github.com/r3mus on 8/14/15.
//
//

#import "GPUImageFilter.h"

@interface GPUImageHighlightShadowTintFilter : GPUImageFilter
{
    GLint shadowTintIntensityUniform, highlightTintIntensityUniform, shadowTintColorUniform, highlightTintColorUniform;
}

// The shadowTint and highlightTint colors specify what colors replace the dark and light areas of the image, respectively. The defaults for shadows are black, highlighs white.
@property(readwrite, nonatomic) GLfloat shadowTintIntensity;
@property(readwrite, nonatomic) GPUVector4 shadowTintColor;
@property(readwrite, nonatomic) GLfloat highlightTintIntensity;
@property(readwrite, nonatomic) GPUVector4 highlightTintColor;

- (void)setShadowTintColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
- (void)setHighlightTintColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;

@end
