#import "GPUImageChromaKeyFilter.h"

// Shader code based on Apple's CIChromaKeyFilter example: https://developer.apple.com/library/mac/#samplecode/CIChromaKeyFilter/Introduction/Intro.html

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageChromaKeyFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform float thresholdSensitivity;
 uniform float smoothing;
 uniform vec3 colorToReplace;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     float maskY = 0.2989 * colorToReplace.r + 0.5866 * colorToReplace.g + 0.1145 * colorToReplace.b;
     float maskCr = 0.7132 * (colorToReplace.r - maskY);
     float maskCb = 0.5647 * (colorToReplace.b - maskY);
     
     float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
     float Cr = 0.7132 * (textureColor.r - Y);
     float Cb = 0.5647 * (textureColor.b - Y);
     
     //     float blendValue = 1.0 - smoothstep(thresholdSensitivity - smoothing, thresholdSensitivity , abs(Cr - maskCr) + abs(Cb - maskCb));
     float blendValue = smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, distance(vec2(Cr, Cb), vec2(maskCr, maskCb)));
     gl_FragColor = vec4(textureColor.rgb, textureColor.a * blendValue);
 }
);
#else
NSString *const kGPUImageChromaKeyFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform float thresholdSensitivity;
 uniform float smoothing;
 uniform vec3 colorToReplace;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     float maskY = 0.2989 * colorToReplace.r + 0.5866 * colorToReplace.g + 0.1145 * colorToReplace.b;
     float maskCr = 0.7132 * (colorToReplace.r - maskY);
     float maskCb = 0.5647 * (colorToReplace.b - maskY);
     
     float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
     float Cr = 0.7132 * (textureColor.r - Y);
     float Cb = 0.5647 * (textureColor.b - Y);
     
     //     float blendValue = 1.0 - smoothstep(thresholdSensitivity - smoothing, thresholdSensitivity , abs(Cr - maskCr) + abs(Cb - maskCb));
     float blendValue = smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, distance(vec2(Cr, Cb), vec2(maskCr, maskCb)));
     gl_FragColor = vec4(textureColor.rgb, textureColor.a * blendValue);
 }
 );
#endif

@implementation GPUImageChromaKeyFilter

@synthesize thresholdSensitivity = _thresholdSensitivity;
@synthesize smoothing = _smoothing;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageChromaKeyFragmentShaderString]))
    {
		return nil;
    }
    
    thresholdSensitivityUniform = [filterProgram uniformIndex:@"thresholdSensitivity"];
    smoothingUniform = [filterProgram uniformIndex:@"smoothing"];
    colorToReplaceUniform = [filterProgram uniformIndex:@"colorToReplace"];
    
    self.thresholdSensitivity = 0.4;
    self.smoothing = 0.1;
    [self setColorToReplaceRed:0.0 green:1.0 blue:0.0];
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setColorToReplaceRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;
{
    GPUVector3 colorToReplace = {redComponent, greenComponent, blueComponent};
    
    [self setVec3:colorToReplace forUniform:colorToReplaceUniform program:filterProgram];
}

- (void)setThresholdSensitivity:(GLfloat)newValue;
{
    _thresholdSensitivity = newValue;
    
    [self setFloat:_thresholdSensitivity forUniform:thresholdSensitivityUniform program:filterProgram];
}

- (void)setSmoothing:(GLfloat)newValue;
{
    _smoothing = newValue;
    
    [self setFloat:_smoothing forUniform:smoothingUniform program:filterProgram];
}


@end
