#import <UIKit/UIKit.h>
#import "GPUImage.h"

typedef enum { PASSTHROUGH_VIDEO, SIMPLE_THRESHOLDING, POSITION_THRESHOLDING, OBJECT_TRACKING} ColorTrackingDisplayMode;

@interface ColorTrackingViewController : UIViewController
{
    CALayer *trackingDot;

    GPUImageVideoCamera *videoCamera;
    GPUImageFilter *rotationFilter, *thresholdFilter, *positionFilter;
    GPUImageView *filteredVideoView;
    
    ColorTrackingDisplayMode displayMode;
	
	BOOL shouldReplaceThresholdColor;
	CGPoint currentTouchPoint;
	GLfloat thresholdSensitivity;
	GLfloat thresholdColor[3];
}

- (void)configureVideoFiltering;
- (void)configureToolbar;
- (void)configureTrackingDot;

@end
