#import <Cocoa/Cocoa.h>
#import <GPUImage/GPUImage.h>

@interface SLSSimpleVideoFileFilterWindowController : NSWindowController
{
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    NSTimer * timer;
}

@property (weak) IBOutlet GPUImageView *videoView;

@property (retain, nonatomic) IBOutlet NSTextField *progressLabel;
- (IBAction)updatePixelWidth:(id)sender;

@end
