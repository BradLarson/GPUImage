#import "GPUImageFilter.h"
/**
 * Created by Alaric Cole
 * Allows adjustment of color temperature in terms of what an image was effectively shot in. This means higher Kelvin values will warm the image, while lower values will cool it. 
 
 */
@interface GPUImageWhiteBalanceFilter : GPUImageFilter
{
    GLint temperatureUniform, tintUniform;
}
// Choose color temperature, in degrees Kelvin
@property(readwrite, nonatomic) CGFloat temperature;

// Adjust tint to compensate
@property(readwrite, nonatomic) CGFloat tint;

@end
