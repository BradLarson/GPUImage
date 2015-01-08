#import <Cocoa/Cocoa.h>
#import <GPUImage/GPUImage.h>

@interface SLSSimpleVideoFilterWindowController : NSWindowController
{
    GPUImageAVCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
}

@property (weak) IBOutlet GPUImageView *videoView;

@end
