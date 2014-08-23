//
//  GPUImageHistogramEqualizationFilter.m
//  FilterShowcase
//
//  Created by Adam Marcus on 19/08/2014.
//  Copyright (c) 2014 Sunset Lake Software LLC. All rights reserved.
//

#import "GPUImageHistogramEqualizationFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageRedHistogramEqualizationFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     lowp float redCurveValue = texture2D(inputImageTexture2, vec2(textureColor.r, 0.0)).r;
     
     gl_FragColor = vec4(redCurveValue, textureColor.g, textureColor.b, textureColor.a);
 }
 );
#else
NSString *const kGPUImageRedHistogramEqualizationFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     float redCurveValue = texture2D(inputImageTexture2, vec2(textureColor.r, 0.0)).r;
     
     gl_FragColor = vec4(redCurveValue, textureColor.g, textureColor.b, textureColor.a);
 }
 );
#endif

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageGreenHistogramEqualizationFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     lowp float greenCurveValue = texture2D(inputImageTexture2, vec2(textureColor.g, 0.0)).g;
     
     gl_FragColor = vec4(textureColor.r, greenCurveValue, textureColor.b, textureColor.a);
 }
 );
#else
NSString *const kGPUImageGreenHistogramEqualizationFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     float greenCurveValue = texture2D(inputImageTexture2, vec2(textureColor.g, 0.0)).g;
     
     gl_FragColor = vec4(textureColor.r, greenCurveValue, textureColor.b, textureColor.a);
 }
 );
#endif

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageBlueHistogramEqualizationFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     lowp float blueCurveValue = texture2D(inputImageTexture2, vec2(textureColor.b, 0.0)).b;
     
     gl_FragColor = vec4(textureColor.r, textureColor.g, blueCurveValue, textureColor.a);
 }
 );
#else
NSString *const kGPUImageBlueHistogramEqualizationFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     float blueCurveValue = texture2D(inputImageTexture2, vec2(textureColor.b, 0.0)).b;
     
     gl_FragColor = vec4(textureColor.r, textureColor.g, blueCurveValue, textureColor.a);
 }
 );
#endif

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageRGBHistogramEqualizationFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate; 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     lowp float redCurveValue = texture2D(inputImageTexture2, vec2(textureColor.r, 0.0)).r;
     lowp float greenCurveValue = texture2D(inputImageTexture2, vec2(textureColor.g, 0.0)).g;
     lowp float blueCurveValue = texture2D(inputImageTexture2, vec2(textureColor.b, 0.0)).b;
     
     gl_FragColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
 }
 );
#else
NSString *const kGPUImageRGBHistogramEqualizationFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     float redCurveValue = texture2D(inputImageTexture2, vec2(textureColor.r, 0.0)).r;
     float greenCurveValue = texture2D(inputImageTexture2, vec2(textureColor.g, 0.0)).g;
     float blueCurveValue = texture2D(inputImageTexture2, vec2(textureColor.b, 0.0)).b;
     
     gl_FragColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
 }
 );
#endif

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageLuminanceHistogramEqualizationFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 const lowp vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     lowp float luminance = dot(textureColor.rgb, W);
     lowp float newLuminance = texture2D(inputImageTexture2, vec2(luminance, 0.0)).r;
     lowp float deltaLuminance = newLuminance - luminance;
     
     lowp float red   = clamp(textureColor.r + deltaLuminance, 0.0, 1.0);
     lowp float green = clamp(textureColor.g + deltaLuminance, 0.0, 1.0);
     lowp float blue  = clamp(textureColor.b + deltaLuminance, 0.0, 1.0);

     gl_FragColor = vec4(red, green, blue, textureColor.a);
 }
 );
#else
NSString *const kGPUImageLuminanceHistogramEqualizationFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 const vec3 W = vec3(0.2125, 0.7154, 0.0721);

 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     float luminance = dot(textureColor.rgb, W);
     float newLuminance = texture2D(inputImageTexture2, vec2(luminance, 0.0)).r;
     float deltaLuminance = newLuminance - luminance;
     
     float red   = clamp(textureColor.r + deltaLuminance, 0.0, 1.0);
     float green = clamp(textureColor.g + deltaLuminance, 0.0, 1.0);
     float blue  = clamp(textureColor.b + deltaLuminance, 0.0, 1.0);
     
     gl_FragColor = vec4(red, green, blue, textureColor.a);
 }
 );
#endif

@implementation GPUImageHistogramEqualizationFilter

