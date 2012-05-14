#import "GPUImageChromaKeyBlendFilter.h"

// Shader code based on Apple's CIChromaKeyFilter example: https://developer.apple.com/library/mac/#samplecode/CIChromaKeyFilter/Introduction/Intro.html

NSString *const kGPUImageChromaKeyBlendFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform float thresholdSensitivity;
 uniform float smoothing;
 uniform vec3 colorToReplace;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;
     vec3 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2).rgb;
     
     float maskY = 0.2989 * colorToReplace.r + 0.5866 * colorToReplace.g + 0.1145 * colorToReplace.b;
     float maskCr = 0.7132 * (colorToReplace.r - maskY);
     float maskCb = 0.5647 * (colorToReplace.b - maskY);
     
     float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
     float Cr = 0.7132 * (textureColor.r - Y);
     float Cb = 0.5647 * (textureColor.b - Y);
     
//     float blendValue = 1.0 - smoothstep(thresholdSensitivity - smoothing, thresholdSensitivity , abs(Cr - maskCr) + abs(Cb - maskCb));
     float blendValue = 1.0 - smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, distance(vec2(Cr, Cb), vec2(maskCr, maskCb)));
     gl_FragColor = vec4(mix(textureColor, textureColor2, blendValue), 1.0);
 }
 );

@implementation GPUImageChromaKeyBlendFilter

@synthesize thresholdSensitivity = _thresholdSensitivity;
@synthesize smoothing = _smoothing;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageChromaKeyBlendFragmentShaderString]))
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
    GLfloat colorToReplace[3];
    colorToReplace[0] = redComponent;
    colorToReplace[1] = greenComponent;    
    colorToReplace[2] = blueComponent;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform3fv(colorToReplaceUniform, 1, colorToReplace);    
}

- (void)setThresholdSensitivity:(CGFloat)newValue;
{
    _thresholdSensitivity = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(thresholdSensitivityUniform, _thresholdSensitivity);
}


- (void)setSmoothing:(CGFloat)newValue;
{
    _smoothing = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(smoothingUniform, _smoothing);
}

@end

