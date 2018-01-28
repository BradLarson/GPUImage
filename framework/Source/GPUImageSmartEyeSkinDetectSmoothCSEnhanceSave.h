#import <Foundation/Foundation.h>
#import "GPUImageTwoInputFilter.h"

@interface GPUImageSmartEyeSkinDetectSmoothCSEnhanceSave : GPUImageTwoInputFilter
{
    GLint mLevelUniform;
    GLint sLevelUniform;
    GLint mXStepUniform;
    GLint mYStepUniform;
    GLint contrastRatio_10bitUniform;
    GLint contrastKeyPointUniform;
    GLint saturationRatio_10bitUniform;
}

@property(readwrite,nonatomic) CGFloat mLevel;
@property(readwrite,nonatomic) CGFloat sLevel;
@property(readwrite,nonatomic) CGFloat mXStep;
@property(readwrite,nonatomic) CGFloat mYStep;
@property(readwrite,nonatomic) CGFloat contrastRatio_10bit;
@property(readwrite,nonatomic) CGFloat contrastKeyPoint;
@property(readwrite,nonatomic) CGFloat saturationRatio_10bit;

@end