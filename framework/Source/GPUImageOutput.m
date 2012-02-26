#import "GPUImageOutput.h"

@implementation GPUImageOutput

#pragma mark -
#pragma mark Initialization and teardown

- (id)init; 
{
	if (!(self = [super init]))
    {
		return nil;
    }

    targets = [[NSMutableArray alloc] init];
    
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

- (void)addTarget:(id<GPUImageInput>)newTarget;
{
    cachedMaximumOutputSize = CGSizeZero;
    [newTarget setInputTexture:outputTexture];
    [targets addObject:newTarget];
}

- (void)removeTarget:(id<GPUImageInput>)targetToRemove;
{
    cachedMaximumOutputSize = CGSizeZero;
    [targetToRemove setInputSize:CGSizeZero];
    [targetToRemove setInputTexture:0];
    [targets removeObject:targetToRemove];
}

- (void)removeAllTargets;
{
    cachedMaximumOutputSize = CGSizeZero;
    for (id<GPUImageInput> targetToRemove in targets)
    {
        [targetToRemove setInputSize:CGSizeZero];
        [targetToRemove setInputTexture:0];
    }
    [targets removeAllObjects];
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
}

- (void)deleteOutputTexture;
{
    if (outputTexture)
    {
        glDeleteTextures(1, &outputTexture);
        outputTexture = 0;
    }
}

#pragma mark -
#pragma mark Accessors

@synthesize shouldSmoothlyScaleOutput = _shouldSmoothlyScaleOutput;

@end
