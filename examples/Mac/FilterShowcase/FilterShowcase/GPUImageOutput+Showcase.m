//
//  GPUImageFilter+Showcase.m
//  FilterShowcase
//
//  Created by Brent Gulanowski on 2014-05-24.
//  Copyright (c) 2014 Sunset Lake Software LLC. All rights reserved.
//

#import "GPUImageOutput+Showcase.h"

// Not in GPUImage.h
#import <GPUImage/GPUImageSourceOverBlendFilter.h>
#import <GPUImage/GPUImageNonMaximumSuppressionFilter.h>
#import <GPUImage/GPUImageWeakPixelInclusionFilter.h>
#import <GPUImage/GPUImageSolidColorGenerator.h>

@implementation GPUImageTransform3DFilter
@end

@implementation GPUImageFilterVariable
+ (instancetype)filterVariableWithName:(NSString *)name min:(CGFloat)min max:(CGFloat)max initial:(CGFloat)initial
{
	GPUImageFilterVariable *variable = [[self alloc] init];
	variable.name = name;
	variable.minimum = min;
	variable.maximum = max;
	variable.initial = initial;
	return variable;
}
@end

@implementation GPUImageOutput (Showcase)

- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	return [self init];
}

- (NSString *)displayName
{
	return [[self class] displayName];
}

#pragma mark - Blend images

- (BOOL)needsSecondImage
{
	return NO;
}

- (NSImage *)secondInputImage
{
	// The picture is only used for two-image blend filters
	return [NSImage imageNamed:@"Lambeau.jpg"];
}

- (void)setSecondImage:(GPUImagePicture *)image
{
	// overridden by Input classes
}

#pragma mark - Filter Variables

- (NSArray *)filterVariables
{
	NSString *keyPath = [self sliderKeyPath];
	CGFloat initialValue = [[self valueForKeyPath:keyPath] floatValue];
	return @[[GPUImageFilterVariable filterVariableWithName:keyPath min:[self minSliderValue] max:[self maxSliderValue] initial:initialValue]];
}

- (BOOL)enableSlider
{
	return YES;
}

- (NSString *)sliderKeyPath
{
	return [[self displayName] lowercaseString];
}

- (CGFloat)minSliderValue
{
	return 0;
}

- (CGFloat)maxSliderValue
{
	return 1.;
}

- (GPUImageView *)viewTarget
{
	for (id target in self.targets) {
		if ([target isKindOfClass:[GPUImageView class]]) {
			return target;
		}
	}
	return nil;
}

+ (BOOL)excludeFromShowcase
{
	return NO;
}

+ (instancetype)showcaseImageOutputWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	return [[self alloc] initWithSource:output targetView:view];
}

+ (NSString *)displayName {
	NSString *className = [self className];
	BOOL hasSuffix = [className hasSuffix:@"Filter"];
	NSString *displayName = [className substringWithRange:NSMakeRange(8, [className length] - (hasSuffix ? 14 : 8))];
	return displayName;
}

@end

#pragma mark - Abstract Filter Classes

@implementation GPUImageFilter (Showcase)

- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
		[output addTarget:self];
		[self addTarget:view];
	}
	return self;
}

- (void)setSecondImage:(GPUImagePicture *)image
{
	[image addTarget:self];
}

- (void)configureSphereWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
#if 0
	[output addTarget:self];
	[self addTarget:view];
#else
	// Provide a blurred image for a cool-looking background
	GPUImageGaussianBlurFilter *gaussianBlur = [[GPUImageGaussianBlurFilter alloc] init];
	[output addTarget:gaussianBlur];
	[output addTarget:self];

	gaussianBlur.blurRadiusInPixels = 10.0;
	
	GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
	blendFilter.mix = 0.5;
	[gaussianBlur addTarget:blendFilter];
	[self addTarget:blendFilter];
	
	[blendFilter addTarget:view];
#endif
}

@end

@implementation GPUImageFilterGroup (Showcase)

- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
		[self addTarget:view];
		[output addTarget:self];
	}
	return self;
}

- (void)setSecondImage:(GPUImagePicture *)image
{
	[image addTarget:self];
}

