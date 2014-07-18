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

@synthesize currentSliderValue=_currentSliderValue;

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

#pragma mark - Keypath dependencies

+ (NSSet *)keyPathsForValuesAffectingCurrentSliderValue
{
	return [NSSet setWithArray:@[@"selectedVariableIndex"]];
}

+ (NSSet *)keyPathsForValuesAffectingMinimumSliderValue
{
	return [NSSet setWithArray:@[@"selectedVariableIndex"]];
}

+ (NSSet *)keyPathsForValuesAffectingMaximumSliderValue
{
	return [NSSet setWithArray:@[@"selectedVariableIndex"]];
}

#pragma mark - Accessors

- (NSUInteger)countOfImageFilterClassNames
{
	return [_filterClassNames count] + [_filterGroupClassNames count];
}

- (CGFloat)currentSliderValue
{
	NSString *key = [(GPUImageFilterVariable *)_filterVariables[_selectedVariableIndex] name];
	return [[_activeFilter valueForKeyPath:key] floatValue];
}

- (void)setCurrentSliderValue:(CGFloat)newValue;
{
    _currentSliderValue = newValue;
	NSString *keyPath = [_activeFilter sliderKeyPath];
	[_activeFilter setValue:@(newValue) forKeyPath:keyPath];
}

- (CGFloat)minimumSliderValue
{
	return [(GPUImageFilterVariable *)_filterVariables[_selectedVariableIndex] minimum];
}

- (CGFloat)maximumSliderValue
{
	return [(GPUImageFilterVariable *)_filterVariables[_selectedVariableIndex] maximum];
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
	// this creates and connects the new filter to the source and destination
	return [NSClassFromString([self objectInImageFilterClassNamesAtIndex:index]) showcaseImageOutputWithSource:_inputCamera targetView:_glView];
}

- (void)clearCurrentFilter
{
	if (_activeFilter) {
        [_inputCamera removeAllTargets];
        [_imageForBlending removeAllTargets];
        [_activeFilter removeAllTargets];
        _activeFilter = nil;
    }
}

- (void)setActiveFilter:(GPUImageOutput<GPUImageInput> *)filter
{
	_activeFilter = filter;
	
	self.enableSlider = [_activeFilter enableSlider];
	if (_enableSlider) {
		self.filterVariables = _activeFilter.filterVariables;
		self.selectedVariableIndex = 0;
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

- (void)setSelectedRow:(NSUInteger)selectedRow
{
	if (selectedRow != _selectedRow || nil == _activeFilter) {
		_selectedRow = selectedRow;
		// clear the current filter before creating the new filter
		[self clearCurrentFilter];
		[self setActiveFilter:[self imageFilterAtIndex:_selectedRow]];
	}
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

#pragma mark - Actions

- (IBAction)updateSelectedVariable:(NSPopUpButton *)sender {
	self.selectedVariableIndex = [sender indexOfSelectedItem];
}

@end
