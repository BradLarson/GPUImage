#import "GPUImagePicture.h"

@implementation GPUImagePicture

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithImage:(UIImage *)newImageSource;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    imageSource = newImageSource;

    [GPUImageOpenGLESContext useImageProcessingContext];

    CGSize pointSizeOfImage = [imageSource size];
    CGFloat scaleOfImage = [imageSource scale];
    CGSize pixelSizeOfImage = CGSizeMake(scaleOfImage * pointSizeOfImage.width, scaleOfImage * pointSizeOfImage.height);

    GLubyte *imageData = (GLubyte *) malloc((int)pixelSizeOfImage.width * (int)pixelSizeOfImage.height * 4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();    
    
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)pixelSizeOfImage.width, (int)pixelSizeOfImage.height, 8, (int)pixelSizeOfImage.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)pixelSizeOfImage.width, (int)pixelSizeOfImage.height, 8, (int)pixelSizeOfImage.width * 4, genericRGBColorspace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, pixelSizeOfImage.width, pixelSizeOfImage.height), [newImageSource CGImage]);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    glBindTexture(GL_TEXTURE_2D, outputTexture);
	// Using BGRA extension to pull in video frame data directly
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)pixelSizeOfImage.width, (int)pixelSizeOfImage.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);

    free(imageData);
    
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
        [currentTarget newFrameReady];
    }
}

@end