- (id)featureDetectionBlockWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	CGSize viewSize = [view sizeInPixels];
	
	GPUImageCrosshairGenerator *crosshairGenerator = [[GPUImageCrosshairGenerator alloc] init];
	crosshairGenerator.crosshairWidth = 15.0;
	[crosshairGenerator forceProcessingAtSize:viewSize];
		
	GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
	[blendFilter forceProcessingAtSize:viewSize];
	GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
	[output addTarget:gammaFilter];
	[gammaFilter addTarget:blendFilter];
	
	[crosshairGenerator addTarget:blendFilter];
	
	[blendFilter addTarget:view];

	return ^(GLfloat* cornerArray, NSUInteger cornersDetected, CMTime frameTime) {
		[crosshairGenerator renderCrosshairsFromArray:cornerArray count:cornersDetected frameTime:frameTime];
	};
}

@end

@implementation GPUImageTwoInputFilter (Showcase)
+ (BOOL)excludeFromShowcase { return self == [GPUImageTwoInputFilter class]; }
@end

@implementation GPUImageTwoPassFilter (Showcase)
+ (BOOL)excludeFromShowcase { return self == [GPUImageTwoPassFilter class]; }
@end

@implementation GPUImageTwoPassTextureSamplingFilter (Showcase)
+ (BOOL)excludeFromShowcase { return self == [GPUImageTwoPassTextureSamplingFilter class]; }
@end

@implementation GPUImageTwoInputCrossTextureSamplingFilter (Showcase)
+ (BOOL)excludeFromShowcase { return self == [GPUImageTwoInputCrossTextureSamplingFilter class]; }
@end

@implementation GPUImageThreeInputFilter (Showcase)
+ (BOOL)excludeFromShowcase { return self == [GPUImageThreeInputFilter class]; }
@end

@implementation GPUImage3x3TextureSamplingFilter (Showcase)
+ (BOOL)excludeFromShowcase { return self == [GPUImage3x3TextureSamplingFilter class]; }
@end

#pragma mark - Color Processing Filters

// Note: not all classes require overrides

@implementation GPUImageAdaptiveThresholdFilter (Showcase)
- (NSString *)sliderKeyPath { return @"blurRadiusInPixels"; }
- (CGFloat)minSliderValue { return 1.; }
- (CGFloat)maxSliderValue { return 20.; }
@end

@implementation GPUImageAmatorkaFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageAverageColor (Showcase)
- (id)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
        GPUImageSolidColorGenerator *colorGenerator = [[GPUImageSolidColorGenerator alloc] init];
        [colorGenerator forceProcessingAtSize:[view sizeInPixels]];
        
        [self setColorAverageProcessingFinishedBlock:^(CGFloat redComponent, CGFloat greenComponent, CGFloat blueComponent, CGFloat alphaComponent, CMTime frameTime) {
            [colorGenerator setColorRed:redComponent green:greenComponent blue:blueComponent alpha:alphaComponent];
//			NSLog(@"Average color: %f, %f, %f, %f", redComponent, greenComponent, blueComponent, alphaComponent);
        }];
        
		[output addTarget:self];
        [colorGenerator addTarget:view];
	}
	return self;
}
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageAverageLuminanceThresholdFilter (Showcase)
- (NSString *)sliderKeyPath { return @"thresholdMultiplier"; }
- (CGFloat)maxSliderValue { return 2.; }
@end

@implementation GPUImageBrightnessFilter (Showcase)
- (CGFloat)minSliderValue { return -1.; }
- (CGFloat)maxSliderValue { return 1.; }
@end

@implementation GPUImageCGAColorspaceFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageColorInvertFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageColorMatrixFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageContrastFilter (Showcase)
- (CGFloat)minSliderValue { return 0.; }
- (CGFloat)maxSliderValue { return 4.; }
@end

@implementation GPUImageExposureFilter (Showcase)
- (CGFloat)minSliderValue { return -4.; }
- (CGFloat)maxSliderValue { return 4.; }
@end

@implementation GPUImageFalseColorFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageGammaFilter (Showcase)
- (CGFloat)maxSliderValue { return 3.; }
@end

@implementation GPUImageGrayscaleFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageHazeFilter (Showcase)
- (NSString *)sliderKeyPath { return @"distance"; }
- (CGFloat)minSliderValue { return -0.2; }
- (CGFloat)maxSliderValue { return 0.2; }
@end

