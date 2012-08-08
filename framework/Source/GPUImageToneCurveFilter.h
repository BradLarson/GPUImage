#import "GPUImageFilter.h"

@interface GPUImageToneCurveFilter : GPUImageFilter

@property(readwrite, nonatomic, copy) NSArray *redControlPoints;
@property(readwrite, nonatomic, copy) NSArray *greenControlPoints;
@property(readwrite, nonatomic, copy) NSArray *blueControlPoints;

// Initialization and teardown
- (id)initWithACV:(NSString*)curveFile;

// This lets you set all three red, green, and blue tone curves at once.
- (void)setRGBControlPoints:(NSArray *)points;
- (void)setPointsWithACV:(NSString*)curveFile;

// Curve calculation
- (NSMutableArray *)getPreparedSplineCurve:(NSArray *)points;
- (NSMutableArray *)splineCurve:(NSArray *)points;
- (NSMutableArray *)secondDerivative:(NSArray *)cgPoints;
- (void)updateToneCurveTexture;
   
@end
