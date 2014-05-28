//
//  GPUImagePicture+TextureSubimage.m
//  GPUImage
//
//  Created by Jack Wu on 2014-05-28.
//  Copyright (c) 2014 Brad Larson. All rights reserved.
//

#import "GPUImagePicture+TextureSubimage.h"

@implementation GPUImagePicture (TextureSubimage)

- (void)replaceTextureWithSubimage:(UIImage*)subimage {
    return [self replaceTextureWithSubCGImage:[subimage CGImage]];
}

- (void)replaceTextureWithSubCGImage:(CGImageRef)subimageSource {
    CGRect rect = (CGRect) {.origin = CGPointZero, .size = (CGSize){.width = CGImageGetWidth(subimageSource), .height = CGImageGetHeight(subimageSource)}};
    return [self replaceTextureWithSubCGImage:subimageSource inRect:rect];
}

- (void)replaceTextureWithSubimage:(UIImage*)subimage inRect:(CGRect)subRect {
    return [self replaceTextureWithSubCGImage:[subimage CGImage] inRect:subRect];
}

- (void)replaceTextureWithSubCGImage:(CGImageRef)subimageSource inRect:(CGRect)subRect {
    NSAssert(outputFramebuffer, @"Picture must be initialized first before replacing subtexture");
    NSAssert(self.framebufferForOutput.textureOptions.internalFormat == GL_RGBA, @"For replacing subtexture the internal texture format must be GL_RGBA.");

    CGRect subimageRect = (CGRect){.origin = CGPointZero, .size = (CGSize){.width = CGImageGetWidth(subimageSource), .height = CGImageGetHeight(subimageSource)}};
    NSAssert(!CGRectIsEmpty(subimageRect), @"Passed sub image must not be empty - it should be at least 1px tall and wide");
    NSAssert(!CGRectIsEmpty(subRect), @"Passed sub rect must not be empty");

    NSAssert(CGSizeEqualToSize(subimageRect.size, subRect.size), @"Subimage size must match the size of sub rect");
    
    // We don't have to worry about scaling the subimage or finding a power of two size.
    // The initialization has taken care of that for us.
    
    dispatch_semaphore_signal(imageUpdateSemaphore);

    BOOL shouldRedrawUsingCoreGraphics = NO;

    // Since internal format is always RGBA, we need the input data in RGBA as well.
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(subimageSource);
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    if (byteOrderInfo != kCGBitmapByteOrderDefault && byteOrderInfo != kCGBitmapByteOrder32Big) {
        shouldRedrawUsingCoreGraphics = YES;
    }
    else {
        CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
        if (alphaInfo != kCGImageAlphaPremultipliedLast && alphaInfo != kCGImageAlphaLast && alphaInfo != kCGImageAlphaNoneSkipLast) {
            shouldRedrawUsingCoreGraphics = YES;
        }
    }

    GLubyte *imageData = NULL;
    CFDataRef dataFromImageDataProvider;
    if (shouldRedrawUsingCoreGraphics)
    {
        // For resized or incompatible image: redraw
        imageData = (GLubyte *) calloc(1, (int)subimageRect.size.width * (int)subimageRect.size.height * 4);
        
        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef imageContext = CGBitmapContextCreate(imageData, (size_t)subimageRect.size.width, (size_t)subimageRect.size.height, 8, (size_t)subimageRect.size.width * 4, genericRGBColorspace,  kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
        
        CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, subimageRect.size.width, subimageRect.size.height), subimageSource);
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
    }
    else
    {
        // Access the raw image bytes directly
        dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(subimageSource));
        imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        [outputFramebuffer disableReferenceCounting];
        
        glBindTexture(GL_TEXTURE_2D, [outputFramebuffer texture]);
        
        // no need to use self.outputTextureOptions here since pictures need this texture formats and type
        glTexSubImage2D(GL_TEXTURE_2D, 0, subRect.origin.x, subRect.origin.y, (GLint)subRect.size.width, subRect.size.height, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
        
        if (self.shouldSmoothlyScaleOutput)
        {
            glGenerateMipmap(GL_TEXTURE_2D);
        }
        glBindTexture(GL_TEXTURE_2D, 0);
    });

    if (shouldRedrawUsingCoreGraphics)
    {
        free(imageData);
    }
    else
    {
        CFRelease(dataFromImageDataProvider);
    }
}
@end
