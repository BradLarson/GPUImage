#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface MultiViewViewController : UIViewController
{
    GPUImageView *view1, *view2, *view3, *view4;
    GPUImageVideoCamera *videoCamera;
}

@end
