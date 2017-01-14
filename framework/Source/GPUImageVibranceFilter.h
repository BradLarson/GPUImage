//
//  GPUImageVibranceFilter.h
//
//
//  Created by github.com/r3mus on 8/14/15.
//
//

#import "GPUImageFilter.h"

@interface GPUImageVibranceFilter : GPUImageFilter
{
    GLint vibranceUniform;
}

// Modifies the saturation of desaturated colors, leaving saturated colors unmodified.
// Value -1.2 to 1.2 (-1.2 is minimum vibrance, 0 is no change, and 1.2 is maximum vibrance)
@property (readwrite, nonatomic) CGFloat vibrance;

@end
