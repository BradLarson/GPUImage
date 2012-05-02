#import "GPUImageVideoCamera.h"

@interface GPUImageStillCamera : GPUImageVideoCamera

// Photography controls
- (void)capturePhotoProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(UIImage *processedImage, NSError *error))block;

@end
