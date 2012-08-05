#import "GPUImageFilter.h"

@interface GPUImageToneCurveFilter : GPUImageFilter

@property(readwrite, nonatomic) NSArray *redControlPoints;
@property(readwrite, nonatomic) NSArray *greenControlPoints;
@property(readwrite, nonatomic) NSArray *blueControlPoints;


- (void)setRGBControlPoints:(NSArray *)points;

// Curve calculation
- (NSMutableArray *)getPreparedSplineCurve:(NSArray *)points;
- (NSMutableArray *)splineCurve:(NSArray *)points;
- (NSMutableArray *)secondDerivative:(NSArray *)cgPoints;
- (void)updateToneCurveTexture;
   
@end
