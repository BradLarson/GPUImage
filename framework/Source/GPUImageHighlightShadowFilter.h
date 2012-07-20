#import "GPUImageFilter.h"

/**
 * This is an attempt to replicate CIHighlightShadowAdjust
 * 
 * 
 * @author Alaric Cole
 * @creationDate 07/10/12
 *
 */


@interface GPUImageHighlightShadowFilter : GPUImageFilter
{
    GLint shadowsUniform, highlightsUniform;
}

/**
 * 0 - 1, increase to lighten shadows.
 * @default 0
 */
@property(readwrite, nonatomic) CGFloat shadows;

/**
 * 0 - 1, decrease to darken highlights.
 * @default 1
 */
@property(readwrite, nonatomic) CGFloat highlights;

@end
