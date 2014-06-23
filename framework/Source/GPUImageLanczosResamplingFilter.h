#import "GPUImageTwoPassTextureSamplingFilter.h"

@interface GPUImageLanczosResamplingFilter : GPUImageTwoPassTextureSamplingFilter

@property(readwrite, nonatomic) CGSize originalImageSize;

@end
