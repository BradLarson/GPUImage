#import "GPUImageFilter.h"

@interface GPUImageZoomBlurFilter : GPUImageFilter

/** A multiplier for the blur size, ranging from 0.0 on up, with a default of 1.0
 */
@property (readwrite, nonatomic) CGFloat blurSize;

/** The normalized center of the blur. (0.5, 0.5) by default
 */
@property (readwrite, nonatomic) CGPoint blurCenter;

@end
