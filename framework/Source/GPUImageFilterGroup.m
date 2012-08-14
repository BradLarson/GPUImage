#import "GPUImageFilterGroup.h"
#import "GPUImagePicture.h"

@implementation GPUImageFilterGroup

@synthesize terminalFilter = _terminalFilter;
@synthesize initialFilters = _initialFilters;
@synthesize inputFilterToIgnoreForUpdates = _inputFilterToIgnoreForUpdates;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    filters = [[NSMutableArray alloc] init];
    
    [self deleteOutputTexture];
    
    return self;
}

#pragma mark -
#pragma mark Filter management

- (void)addFilter:(GPUImageOutput<GPUImageInput> *)newFilter;
{
    [filters addObject:newFilter];
}

- (GPUImageOutput<GPUImageInput> *)filterAtIndex:(NSUInteger)filterIndex;
{
    return [filters objectAtIndex:filterIndex];
}

- (int)filterCount;
{
    return [filters count];
}

#pragma mark -
#pragma mark Still image processing

- (UIImage *)imageFromCurrentlyProcessedOutputWithOrientation:(UIImageOrientation)imageOrientation;
{
    return [self.terminalFilter imageFromCurrentlyProcessedOutputWithOrientation:imageOrientation];
}

- (CGImageRef)newCGImageFromCurrentlyProcessedOutputWithOrientation:(UIImageOrientation)imageOrientation;
{
    return [self.terminalFilter newCGImageFromCurrentlyProcessedOutputWithOrientation:imageOrientation];
}

- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter;
{
    return [self.terminalFilter imageByFilteringImage:imageToFilter];
//    CGImageRef image = [self newCGImageByFilteringCGImage:[imageToFilter CGImage]];
//    UIImage *processedImage = [UIImage imageWithCGImage:image];
//    CGImageRelease(image);
//    return processedImage;
}

- (CGImageRef)newCGImageByFilteringImage:(UIImage *)imageToFilter;
{
    return [self.terminalFilter newCGImageByFilteringImage:imageToFilter];
//    
//    return [self newCGImageByFilteringCGImage:[imageToFilter CGImage]];
}

- (CGImageRef)newCGImageByFilteringCGImage:(CGImageRef)imageToFilter;
{
    return [self.terminalFilter newCGImageByFilteringCGImage:imageToFilter];
//    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithCGImage:imageToFilter];
//    
//    [stillImageSource addTarget:self];
//    [stillImageSource processImage];
//    
//    CGImageRef processedImage = [self.terminalFilter newCGImageFromCurrentlyProcessedOutput];
//    
//    [stillImageSource removeTarget:self];
//    return processedImage;
}

- (void)prepareForImageCapture;
{
    [self.terminalFilter prepareForImageCapture];
}

#pragma mark -
#pragma mark GPUImageOutput overrides

- (void)setTargetToIgnoreForUpdates:(id<GPUImageInput>)targetToIgnoreForUpdates;
{
    [_terminalFilter setTargetToIgnoreForUpdates:targetToIgnoreForUpdates];
}

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    [_terminalFilter addTarget:newTarget atTextureLocation:textureLocation];
}

- (void)removeTarget:(id<GPUImageInput>)targetToRemove;
{
    [_terminalFilter removeTarget:targetToRemove];
}

- (void)removeAllTargets;
{
    [_terminalFilter removeAllTargets];
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in _initialFilters)
    {
        if (currentFilter != self.inputFilterToIgnoreForUpdates)
        {
            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in _initialFilters)
    {
        [currentFilter setInputTexture:newInputTexture atIndex:textureIndex];
    }
}

- (NSInteger)nextAvailableTextureIndex;
{
//    if ([_initialFilters count] > 0)
//    {
//        return [[_initialFilters objectAtIndex:0] nextAvailableTextureIndex];
//    }
    
    return 0;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in _initialFilters)
    {
        [currentFilter setInputSize:newSize atIndex:textureIndex];
    }
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in _initialFilters)
    {
        [currentFilter setInputRotation:newInputRotation  atIndex:(NSInteger)textureIndex];
    }
}

- (void)forceProcessingAtSize:(CGSize)frameSize;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in filters)
    {
        [currentFilter forceProcessingAtSize:frameSize];
    }
}


- (CGSize)maximumOutputSize;
{
    // I'm temporarily disabling adjustments for smaller output sizes until I figure out how to make this work better
    return CGSizeZero;

    /*
    if (CGSizeEqualToSize(cachedMaximumOutputSize, CGSizeZero))
    {
        for (id<GPUImageInput> currentTarget in _initialFilters)
        {
            if ([currentTarget maximumOutputSize].width > cachedMaximumOutputSize.width)
            {
                cachedMaximumOutputSize = [currentTarget maximumOutputSize];
            }
        }
    }
    
    return cachedMaximumOutputSize;
     */
}

- (void)endProcessing;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in _initialFilters)
    {
        [currentFilter endProcessing];
    }
}

@end