@synthesize downsamplingFactor = _downsamplingFactor;

#pragma mark -
#pragma mark Initialization

- (id)init;
{
    if (!(self = [self initWithHistogramType:kGPUImageHistogramRGB]))
    {
        return nil;
    }
    
    return self;
}

- (id)initWithHistogramType:(GPUImageHistogramType)newHistogramType
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    histogramFilter = [[GPUImageHistogramFilter alloc] initWithHistogramType:newHistogramType];
    [self addFilter:histogramFilter];
    
    GLubyte dummyInput[4 * 256]; // NB: No way to initialise GPUImageRawDataInput without providing bytes
    rawDataInputFilter = [[GPUImageRawDataInput alloc] initWithBytes:dummyInput size:CGSizeMake(256.0, 1.0) pixelFormat:GPUPixelFormatBGRA type:GPUPixelTypeUByte];
    rawDataOutputFilter = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(256.0, 3.0) resultsInBGRAFormat:YES];
    
    __unsafe_unretained GPUImageRawDataOutput *_rawDataOutputFilter = rawDataOutputFilter;
    __unsafe_unretained GPUImageRawDataInput *_rawDataInputFilter = rawDataInputFilter;
    [rawDataOutputFilter setNewFrameAvailableBlock:^{
        
        unsigned int histogramBins[3][256];
        
        [_rawDataOutputFilter lockFramebufferForReading];
        
        GLubyte *data  = [_rawDataOutputFilter rawBytesForImage];
        data += [_rawDataOutputFilter bytesPerRowInOutput];

        histogramBins[0][0] = *data++;
        histogramBins[1][0] = *data++;
        histogramBins[2][0] = *data++;
        data++;
        
        for (unsigned int x = 1; x < 256; x++) {
            histogramBins[0][x] = histogramBins[0][x-1] + *data++;
            histogramBins[1][x] = histogramBins[1][x-1] + *data++;
            histogramBins[2][x] = histogramBins[2][x-1] + *data++;
            data++;
        }
        
        [_rawDataOutputFilter unlockFramebufferAfterReading];

        GLubyte colorMapping[4 * 256];
        GLubyte *_colorMapping = colorMapping;
        
        for (unsigned int x = 0; x < 256; x++) {
            *_colorMapping++ = (GLubyte) (((histogramBins[0][x] - histogramBins[0][0]) * 255) / histogramBins[0][255]);
            *_colorMapping++ = (GLubyte) (((histogramBins[1][x] - histogramBins[1][0]) * 255) / histogramBins[1][255]);
            *_colorMapping++ = (GLubyte) (((histogramBins[2][x] - histogramBins[2][0]) * 255) / histogramBins[2][255]);
            *_colorMapping++ = 255;
        }
        
        _colorMapping = colorMapping;
        [_rawDataInputFilter updateDataFromBytes:_colorMapping size:CGSizeMake(256.0, 1.0)];
        [_rawDataInputFilter processData];
    }];
    [histogramFilter addTarget:rawDataOutputFilter];
    
    NSString *fragmentShader = nil;
    switch (newHistogramType) {
        case kGPUImageHistogramRed:
            fragmentShader = kGPUImageRedHistogramEqualizationFragmentShaderString;
            break;
        case kGPUImageHistogramGreen:
            fragmentShader = kGPUImageGreenHistogramEqualizationFragmentShaderString;
            break;
        case kGPUImageHistogramBlue:
            fragmentShader = kGPUImageBlueHistogramEqualizationFragmentShaderString;
            break;
        default:
        case kGPUImageHistogramRGB:
            fragmentShader = kGPUImageRGBHistogramEqualizationFragmentShaderString;
            break;
        case kGPUImageHistogramLuminance:
            fragmentShader = kGPUImageLuminanceHistogramEqualizationFragmentShaderString;
            break;
    }
    GPUImageFilter *equalizationFilter = [[GPUImageTwoInputFilter alloc] initWithFragmentShaderFromString:fragmentShader];
    [rawDataInputFilter addTarget:equalizationFilter atTextureLocation:1];
    
    [self addFilter:equalizationFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:histogramFilter, equalizationFilter, nil];
    self.terminalFilter = equalizationFilter;
    
    self.downsamplingFactor = 16;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setDownsamplingFactor:(NSUInteger)newValue;
{
    if (_downsamplingFactor != newValue)
    {
        _downsamplingFactor = newValue;
        histogramFilter.downsamplingFactor = newValue;
    }
}

@end
