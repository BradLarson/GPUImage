// 2448x3264 pixel image = 31,961,088 bytes for uncompressed RGBA

#import "GPUImageStillCamera.h"

@interface GPUImageStillCamera ()
{
    AVCaptureStillImageOutput *photoOutput;
}

@end

@implementation GPUImageStillCamera

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack]))
    {
		return nil;
    }
    
    [self.captureSession beginConfiguration];

    photoOutput = [[AVCaptureStillImageOutput alloc] init];
    [photoOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    [self.captureSession addOutput:photoOutput];
    
    [self.captureSession commitConfiguration];

    return self;
}

- (void)removeInputsAndOutputs;
{
    [self.captureSession removeOutput:photoOutput];
    [super removeInputsAndOutputs];
}

#pragma mark -
#pragma mark Photography controls

- (void)capturePhotoAsImageProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(UIImage *processedImage, NSError *error))block;
{
    [photoOutput captureStillImageAsynchronouslyFromConnection:[[photoOutput connections] objectAtIndex:0] completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {

        [self captureOutput:photoOutput didOutputSampleBuffer:imageSampleBuffer fromConnection:[[photoOutput connections] objectAtIndex:0]];

        UIImage *filteredPhoto = [finalFilterInChain imageFromCurrentlyProcessedOutput];
        
        block(filteredPhoto, error);        
    }];
    
    return;
}

- (void)capturePhotoAsJPEGProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(NSData *processedJPEG, NSError *error))block;
{
//    report_memory(@"Before still image capture");
    [photoOutput captureStillImageAsynchronouslyFromConnection:[[photoOutput connections] objectAtIndex:0] completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
//        report_memory(@"Before filter processing");
        
        [self captureOutput:photoOutput didOutputSampleBuffer:imageSampleBuffer fromConnection:[[photoOutput connections] objectAtIndex:0]];
//        report_memory(@"After filter processing");
        
        NSData *dataForJPEGFile = nil;
        @autoreleasepool {
            UIImage *filteredPhoto = [finalFilterInChain imageFromCurrentlyProcessedOutput];
            
//            report_memory(@"After UIImage generation");

            dataForJPEGFile = UIImageJPEGRepresentation(filteredPhoto, 0.8);
//            report_memory(@"After JPEG generation");
        }

//        report_memory(@"After autorelease pool");

        block(dataForJPEGFile, error);        
    }];
    
    return;
}

- (void)capturePhotoAsPNGProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(NSData *processedPNG, NSError *error))block;
{
    [photoOutput captureStillImageAsynchronouslyFromConnection:[[photoOutput connections] objectAtIndex:0] completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        [self captureOutput:photoOutput didOutputSampleBuffer:imageSampleBuffer fromConnection:[[photoOutput connections] objectAtIndex:0]];
        
        NSData *dataForPNGFile = nil;
        @autoreleasepool { 
            UIImage *filteredPhoto = [finalFilterInChain imageFromCurrentlyProcessedOutput];
            dataForPNGFile = UIImagePNGRepresentation(filteredPhoto);
        }
        
        block(dataForPNGFile, error);        
    }];
    
    return;
}


@end
