
#import "GPUImageFilter.h"

@interface GPUImageSolidColorFilter : GPUImageFilter

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
@property(readwrite, nonatomic) UIColor *color;
#else
@property(readwrite, nonatomic) NSColor *color;
#endif

@end
