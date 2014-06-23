
#import "GPUImageHueFilter.h"

// Adapted from http://stackoverflow.com/questions/9234724/how-to-change-hue-of-a-texture-with-glsl - see for code and discussion
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageHueFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform mediump float hueAdjust;
 const highp  vec4  kRGBToYPrime = vec4 (0.299, 0.587, 0.114, 0.0);
 const highp  vec4  kRGBToI     = vec4 (0.595716, -0.274453, -0.321263, 0.0);
 const highp  vec4  kRGBToQ     = vec4 (0.211456, -0.522591, 0.31135, 0.0);
 
 const highp  vec4  kYIQToR   = vec4 (1.0, 0.9563, 0.6210, 0.0);
 const highp  vec4  kYIQToG   = vec4 (1.0, -0.2721, -0.6474, 0.0);
 const highp  vec4  kYIQToB   = vec4 (1.0, -1.1070, 1.7046, 0.0);
 
 void main ()
 {
     // Sample the input pixel
     highp vec4 color   = texture2D(inputImageTexture, textureCoordinate);
     
     // Convert to YIQ
     highp float   YPrime  = dot (color, kRGBToYPrime);
     highp float   I      = dot (color, kRGBToI);
     highp float   Q      = dot (color, kRGBToQ);
     
     // Calculate the hue and chroma
     highp float   hue     = atan (Q, I);
     highp float   chroma  = sqrt (I * I + Q * Q);
     
     // Make the user's adjustments
     hue += (-hueAdjust); //why negative rotation?
     
     // Convert back to YIQ
     Q = chroma * sin (hue);
     I = chroma * cos (hue);
     
     // Convert back to RGB
     highp vec4    yIQ   = vec4 (YPrime, I, Q, 0.0);
     color.r = dot (yIQ, kYIQToR);
     color.g = dot (yIQ, kYIQToG);
     color.b = dot (yIQ, kYIQToB);
     
     // Save the result
     gl_FragColor = color;
 }
);
#else
NSString *const kGPUImageHueFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float hueAdjust;
 const vec4  kRGBToYPrime = vec4 (0.299, 0.587, 0.114, 0.0);
 const vec4  kRGBToI     = vec4 (0.595716, -0.274453, -0.321263, 0.0);
 const vec4  kRGBToQ     = vec4 (0.211456, -0.522591, 0.31135, 0.0);
 
 const vec4  kYIQToR   = vec4 (1.0, 0.9563, 0.6210, 0.0);
 const vec4  kYIQToG   = vec4 (1.0, -0.2721, -0.6474, 0.0);
 const vec4  kYIQToB   = vec4 (1.0, -1.1070, 1.7046, 0.0);
 
 void main ()
 {
     // Sample the input pixel
     vec4 color   = texture2D(inputImageTexture, textureCoordinate);
     
     // Convert to YIQ
     float   YPrime  = dot (color, kRGBToYPrime);
     float   I      = dot (color, kRGBToI);
     float   Q      = dot (color, kRGBToQ);
     
     // Calculate the hue and chroma
     float   hue     = atan (Q, I);
     float   chroma  = sqrt (I * I + Q * Q);
     
     // Make the user's adjustments
     hue += (-hueAdjust); //why negative rotation?
     
     // Convert back to YIQ
     Q = chroma * sin (hue);
     I = chroma * cos (hue);
     
     // Convert back to RGB
     vec4    yIQ   = vec4 (YPrime, I, Q, 0.0);
     color.r = dot (yIQ, kYIQToR);
     color.g = dot (yIQ, kYIQToG);
     color.b = dot (yIQ, kYIQToB);
     
     // Save the result
     gl_FragColor = color;
 }
);
#endif

@implementation GPUImageHueFilter
@synthesize hue;

- (id)init
{
    if(! (self = [super initWithFragmentShaderFromString:kGPUImageHueFragmentShaderString]) )
    {
        return nil;
    }
    
    hueAdjustUniform = [filterProgram uniformIndex:@"hueAdjust"];
    self.hue = 90;
    
    return self;
}

- (void)setHue:(CGFloat)newHue
{
    // Convert degrees to radians for hue rotation
    hue = fmodf(newHue, 360.0) * M_PI/180;
    [self setFloat:hue forUniform:hueAdjustUniform program:filterProgram];
}

@end