@implementation GPUImageHighlightShadowFilter (Showcase)
- (NSString *)sliderKeyPath { return @"highlights"; }
@end

@implementation GPUImageHistogramFilter (Showcase)
- (id)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {

		// I'm adding an intermediary filter because glReadPixels() requires something to be rendered for its glReadPixels() operation to work
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
        [output addTarget:gammaFilter];
        [gammaFilter addTarget:self];
        
        GPUImageHistogramGenerator *histogramGraph = [[GPUImageHistogramGenerator alloc] init];
        
        [histogramGraph forceProcessingAtSize:CGSizeMake(256.0, 144.0)];
        [self addTarget:histogramGraph];
        
        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        blendFilter.mix = 0.75;
        [blendFilter forceProcessingAtSize:CGSizeMake(256.0, 144.0)];
        
        [output addTarget:blendFilter];
        [histogramGraph addTarget:blendFilter];
        
        [blendFilter addTarget:view];
	}
	return self;
}

- (NSString *)sliderKeyPath { return @"downsamplingFactor"; }
- (CGFloat)minSliderValue { return 4.; }
- (CGFloat)maxSliderValue { return 32.; }
@end

@implementation GPUImageHistogramGenerator (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageHueFilter (Showcase)
- (CGFloat)minSliderValue { return 0.; }
- (CGFloat)maxSliderValue { return 360.; }
@end

@implementation GPUImageLevelsFilter (Showcase)
- (NSString *)sliderKeyPath { return @"level"; }
- (CGFloat)level {
	return 0.;
}
- (void)setLevel:(CGFloat)level {
	[self setRedMin:level gamma:1. max:1.];
	[self setGreenMin:level gamma:1. max:1.];
	[self setBlueMin:level gamma:1. max:1.];
}
- (CGFloat)minSliderValue { return 0.; }
- (CGFloat)maxSliderValue { return 1.; }
@end

@implementation GPUImageLookupFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

// GPUImageLuminanceThresholdFilter - no overrides
@implementation GPUImageLuminanceThresholdFilter (Showcase)
- (NSString *)sliderKeyPath { return @"threshold"; }
@end

@implementation GPUImageLuminosity (Showcase)
- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
        GPUImageSolidColorGenerator *colorGenerator = [[GPUImageSolidColorGenerator alloc] init];
        [colorGenerator forceProcessingAtSize:[view sizeInPixels]];
        
        [self setLuminosityProcessingFinishedBlock:^(CGFloat luminosity, CMTime frameTime) {
            [colorGenerator setColorRed:luminosity green:luminosity blue:luminosity alpha:1.0];
        }];
        
		[output addTarget:self];
        [colorGenerator addTarget:view];
	}
	return self;
}

- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageMissEtikateFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

// GPUImageOpacityFilter - no overrides
@implementation GPUImageOpacityFilter (Showcase)

- (void)setSecondImage:(GPUImagePicture *)image
{
	GPUImageView *view = [self viewTarget];
	[self removeTarget:view];

	GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
	blendFilter.mix = 1.0;
	[blendFilter addTarget:view];
	[image addTarget:blendFilter];
	[self addTarget:blendFilter];
}

@end

@implementation GPUImageMonochromeFilter (Showcase)
- (NSString *)sliderKeyPath { return @"intensity"; }
@end

@implementation GPUImageRGBFilter (Showcase)
- (NSString *)sliderKeyPath { return @"green"; }
- (CGFloat)minSliderValue { return 0.; }
- (CGFloat)maxSliderValue { return 2.; }
@end

@implementation GPUImageSaturationFilter (Showcase)
- (CGFloat)minSliderValue { return 0.; }
- (CGFloat)maxSliderValue { return 2.; }
@end

@implementation GPUImageSepiaFilter (Showcase)
- (NSString *)sliderKeyPath { return @"intensity"; }
@end

@implementation GPUImageSoftEleganceFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageSolidColorGenerator (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageToneCurveFilter (Showcase)
- (NSString *)sliderKeyPath { return @"sliderValue"; }
- (CGFloat)sliderValue { return 0.5; }
- (void)setSliderValue:(CGFloat)value {
	[self setBlueControlPoints:@[[NSValue valueWithPoint:NSMakePoint(0.0, 0.0)],
								 [NSValue valueWithPoint:NSMakePoint(0.5, value)],
								 [NSValue valueWithPoint:NSMakePoint(1.0, 0.75)]]];
}
@end

@implementation GPUImageWhiteBalanceFilter (Showcase)
- (NSString *)sliderKeyPath { return @"temperature"; }
- (CGFloat)minSliderValue { return 2500.; }
- (CGFloat)maxSliderValue { return 7500.; }
@end

#pragma mark - Image Processing

@implementation GPUImage3x3ConvolutionFilter (Showcase)
- (id)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [super initWithSource:output targetView:view];
	if (self) {
		self.convolutionKernel = (GPUMatrix3x3){
			{-1.0f,  0.0f, 1.0f},
			{-2.0f, 0.0f, 2.0f},
			{-1.0f,  0.0f, 1.0f}
		};
	}
	return self;
}
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageBilateralFilter (Showcase)
- (NSString *)sliderKeyPath { return @"distanceNormalizationFactor"; }
- (CGFloat)maxSliderValue { return 10.; }
@end

@implementation GPUImageBoxBlurFilter (Showcase)
- (NSString *)sliderKeyPath { return @"blurRadiusInPixels"; }
- (CGFloat)minSliderValue { return 1.; }
- (CGFloat)maxSliderValue { return 24.; }
@end

@implementation GPUImageBuffer (Showcase)

- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
		GPUImageDifferenceBlendFilter *blendFilter = [[GPUImageDifferenceBlendFilter alloc] init];
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
		
        [output addTarget:self];
        [output addTarget:gammaFilter];
		
        [gammaFilter addTarget:blendFilter];
        [self addTarget:blendFilter];
        
        [blendFilter addTarget:view];
	}
	return self;
}

- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageCannyEdgeDetectionFilter (Showcase)
- (NSString *)sliderKeyPath { return @"blurTexelSpacingMultiplier"; }
@end

@implementation GPUImageColorPackingFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageCropFilter (Showcase)
- (NSString *)sliderKeyPath { return @"cropHeight"; }
- (CGFloat)cropHeight { return self.cropRegion.size.height; }
- (void)setCropHeight:(CGFloat)height {
	self.cropRegion = CGRectMake(0.0, 0.0, 1.0, height);
}
- (CGFloat)minSliderValue { return 0.2; }
@end

@implementation GPUImageCrosshairGenerator (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageDirectionalNonMaximumSuppressionFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUimageDirectionalSobelEdgeDetectionFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageGaussianBlurFilter (Showcase)
- (NSString *)sliderKeyPath { return @"blurRadiusInPixels"; }
- (CGFloat)minSliderValue { return 1.; }
- (CGFloat)maxSliderValue { return 24; }
@end

@implementation GPUImageGaussianBlurPositionFilter (Showcase)
- (NSString *)sliderKeyPath { return @"blurRadius"; }
- (CGFloat)maxSliderValue { return .75; }
@end

@implementation GPUImageGaussianSelectiveBlurFilter (Showcase)
- (NSString *)sliderKeyPath { return @"excludeCircleRadius"; }
@end

@implementation GPUImageHarrisCornerDetectionFilter (Showcase)
- (id)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
		[output addTarget:self];
		self.cornersDetectedBlock = [self featureDetectionBlockWithSource:output targetView:view];
	}
	return self;
}

- (NSString *)sliderKeyPath { return @"threshold"; }
- (CGFloat)minSliderValue { return 0.01; }
- (CGFloat)maxSliderValue { return 0.7; }
@end

@implementation GPUImageHighPassFilter (Showcase)
- (NSString *)sliderKeyPath { return @"filterStrength"; }
@end

@implementation GPUImageHoughTransformLineDetector (Showcase)
- (id)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
		CGSize viewSize = [view sizeInPixels];
        GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
        [lineGenerator forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
        [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
        [self setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
            [lineGenerator renderLinesFromArray:lineArray count:linesDetected frameTime:frameTime];
        }];
        
        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        [blendFilter forceProcessingAtSize:viewSize];
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
        [output addTarget:gammaFilter];
        [gammaFilter addTarget:blendFilter];
        
        [lineGenerator addTarget:blendFilter];
        
        [blendFilter addTarget:view];
		[output addTarget:self];
	}
	return self;
}
- (NSString *)sliderKeyPath { return @"lineDetectionThreshold"; }
- (CGFloat)minSliderValue { return 0.2; }
@end

@implementation GPUImageLanczosResamplingFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageLaplacianFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageLineGenerator (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageLocalBinaryPatternFilter (Showcase)
- (NSString *)sliderKeyPath { return @"multiplier"; }
- (CGFloat)multiplier { return 1.; }
- (void)setMultiplier:(CGFloat)multiplier {
	CGSize size = [[self viewTarget] bounds].size;
	[self setTexelWidth:(multiplier / size.width)];
	[self setTexelHeight:(multiplier / size.height)];
}
- (CGFloat)minSliderValue { return 1.; }
- (CGFloat)maxSliderValue { return 5.; }
@end

@implementation GPUImageLowPassFilter (Showcase)
- (NSString *)sliderKeyPath { return @"filterStrength"; }
@end

@implementation GPUImageMedianFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageMotionDetector (Showcase)
- (NSString *)sliderKeyPath { return @"lowPassFilterStrength"; }
@end

@implementation GPUImageNobleCornerDetectionFilter (Showcase)
- (id)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
		[output addTarget:self];
		self.cornersDetectedBlock = [self featureDetectionBlockWithSource:output targetView:view];
	}
	return self;
}
- (NSString *)sliderKeyPath { return @"threshold"; }
- (CGFloat)minSliderValue { return 0.01; }
- (CGFloat)maxSliderValue { return 0.7; }
@end

@implementation GPUImageNonMaximumSuppressionFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageParallelCoordinateLineTransformFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImagePrewittEdgeDetectionFilter (Showcase)
- (NSString *)sliderKeyPath { return @"edgeStrength"; }
- (CGFloat)maxSliderValue { return 2.; }
@end

@implementation GPUImageSharpenFilter (Showcase)
- (NSString *)sliderKeyPath { return @"sharpness"; }
- (CGFloat)minSliderValue { return -1.; }
- (CGFloat)maxSliderValue { return 4.; }
@end

@implementation GPUImageShiTomasiFeatureDetectionFilter (Showcase)
- (id)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
		[output addTarget:self];
		self.cornersDetectedBlock = [self featureDetectionBlockWithSource:output targetView:view];
	}
	return self;
}
- (NSString *)sliderKeyPath { return @"threshold"; }
- (CGFloat)minSliderValue { return 0.01; }
- (CGFloat)maxSliderValue { return 0.7; }
@end

@implementation GPUImageSingleComponentGaussianBlurFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageSobelEdgeDetectionFilter (Showcase)
- (NSString *)sliderKeyPath { return @"edgeStrength"; }
- (CGFloat)maxSliderValue { return 2.; }
@end

@implementation GPUImageThresholdEdgeDetectionFilter (Showcase)
- (NSString *)sliderKeyPath { return @"threshold"; }
@end

@implementation GPUImageThresholdedNonMaximumSuppressionFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageTransformFilter (Showcase)
- (NSString *)sliderKeyPath { return @"rotation"; }
- (CGFloat)rotation { return 2.; }
- (void)setRotation:(CGFloat)rotation {
	self.affineTransform = CGAffineTransformMakeRotation(rotation);
}
- (CGFloat)maxSliderValue { return 2*M_PI; }
@end

@implementation GPUImageTransform3DFilter (Showcase)
- (NSString *)sliderKeyPath { return @"rotation"; }
- (CGFloat)rotation { return 0.75; }
- (void)setRotation:(CGFloat)rotation {
	CATransform3D perspectiveTransform = CATransform3DIdentity;
	perspectiveTransform.m34 = 0.4;
	perspectiveTransform.m33 = 0.4;
	perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75);
	perspectiveTransform = CATransform3DRotate(perspectiveTransform, rotation, 0.0, 1.0, 0.0);
	
	[self setTransform3D:perspectiveTransform];
}
- (CGFloat)maxSliderValue { return 2*M_PI; }
@end

@implementation GPUImageUnsharpMaskFilter (Showcase)
- (NSString *)sliderKeyPath { return @"intensity"; }
- (CGFloat)minSliderValue { return 0.; }
- (CGFloat)maxSliderValue { return 5.; }
@end

@implementation GPUImageWeakPixelInclusionFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageXYDerivativeFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageZoomBlurFilter (Showcase)
- (NSString *)sliderKeyPath { return @"blurSize"; }
- (CGFloat)maxSliderValue { return 2.5; }
@end

#pragma mark - Effects

@implementation GPUImageBulgeDistortionFilter (Showcase)
- (NSString *)sliderKeyPath { return @"scale"; }
- (CGFloat)minSliderValue { return -1; }
@end

@implementation GPUImageChromaKeyFilter (Showcase)
- (NSString *)sliderKeyPath { return @"thresholdSensitivity"; }
@end

@implementation GPUImageClosingFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageCrosshatchFilter (Showcase)
- (NSString *)sliderKeyPath { return @"crossHatchSpacing"; }
- (CGFloat)minSliderValue { return 0.01; }
- (CGFloat)maxSliderValue { return 0.06; }
@end

@implementation GPUImageDilationFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageEmbossFilter (Showcase)
- (NSString *)sliderKeyPath { return @"intensity"; }
- (CGFloat)maxSliderValue { return 5.; }
@end

@implementation GPUImageErosionFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageGlassSphereFilter (Showcase)
- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
		[self configureSphereWithSource:output targetView:view];
	}
	return self;
}
- (NSString *)sliderKeyPath { return @"radius"; }
@end

@implementation GPUImageHalftoneFilter (Showcase)
- (NSString *)sliderKeyPath { return @"fractionalWidthOfAPixel"; }
- (CGFloat)maxSliderValue { return 0.05; }
@end

@implementation GPUImageJFAVoronoiFilter (Showcase)
// FIXME: broken on develop, not sure how to fix
+ (BOOL)excludeFromShowcase { return YES; }
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageKuwaharaFilter (Showcase)
- (NSString *)sliderKeyPath { return @"radius"; }
- (CGFloat)minSliderValue { return 3.; }
- (CGFloat)maxSliderValue { return 8.; }
@end

@implementation GPUImageKuwaharaRadius3Filter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageMosaicFilter (Showcase)
- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [super initWithSource:output targetView:view];
	if (self) {
		[self setTileSet:@"squares.png"];
		self.colorOn = NO;
		[self setSizeComponent:0.025];
	}
	return self;
}
- (NSString *)sliderKeyPath { return @"sizeComponent"; }
- (CGFloat)sizeComponent { return 0.025; }
- (void)setSizeComponent:(CGFloat)component {
	self.displayTileSize = CGSizeMake(component, component);
}
- (CGFloat)minSliderValue { return 0.002; }
- (CGFloat)maxSliderValue { return 0.05; }
@end

@implementation GPUImageOpeningFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageMotionBlurFilter (Showcase)
- (NSString *)sliderKeyPath { return @"blurAngle"; }
- (CGFloat)maxSliderValue { return 180.; }
@end

@implementation GPUImagePerlinNoiseFilter (Showcase)
- (NSString *)sliderKeyPath { return @"scale"; }
- (CGFloat)maxSliderValue { return 30.; }
@end

@implementation GPUImagePinchDistortionFilter (Showcase)
- (NSString *)sliderKeyPath { return @"scale"; }
- (CGFloat)minSliderValue { return -2.; }
- (CGFloat)maxSliderValue { return 2.; }
@end

@implementation GPUImagePixellateFilter (Showcase)
- (NSString *)sliderKeyPath { return @"fractionalWidthOfAPixel"; }
- (CGFloat)maxSliderValue { return 0.3; }
@end

@implementation GPUImagePixellatePositionFilter (Showcase)
- (NSString *)sliderKeyPath { return @"fractionalWidthOfAPixel"; }
- (CGFloat)maxSliderValue { return 0.5; }
@end

@implementation GPUImagePolarPixellateFilter (Showcase)
- (NSString *)sliderKeyPath { return @"pixelSizeDiameter"; }
- (CGFloat)pixelSizeDiameter { return 0.05; }
- (void)setPixelSizeDiameter:(CGFloat)diameter {
	self.pixelSize = CGSizeMake(diameter, diameter);
}
- (CGFloat)minSliderValue { return -0.1; }
- (CGFloat)maxSliderValue { return 0.1; }
@end

