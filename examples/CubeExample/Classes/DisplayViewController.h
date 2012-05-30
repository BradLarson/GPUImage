#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "ESRenderer.h"
#import "ES2Renderer.h"
#import "GPUImage.h"

@interface DisplayViewController : UIViewController
{
    CGPoint lastMovementPosition;
@private
    ES2Renderer *renderer;
    GPUImageTextureInput *textureInput;
    GPUImageFilter *filter;
    
    NSDate *startTime;
}

- (void)drawView:(id)sender;

@end
