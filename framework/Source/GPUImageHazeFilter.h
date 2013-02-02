#import "GPUImageFilter.h"

/*
 * The haze filter can be used to add or remove haze (similar to a UV filter)
 * 
 * @author Alaric Cole
 * @creationDate 03/10/12
 *
 */

/** The haze filter can be used to add or remove haze
 
 This is similar to a UV filter
 */
@interface GPUImageHazeFilter : GPUImageFilter
{
    GLint distanceUniform;
	GLint slopeUniform;
}

/** Strength of the color applied. Default 0. Values between -.3 and .3 are best
 */
@property(readwrite, nonatomic) CGFloat distance; 

/** Amount of color change. Default 0. Values between -.3 and .3 are best
 */
@property(readwrite, nonatomic) CGFloat slope;

@end
