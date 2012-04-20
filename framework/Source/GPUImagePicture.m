#import "GPUImagePicture.h"

@implementation GPUImagePicture

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithImage:(UIImage *)newImageSource;
{
    if (!(self = [self initWithImage:newImageSource smoothlyScaleOutput:NO]))
    {
		return nil;
    }
    
    return self;
}

- (id)initWithImage:(UIImage *)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    self.shouldSmoothlyScaleOutput = smoothlyScaleOutput;
    imageSource = newImageSource;

    [GPUImageOpenGLESContext useImageProcessingContext];

    CGSize pointSizeOfImage = [imageSource size];
    CGFloat scaleOfImage = [imageSource scale];
    CGSize pixelSizeOfImage = CGSizeMake(scaleOfImage * pointSizeOfImage.width, scaleOfImage * pointSizeOfImage.height);

    BOOL shouldRedrawUsingCoreGraphics = YES;
    if (self.shouldSmoothlyScaleOutput)
    {
        // In order to use mipmaps, you need to provide power-of-two textures, so convert to the next largest power of two and stretch to fill
        CGFloat powerClosestToWidth = ceil(log2(pixelSizeOfImage.width));
        CGFloat powerClosestToHeight = ceil(log2(pixelSizeOfImage.height));
        
        pixelSizeOfImage = CGSizeMake(pow(2.0, powerClosestToWidth), pow(2.0, powerClosestToHeight));
        
        shouldRedrawUsingCoreGraphics = YES;
    }

    GLubyte *imageData = NULL;
    CFDataRef dataFromImageDataProvider;

//    CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();

    if (shouldRedrawUsingCoreGraphics)
    {
        // For resized image, redraw
        imageData = (GLubyte *) calloc(1, (int)pixelSizeOfImage.width * (int)pixelSizeOfImage.height * 4);
        
        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();    
        CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)pixelSizeOfImage.width, (int)pixelSizeOfImage.height, 8, (int)pixelSizeOfImage.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, pixelSizeOfImage.width, pixelSizeOfImage.height), [newImageSource CGImage]);
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
    }
    else
    {
        // Access the raw image bytes directly
        dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider([newImageSource CGImage]));
        imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    }    
    
//    elapsedTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0;
//    NSLog(@"Core Graphics drawing time: %f", elapsedTime);

    glBindTexture(GL_TEXTURE_2D, outputTexture);
    if (self.shouldSmoothlyScaleOutput)
    {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    }
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)pixelSizeOfImage.width, (int)pixelSizeOfImage.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);
    
    if (self.shouldSmoothlyScaleOutput)
    {
        glGenerateMipmap(GL_TEXTURE_2D);
    }

    if (shouldRedrawUsingCoreGraphics)
    {
        free(imageData);
    }
    else
    {
        CFRelease(dataFromImageDataProvider);
    }
    
    return self;
}

#pragma mark -
#pragma mark Image rendering

- (void)processImage;
{
    CGSize pointSizeOfImage = [imageSource size];
    CGFloat scaleOfImage = [imageSource scale];
    CGSize pixelSizeOfImage = CGSizeMake(scaleOfImage * pointSizeOfImage.width, scaleOfImage * pointSizeOfImage.height);
    
    for (id<GPUImageInput> currentTarget in targets)
    {
        [currentTarget setInputSize:pixelSizeOfImage];
        [currentTarget newFrameReadyAtTime:kCMTimeInvalid];
    }    
}

@end
