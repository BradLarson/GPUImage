
#import "GPUImageFilter.h"
// https://codea.io/talk/discussion/6772/multiple-step-colour-gradient-shader

@interface GPUImageFilter (Float4Array)
- (void)setFloat4Array:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
@end

#pragma mark

@interface GPUImageGradientRadialFilter : GPUImageFilter

// Default of (0.5, 0.5)
@property(readwrite, nonatomic) CGPoint center;
// Set to (1.0, 1.0) for circular gradient, (0.0, 1.0) or (1.0, 0.0) for linear, or fractional, eg (1.0, 0.5) for oval
@property(readwrite, nonatomic) CGPoint aspect;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
// Colors and transition points between the colors (transition points are in range 0.0 - 1.0)
- (void)setSteps:(NSArray<NSNumber *> *)steps withColors:(NSArray<UIColor *> *)colors;
// Colors to grade between. Transitions poins are calculated according number of colors
- (void)setColors:(NSArray<UIColor *> *)colors;
#else
- (void)setSteps:(NSArray<NSNumber *> *)steps withColors:(NSArray<NSColor *> *)colors;
- (void)setColors:(NSArray<NSColor *> *)colors;
#endif

@end

#pragma mark

@interface GPUImageGradientLinearFilter : GPUImageFilter

// Default of (0.5, 0.5)
@property(readwrite, nonatomic) CGPoint center;
// Angle in degrees
@property(readwrite, nonatomic) CGFloat angle;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
// Colors and transition points between the colors (transition points are in range 0.0 - 1.0)
- (void)setSteps:(NSArray<NSNumber *> *)steps withColors:(NSArray<UIColor *> *)colors;
// Colors to grade between. Transitions poins are calculated according number of colors
- (void)setColors:(NSArray<UIColor *> *)colors;
#else
// Colors and transition points between the colors (transition points are in range 0.0 - 1.0)
- (void)setSteps:(NSArray<NSNumber *> *)steps withColors:(NSArray<NSColor *> *)colors;
// Colors to grade between. Transitions poins are calculated according number of colors
- (void)setColors:(NSArray<NSColor *> *)colors;
#endif

@end
