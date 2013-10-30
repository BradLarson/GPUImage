#import "GPUImageFilter.h"

@interface GPUImageCurveData : NSObject

- (id)initWithACVData:(NSData*)data;
- (id)initWithACV:(NSString*)curveFilename;
- (id)initWithACVURL:(NSURL*)curveFileURL;

@property(readwrite, nonatomic, copy) NSArray *redControlPoints;
@property(readwrite, nonatomic, copy) NSArray *greenControlPoints;
@property(readwrite, nonatomic, copy) NSArray *blueControlPoints;
@property(readwrite, nonatomic, copy) NSArray *rgbCompositeControlPoints;

@property(readonly, nonatomic) NSArray *rgbCompositeCurve;
@property(readonly, nonatomic) NSArray *redCurve;
@property(readonly, nonatomic) NSArray *greenCurve;
@property(readonly, nonatomic) NSArray *blueCurve;

// Curve calculation
- (NSMutableArray *)getPreparedSplineCurve:(NSArray *)points;
- (NSMutableArray *)splineCurve:(NSArray *)points;
- (NSMutableArray *)secondDerivative:(NSArray *)cgPoints;

@end

@interface GPUImageToneCurveFilter : GPUImageFilter

@property(readwrite, nonatomic, copy) NSArray *redControlPoints DEPRECATED_ATTRIBUTE;
@property(readwrite, nonatomic, copy) NSArray *greenControlPoints DEPRECATED_ATTRIBUTE;
@property(readwrite, nonatomic, copy) NSArray *blueControlPoints DEPRECATED_ATTRIBUTE;
@property(readwrite, nonatomic, copy) NSArray *rgbCompositeControlPoints DEPRECATED_ATTRIBUTE;

@property(readwrite, nonatomic) GPUImageCurveData *curveData;

// Initialization and teardown
- (id)initWithCurveData:(GPUImageCurveData *)curveData;

- (id)initWithACVData:(NSData*)data;
- (id)initWithACV:(NSString*)curveFilename;
- (id)initWithACVURL:(NSURL*)curveFileURL;

// This lets you set all three red, green, and blue tone curves at once.
// NOTE: Deprecated this function because this effect can be accomplished
// using the rgbComposite channel rather then setting all 3 R, G, and B channels.
- (void)setRGBControlPoints:(NSArray *)points DEPRECATED_ATTRIBUTE;

- (void)setPointsWithACV:(NSString*)curveFilename;
- (void)setPointsWithACVURL:(NSURL*)curveFileURL;

// Deprecated because this is an internal method.
- (void)updateToneCurveTexture;

@end
