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

- (id)initWithCGImage:(CGImageRef)newImageSource;
{
    if (!(self = [self initWithCGImage:newImageSource smoothlyScaleOutput:NO]))
    {
		return nil;
    }
    return self;
}

- (id)initWithImage:(UIImage *)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;
{
    return [self initWithCGImage:[newImageSource CGImage] smoothlyScaleOutput:smoothlyScaleOutput];
}

- (id)initWithCGImage:(CGImageRef)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    self.shouldSmoothlyScaleOutput = smoothlyScaleOutput;
        
    // TODO: Dispatch this whole thing asynchronously to move image loading off main thread
    CGFloat widthOfImage = CGImageGetWidth(newImageSource);
    CGFloat heightOfImage = CGImageGetHeight(newImageSource);
    pixelSizeOfImage = CGSizeMake(widthOfImage, heightOfImage);
    CGSize pixelSizeToUseForTexture = pixelSizeOfImage;

    BOOL shouldRedrawUsingCoreGraphics = YES;
    
    // For now, deal with images larger than the maximum texture size by resizing to be within that limit
    CGSize scaledImageSizeToFitOnGPU = [GPUImageOpenGLESContext sizeThatFitsWithinATextureForSize:pixelSizeOfImage];
    if (!CGSizeEqualToSize(scaledImageSizeToFitOnGPU, pixelSizeOfImage))
    {
        pixelSizeOfImage = scaledImageSizeToFitOnGPU;
        pixelSizeToUseForTexture = pixelSizeOfImage;
        shouldRedrawUsingCoreGraphics = YES;
    }
    
    if (self.shouldSmoothlyScaleOutput)
    {
        // In order to use mipmaps, you need to provide power-of-two textures, so convert to the next largest power of two and stretch to fill
        CGFloat powerClosestToWidth = ceil(log2(pixelSizeOfImage.width));
        CGFloat powerClosestToHeight = ceil(log2(pixelSizeOfImage.height));
        
        pixelSizeToUseForTexture = CGSizeMake(pow(2.0, powerClosestToWidth), pow(2.0, powerClosestToHeight));
        
        shouldRedrawUsingCoreGraphics = YES;
    }

    GLubyte *imageData = NULL;
    CFDataRef dataFromImageDataProvider;

//    CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();

    if (shouldRedrawUsingCoreGraphics)
    {
        // For resized image, redraw
        imageData = (GLubyte *) calloc(1, (int)pixelSizeToUseForTexture.width * (int)pixelSizeToUseForTexture.height * 4);
        
        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();    
        CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)pixelSizeToUseForTexture.width, (int)pixelSizeToUseForTexture.height, 8, (int)pixelSizeToUseForTexture.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//        CGContextSetBlendMode(imageContext, kCGBlendModeCopy); // From Technical Q&A QA1708: http://developer.apple.com/library/ios/#qa/qa1708/_index.html
        CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, pixelSizeToUseForTexture.width, pixelSizeToUseForTexture.height), newImageSource);
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
    }
    else
    {
        // Access the raw image bytes directly
        dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(newImageSource));
        imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    }    
    
//    elapsedTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0;
//    NSLog(@"Core Graphics drawing time: %f", elapsedTime);

//    CGFloat currentRedTotal = 0.0f, currentGreenTotal = 0.0f, currentBlueTotal = 0.0f, currentAlphaTotal = 0.0f;
//	NSUInteger totalNumberOfPixels = round(pixelSizeToUseForTexture.width * pixelSizeToUseForTexture.height);
//    
//    for (NSUInteger currentPixel = 0; currentPixel < totalNumberOfPixels; currentPixel++)
//    {
//        currentBlueTotal += (CGFloat)imageData[(currentPixel * 4)] / 255.0f;
//        currentGreenTotal += (CGFloat)imageData[(currentPixel * 4) + 1] / 255.0f;
//        currentRedTotal += (CGFloat)imageData[(currentPixel * 4 + 2)] / 255.0f;
//        currentAlphaTotal += (CGFloat)imageData[(currentPixel * 4) + 3] / 255.0f;
//    }
//    
//    NSLog(@"Debug, average input image red: %f, green: %f, blue: %f, alpha: %f", currentRedTotal / (CGFloat)totalNumberOfPixels, currentGreenTotal / (CGFloat)totalNumberOfPixels, currentBlueTotal / (CGFloat)totalNumberOfPixels, currentAlphaTotal / (CGFloat)totalNumberOfPixels);
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];
        
        glBindTexture(GL_TEXTURE_2D, outputTexture);
        if (self.shouldSmoothlyScaleOutput)
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        }
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)pixelSizeToUseForTexture.width, (int)pixelSizeToUseForTexture.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);
        
        if (self.shouldSmoothlyScaleOutput)
        {
            glGenerateMipmap(GL_TEXTURE_2D);
        }        
    });

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
    hasProcessedImage = YES;
  
    dispatch_async([GPUImageOpenGLESContext sharedOpenGLESQueue], ^{
        for (id<GPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [currentTarget setInputSize:pixelSizeOfImage atIndex:textureIndexOfTarget];
            [currentTarget newFrameReadyAtTime:kCMTimeIndefinite atIndex:textureIndexOfTarget];
        }    
    });
}

- (CGSize)outputImageSize;
{
    return pixelSizeOfImage;
}

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    [super addTarget:newTarget atTextureLocation:textureLocation];

    if (hasProcessedImage)
    {
        [newTarget setInputSize:pixelSizeOfImage atIndex:textureLocation];
        [newTarget newFrameReadyAtTime:kCMTimeIndefinite atIndex:textureLocation];
    }
}

@end
