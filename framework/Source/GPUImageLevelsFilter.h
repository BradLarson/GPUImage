#import "GPUImageFilter.h"

@interface GPUImageLevelsFilter : GPUImageFilter
{
    GLint redUniform;
    GLint greenUniform;
    GLint blueUniform;
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

