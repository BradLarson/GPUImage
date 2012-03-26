#import "GPUImageFilterGroup.h"
#import "GPUImageFilter.h"

@interface GPUImageFilterGroup()
{
    NSMutableArray *filtersWithNoInputs, *filtersWithNoOutputs;
}

@property(readwrite, nonatomic, strong) GPUImageFilter *initialFilter;
@property(readwrite, nonatomic, strong) GPUImageFilter *terminalFilter;

// Filter management
- (void)updateEndPoints;

@end

@implementation GPUImageFilterGroup

@synthesize initialFilter = _initialFilter;
@synthesize terminalFilter = _terminalFilter;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    filters = [[NSMutableArray alloc] init];
    
    filtersWithNoInputs = [[NSMutableArray alloc] init];
    filtersWithNoOutputs = [[NSMutableArray alloc] init];

    [self deleteOutputTexture];
    
    return self;
}

#pragma mark -
#pragma mark Filter management

- (void)addFilter:(GPUImageFilter *)newFilter;
{
    [filters addObject:newFilter];
    
    [filtersWithNoInputs addObject:newFilter];
    [filtersWithNoOutputs addObject:newFilter];
    
    [self updateEndPoints];
}

- (void)setTargetFilter:(GPUImageFilter *)targetFilter forFilter:(GPUImageFilter *)sourceFilter;
{
    if  ( ([filters indexOfObject:targetFilter] == NSNotFound) || ([filters indexOfObject:sourceFilter] == NSNotFound) )
    {
        NSAssert(NO, @"Both filters involved in setting a target within a filter group must be members of that group");
    }

    [filtersWithNoInputs removeObject:targetFilter];
    [filtersWithNoOutputs removeObject:sourceFilter];
    
    [sourceFilter addTarget:targetFilter];

    [self updateEndPoints];
}

- (GPUImageFilter *)filterAtIndex:(NSUInteger)filterIndex;
{
    return [filters objectAtIndex:filterIndex];
}

- (void)updateEndPoints;
{
    if ([filtersWithNoOutputs count] == 1)
    {
        self.terminalFilter = [filtersWithNoOutputs objectAtIndex:0];
    }
    else
    {
        self.terminalFilter = nil;
    }

    if ([filtersWithNoInputs count] == 1)
    {
        self.initialFilter = [filtersWithNoInputs objectAtIndex:0];
    }
    else
    {
        self.initialFilter = nil;
    }
}

#pragma mark -
#pragma mark GPUImageOutput overrides

- (void)addTarget:(id<GPUImageInput>)newTarget;
{
    if ([filtersWithNoOutputs count] != 1)
    {
        NSAssert(NO, @"Can't add a target to a filter group which has more than one filter without a target");
    }
    
    [_terminalFilter addTarget:newTarget];
}

- (void)removeTarget:(id<GPUImageInput>)targetToRemove;
{
    if ([filtersWithNoOutputs count] != 1)
    {
        NSAssert(NO, @"Can't remove a target from a filter group which has more than one filter without a target");
    }
    
    [_terminalFilter removeTarget:targetToRemove];
}

- (void)removeAllTargets;
{
    if ([filtersWithNoOutputs count] != 1)
    {
        NSAssert(NO, @"Can't remove a target from a filter group which has more than one filter without a target");
    }
    
    [_terminalFilter removeAllTargets];
}


#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReady;
{
    [_initialFilter newFrameReady];
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    [_initialFilter setInputTexture:newInputTexture atIndex:textureIndex];
}

- (NSInteger)nextAvailableTextureIndex;
{
    return [_initialFilter nextAvailableTextureIndex];
}

- (void)setInputSize:(CGSize)newSize;
{
    [_initialFilter setInputSize:newSize];
}

- (CGSize)maximumOutputSize;
{
    return [_initialFilter maximumOutputSize];
}

- (void)endProcessing;
{
    [_initialFilter endProcessing];
}

@end
