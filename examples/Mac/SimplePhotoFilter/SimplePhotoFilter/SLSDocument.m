#import "SLSDocument.h"

@implementation SLSDocument

@synthesize imageView = _imageView;
@synthesize sliderSetting = _sliderSetting;

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"SLSDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    NSLog(@"Did load nib");
    
//    [inputPicture addTarget:imageFilter];
//    [imageFilter addTarget:self.imageView];
    
//    [inputPicture addTarget:self.imageView];
//    [inputPicture processImage];
    
    [inputPicture addTarget:imageFilter];
    GPUImageSketchFilter *sketchFilter = [[GPUImageSketchFilter alloc] init];
    [imageFilter addTarget:sketchFilter];
    [sketchFilter addTarget:self.imageView];
    [inputPicture processImage];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Take in image from data, read that into NSImage
    // Start up a GPUImagePicture with that data
    NSImage *sourceImage = [[NSImage alloc] initWithData:data];
    inputPicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    imageFilter = [[GPUImageBrightnessFilter alloc] init];
    NSLog(@"Set up filters");
    
    return YES;
}

#pragma mark -
#pragma mark Accessors

- (void)setSliderSetting:(CGFloat)newValue;
{
    _sliderSetting = newValue;
    
    [(GPUImageBrightnessFilter *)imageFilter setBrightness:_sliderSetting];
    [inputPicture processImage];
}


@end
