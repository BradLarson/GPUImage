#import <Cocoa/Cocoa.h>
#import <GPUImage/GPUImage.h>

@interface SLSDocument : NSDocument
{
    GPUImagePicture *inputPicture;
    GPUImageFilter *imageFilter;
}

@property(readwrite, weak) IBOutlet GPUImageView *imageView;
@property(readwrite, nonatomic) CGFloat sliderSetting;

@end
