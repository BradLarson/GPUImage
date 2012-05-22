#import "GPUImageFilterGroup.h"

@interface GPUImageAdaptiveThresholdFilter : GPUImageFilterGroup

/** A multiplier for the background averaging blur size, ranging from 0.0 on up, with a default of 1.0
 */
@property(readwrite, nonatomic) CGFloat blurSize;

@end
