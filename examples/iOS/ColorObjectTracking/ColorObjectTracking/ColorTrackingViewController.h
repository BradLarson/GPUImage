#import <UIKit/UIKit.h>
#import "GPUImage.h"

typedef enum { PASSTHROUGH_VIDEO, SIMPLE_THRESHOLDING, POSITION_THRESHOLDING, OBJECT_TRACKING} ColorTrackingDisplayMode;

@interface ColorTrackingViewController : UIViewController
{
    CALayer *trackingDot;

    GPUImageVideoCamera *videoCamera;
    GPUImageFilter *thresholdFilter, *positionFilter;
    GPUImageRawDataOutput *positionRawData, *videoRawData;
    GPUImageAverageColor *positionAverageColor;
    GPUImageView *filteredVideoView;
    
    ColorTrackingDisplayMode displayMode;
	
	BOOL shouldReplaceThresholdColor;
	CGPoint currentTouchPoint;
	GLfloat thresholdSensitivity;
	GPUVector3 thresholdColor;
}

- (void)configureVideoFiltering;
- (void)configureToolbar;
- (void)configureTrackingDot;

// Image processing
- (CGPoint)centroidFromTexture:(GLubyte *)pixels ofSize:(CGSize)textureSize;

@end
