#import "GPUImageOutput.h"
#import "GPUImageMovieWriter.h"
#import <mach/mach.h>

void runOnMainQueueWithoutDeadlocking(void (^block)(void))
{
	if ([NSThread isMainThread])
	{
		block();
	}
	else
	{
		dispatch_sync(dispatch_get_main_queue(), block);
	}
}

void report_memory(NSString *tag) 
{    
    if (!tag)
        tag = @"Default";
    
    struct task_basic_info info;
    
    mach_msg_type_number_t size = sizeof(info);
    
    kern_return_t kerr = task_info(mach_task_self(),
                                   
                                   TASK_BASIC_INFO,
                                   
                                   (task_info_t)&info,
                                   
                                   &size);    
    if( kerr == KERN_SUCCESS ) {        
        NSLog(@"%@ - Memory used: %u", tag, info.resident_size); //in bytes        
    } else {        
        NSLog(@"%@ - Error: %s", tag, mach_error_string(kerr));        
    }    
}

@implementation GPUImageOutput

@synthesize shouldSmoothlyScaleOutput = _shouldSmoothlyScaleOutput;
@synthesize shouldIgnoreUpdatesToThisTarget = _shouldIgnoreUpdatesToThisTarget;
@synthesize audioEncodingTarget = _audioEncodingTarget;
@synthesize targetToIgnoreForUpdates = _targetToIgnoreForUpdates;
@synthesize frameProcessingCompletionBlock = _frameProcessingCompletionBlock;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init; 
{
	if (!(self = [super init]))
    {
		return nil;
    }

    targets = [[NSMutableArray alloc] init];
    targetTextureIndices = [[NSMutableArray alloc] init];
    
    [self initializeOutputTexture];

    return self;
}

- (void)dealloc 
{
    [self removeAllTargets];
    [self deleteOutputTexture];
}

#pragma mark -
#pragma mark Managing targets

- (void)setInputTextureForTarget:(id<GPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;
{
    [target setInputTexture:outputTexture atIndex:inputTextureIndex];
}

- (void)addTarget:(id<GPUImageInput>)newTarget;
{
    NSInteger nextAvailableTextureIndex = [newTarget nextAvailableTextureIndex];
    [self addTarget:newTarget atTextureLocation:nextAvailableTextureIndex];
    if ([newTarget shouldIgnoreUpdatesToThisTarget])
    {
        _targetToIgnoreForUpdates = newTarget;
    }
}

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    if([targets containsObject:newTarget])
    {
        return;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    [self setInputTextureForTarget:newTarget atIndex:textureLocation];
    [targets addObject:newTarget];
    [targetTextureIndices addObject:[NSNumber numberWithInteger:textureLocation]];
}

- (void)removeTarget:(id<GPUImageInput>)targetToRemove;
{
    if(![targets containsObject:targetToRemove])
    {
        return;
    }
    
    if (_targetToIgnoreForUpdates == targetToRemove)
    {
        _targetToIgnoreForUpdates = nil;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    
    NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
    NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
    [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
    [targetToRemove setInputTexture:0 atIndex:textureIndexOfTarget];
    
    [targetTextureIndices removeObjectAtIndex:indexOfObject];
    [targets removeObject:targetToRemove];
}

- (void)removeAllTargets;
{
    cachedMaximumOutputSize = CGSizeZero;
    for (id<GPUImageInput> targetToRemove in targets)
    {
        NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
        NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        
        [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];        
        [targetToRemove setInputTexture:0 atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
        [targetToRemove setInputRotation:kGPUImageNoRotation atIndex:textureIndexOfTarget];
    }
    [targets removeAllObjects];
    [targetTextureIndices removeAllObjects];
}

#pragma mark -
#pragma mark Manage the output texture

- (void)initializeOutputTexture;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &outputTexture);
	glBindTexture(GL_TEXTURE_2D, outputTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)deleteOutputTexture;
{
    [GPUImageOpenGLESContext useImageProcessingContext];

    if (outputTexture)
    {
        glDeleteTextures(1, &outputTexture);
        outputTexture = 0;
    }
}

- (void)forceProcessingAtSize:(CGSize)frameSize;
{
    
}

- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize;
{
}

#pragma mark -
#pragma mark Still image processing

/**
 Retreive the currently processed output image as an UIImage.
 
 The image's orientation will be the device's current orientation.
 See also: [GPUImageOutput imageFromCurrentlyProcessedOutputWithOrientation:]
 */
- (UIImage *)imageFromCurrentlyProcessedOutput;
{
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    UIImageOrientation imageOrientation = UIImageOrientationLeft;
	switch (deviceOrientation)
    {
		case UIDeviceOrientationPortrait:
			imageOrientation = UIImageOrientationUp;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			imageOrientation = UIImageOrientationDown;
			break;
		case UIDeviceOrientationLandscapeLeft:
			imageOrientation = UIImageOrientationLeft;
			break;
		case UIDeviceOrientationLandscapeRight:
			imageOrientation = UIImageOrientationRight;
			break;
		default:
			imageOrientation = UIImageOrientationUp;
			break;
	}
    
    return [self imageFromCurrentlyProcessedOutputWithOrientation:imageOrientation];
}

- (UIImage *)imageFromCurrentlyProcessedOutputWithOrientation:(UIImageOrientation)imageOrientation;
{
    return nil;
}

- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter;
{
    return nil;
}

- (void)prepareForImageCapture;
{
    
}

#pragma mark -
#pragma mark Accessors

- (void)setAudioEncodingTarget:(GPUImageMovieWriter *)newValue;
{    
    _audioEncodingTarget = newValue;
    
    _audioEncodingTarget.hasAudioTrack = YES;
}

@end