@implementation GPUImagePolkaDotFilter (Showcase)
- (NSString *)sliderKeyPath { return @"fractionalWidthOfAPixel"; }
- (CGFloat)maxSliderValue { return 0.3; }
@end

@implementation GPUImagePosterizeFilter (Showcase)
- (NSString *)sliderKeyPath { return @"colorLevels"; }
- (CGFloat)minSliderValue { return 1.; }
- (CGFloat)maxSliderValue { return 20.; }
@end

@implementation GPUImageRGBClosingFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageRGBDilationFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageRGBErosionFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageRGBOpeningFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageSketchFilter (Showcase)
- (NSString *)sliderKeyPath { return @"edgeStrength"; }
- (CGFloat)maxSliderValue { return 2.; }
@end

@implementation GPUImageSmoothToonFilter (Showcase)
- (NSString *)sliderKeyPath { return @"blurRadiusInPixels"; }
- (CGFloat)minSliderValue { return 1.; }
- (CGFloat)maxSliderValue { return 6.; }
@end

@implementation GPUImageSphereRefractionFilter (Showcase)
- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [self init];
	if (self) {
		[self configureSphereWithSource:output targetView:view];
	}
	return self;
}

- (NSString *)sliderKeyPath { return @"radius"; }
@end

@implementation GPUImageStretchDistortionFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageSwirlFilter (Showcase)
- (NSString *)sliderKeyPath { return @"angle"; }
- (CGFloat)maxSliderValue { return 2.; }
@end

@implementation GPUImageThresholdSketchFilter (Showcase)
- (NSString *)sliderKeyPath { return @"threshold"; }
@end

@implementation GPUImageTiltShiftFilter (Showcase)
- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [super initWithSource:output targetView:view];
	if (self) {
		self.topFocusLevel = .4;
		self.bottomFocusLevel = .6;
		self.focusFallOffRate = .2;
	}
	return self;
}
- (NSString *)sliderKeyPath { return @"midpoint"; }
- (CGFloat)midpoint { return 0.5; }
- (void)setMidpoint:(CGFloat)midpoint {
	[self setTopFocusLevel:midpoint - 0.1];
	[self setBottomFocusLevel:midpoint + 0.1];
}
- (CGFloat)minSliderValue { return 0.2; }
- (CGFloat)maxSliderValue { return 0.8; }
@end

@implementation GPUImageToonFilter (Showcase)
- (BOOL)enableSlider { return NO; }
@end

@implementation GPUImageVignetteFilter (Showcase)
- (NSString *)sliderKeyPath { return @"vignetteEnd"; }
- (CGFloat)minSliderValue { return 0.5; }
- (CGFloat)maxSliderValue { return 0.9; }
@end

@implementation GPUImageVoronoiConsumerFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

#pragma mark - Blends

@implementation GPUImageAddBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageAlphaBlendFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageChromaKeyBlendFilter (Showcase)
- (NSString *)sliderKeyPath { return @"thresholdSensitivity"; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageColorBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageColorBurnBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageColorDodgeBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageDarkenBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageDifferenceBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageDissolveBlendFilter (Showcase)
- (NSString *)sliderKeyPath { return @"mix"; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageDivideBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageExclusionBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageHardLightBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageHueBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageLightenBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageLinearBurnBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageLuminosityBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageMaskFilter (Showcase)
- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view
{
	self = [super initWithSource:output targetView:view];
	if (self) {
		[self setBackgroundColorRed:0 green:1. blue:0. alpha:1.];
	}
	return self;
}
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
- (NSImage *)secondInputImage { return [NSImage imageNamed:@"mask"]; }
@end

@implementation GPUImageMultiplyBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageNormalBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageOverlayBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImagePoissonBlendFilter (Showcase)
// TODO: fix and re-enable
+ (BOOL)excludeFromShowcase { return YES; }
- (NSString *)sliderKeyPath { return @"mix"; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageSaturationBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageScreenBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageSoftLightBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end

@implementation GPUImageSourceOverBlendFilter (Showcase)
+ (BOOL)excludeFromShowcase { return YES; }
@end

@implementation GPUImageSubtractBlendFilter (Showcase)
- (BOOL)enableSlider { return NO; }
- (BOOL)needsSecondImage { return YES; }
@end
