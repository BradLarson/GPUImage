#import "GPUImageOutput.h"

@implementation GPUImageOutput

@synthesize shouldSmoothlyScaleOutput = _shouldSmoothlyScaleOutput;

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
    // Check if contain this target
    if([targets containsObject:newTarget])
        return;
    
    cachedMaximumOutputSize = CGSizeZero;
    NSInteger nextAvailableTextureIndex = [newTarget nextAvailableTextureIndex];
    [self setInputTextureForTarget:newTarget atIndex:nextAvailableTextureIndex];
    [targets addObject:newTarget];
    [targetTextureIndices addObject:[NSNumber numberWithInteger:nextAvailableTextureIndex]];
}

- (void)removeTarget:(id<GPUImageInput>)targetToRemove;
{
    // Check if contain this target
    if(![targets containsObject:targetToRemove])
        return;
    
    cachedMaximumOutputSize = CGSizeZero;
    [targetToRemove setInputSize:CGSizeZero];
    
    NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
    [targetToRemove setInputTexture:0 atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
    [targetTextureIndices removeObjectAtIndex:indexOfObject];
    [targets removeObject:targetToRemove];
}

- (void)removeAllTargets;
{
    cachedMaximumOutputSize = CGSizeZero;
    for (id<GPUImageInput> targetToRemove in targets)
    {
        [targetToRemove setInputSize:CGSizeZero];

        NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
        [targetToRemove setInputTexture:0 atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
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
    if (outputTexture)
    {
        glDeleteTextures(1, &outputTexture);
        outputTexture = 0;
    }
}

#pragma mark -
#pragma mark Accessors


@end
