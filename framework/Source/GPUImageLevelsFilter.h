#import "GPUImageFilter.h"

@interface GPUImageLevelsFilter : GPUImageFilter
{
    GLint minUniform;
    GLint midUniform;
    GLint maxUniform;
    GLint minOutputUniform;
    GLint maxOutputUniform;
    
    GPUVector3 minVector, midVector, maxVector, minOutputVector, maxOutputVector;
}

- (void)setRedMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut;
- (void)setGreenMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut;
- (void)setBlueMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut;

- (void)setRedMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max;
- (void)setGreenMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max;
- (void)setBlueMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max;

- (void)setMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut;
- (void)setMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max;

@end

