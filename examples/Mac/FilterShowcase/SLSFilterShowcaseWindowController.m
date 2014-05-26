#import "SLSFilterShowcaseWindowController.h"

#import "GPUImageOutput+Showcase.h"

#import "NSObject+GPUImageHelpers.h"

@interface SLSFilterShowcaseWindowController ()

@end

@implementation SLSFilterShowcaseWindowController {
    GPUImageAVCamera *_inputCamera;
    GPUImagePicture *_imageForBlending;
    GPUImageOutput<GPUImageInput> *_activeFilter;
	NSArray *_filterClassNames;
	NSArray *_filterGroupClassNames;
}

#pragma mark - Initialization and teardown

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
		// Most abstract classes
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"excludeFromShowcase == NO"];
		NSArray *filterClasses = [[GPUImageFilter gpu_subclasses] filteredArrayUsingPredicate:predicate];
        _filterClassNames = [[filterClasses valueForKeyPath:@"className"] sortedArrayUsingSelector:@selector(compare:)];
		
		NSArray *groupClasses = [[GPUImageFilterGroup gpu_subclasses] filteredArrayUsingPredicate:predicate];
		_filterGroupClassNames = [[groupClasses valueForKeyPath:@"className"] sortedArrayUsingSelector:@selector(compare:)];
		_selectedRow = NSNotFound;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    _inputCamera = [[GPUImageAVCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraDevice:nil];
    self.selectedRow = 0;
    [_inputCamera startCameraCapture];
}

#pragma mark - Accessors

- (NSUInteger)countOfImageFilterClassNames
{
	return [_filterClassNames count] + [_filterGroupClassNames count];
}

- (NSString *)objectInImageFilterClassNamesAtIndex:(NSUInteger)index
{
	NSUInteger filterCount = [_filterClassNames count];
	if (index >= filterCount) {
		index -= filterCount;
		return [_filterGroupClassNames objectAtIndex:index];
	}
	else {
		return [_filterClassNames objectAtIndex:index];
	}
}

#pragma mark - Filter switching

- (GPUImageOutput<GPUImageInput> *)imageFilterAtIndex:(NSUInteger)index
{
	return [NSClassFromString([self objectInImageFilterClassNamesAtIndex:index]) showcaseImageOutputWithSource:_inputCamera targetView:_glView];
}

- (void)setSelectedRow:(NSUInteger)selectedRow
{
	if (selectedRow == _selectedRow && nil == _activeFilter) {
		return;
	}
	
    _selectedRow = selectedRow;
	
    if (_activeFilter) {
        [_inputCamera removeAllTargets];
        [_imageForBlending removeAllTargets];
        // Disconnect older filter before replacing with new one
        [_activeFilter removeAllTargets];
        _activeFilter = nil;
    }
	
	_activeFilter = [self imageFilterAtIndex:_selectedRow];
	
	self.enableSlider = [_activeFilter enableSlider];
	if (_enableSlider) {
		self.minimumSliderValue = [_activeFilter minSliderValue];
		self.maximumSliderValue = [_activeFilter maxSliderValue];
		
		[self willChangeValueForKey:@"currentSliderValue"];
		_currentSliderValue = [[_activeFilter valueForKeyPath:[_activeFilter sliderKeyPath]] floatValue];
		[self didChangeValueForKey:@"currentSliderValue"];
	}
    
    if ([_activeFilter needsSecondImage]) {
		_imageForBlending = [[GPUImagePicture alloc] initWithImage:[_activeFilter secondInputImage] smoothlyScaleOutput:YES];
        [_imageForBlending processImage];
		[_activeFilter setSecondImage:_imageForBlending];
    }
	else {
		_imageForBlending = nil;
	}
}

#pragma mark - Filter settings

- (void)setCurrentSliderValue:(CGFloat)newValue;
{
    _currentSliderValue = newValue;
	NSString *keyPath = [_activeFilter sliderKeyPath];
	[_activeFilter setValue:@(newValue) forKeyPath:keyPath];
}

#pragma mark - NSTableViewDelegate

- (NSUInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self countOfImageFilterClassNames];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	Class class = NSClassFromString([self objectInImageFilterClassNamesAtIndex:rowIndex]);
    return [class displayName];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
	self.selectedRow = [[aNotification object] selectedRow];
}

@end
