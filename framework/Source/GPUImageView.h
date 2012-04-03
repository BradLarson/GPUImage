#import <UIKit/UIKit.h>
#import "GPUImageOpenGLESContext.h"

@interface GPUImageView : UIView <GPUImageInput>
{
}

@property(readonly, nonatomic) CGSize sizeInPixels;

@end
