//
//  GPUImageVibranceFilter.h
//
//
//  Created by github.com/r3mus on 8/14/15.
//
//

#import <GPUImage/GPUImage.h>

@interface GPUImageVibranceFilter : GPUImageFilter
{
    GLint vibranceUniform;
}

// Modifies the saturation of desaturated colors, leaving saturated colors unmodified.
// Value -1 to 1 (-1 is minimum vibrance, 0 is no change, and 1 is maximum vibrance)
@property (readwrite, nonatomic) GLfloat vibrance;

@end
