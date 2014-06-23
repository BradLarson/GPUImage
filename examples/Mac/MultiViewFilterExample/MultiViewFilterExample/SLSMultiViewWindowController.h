#import <Cocoa/Cocoa.h>
#import <GPUImage/GPUImage.h>

@interface SLSMultiViewWindowController : NSWindowController
{
    GPUImageFilter *filter1, *filter2, *filter3;
    GPUImageAVCamera *videoCamera;
}

@property(readwrite) IBOutlet GPUImageView *upperLeftView, *upperRightView, *lowerLeftView, *lowerRightView;

@end
