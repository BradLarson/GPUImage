#import "GPUImageLevelsFilter.h"

/*
 ** Gamma correction
 ** Details: http://blog.mouaif.org/2009/01/22/photoshop-gamma-correction-shader/
 */

#define GammaCorrection(color, gamma)								pow(color, 1.0 / gamma)

/*
 ** Levels control (input (+gamma), output)
 ** Details: http://blog.mouaif.org/2009/01/28/levels-control-shader/
 */

#define LevelsControlInputRange(color, minInput, maxInput)				min(max(color - minInput, vec3(0.0)) / (maxInput - minInput), vec3(1.0))
#define LevelsControlInput(color, minInput, gamma, maxInput)				GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
#define LevelsControlOutputRange(color, minOutput, maxOutput) 			mix(minOutput, maxOutput, color)
#define LevelsControl(color, minInput, gamma, maxInput, minOutput, maxOutput) 	LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageLevelsFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform mediump vec3 levelMinimum;
 uniform mediump vec3 levelMiddle;
 uniform mediump vec3 levelMaximum;
 uniform mediump vec3 minOutput;
 uniform mediump vec3 maxOutput;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(LevelsControl(textureColor.rgb, levelMinimum, levelMiddle, levelMaximum, minOutput, maxOutput), textureColor.a);
 }
);
#else
NSString *const kGPUImageLevelsFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform vec3 levelMinimum;
 uniform vec3 levelMiddle;
 uniform vec3 levelMaximum;
 uniform vec3 minOutput;
 uniform vec3 maxOutput;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(LevelsControl(textureColor.rgb, levelMinimum, levelMiddle, levelMaximum, minOutput, maxOutput), textureColor.a);
 }
);
#endif

@implementation GPUImageLevelsFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageLevelsFragmentShaderString]))
    {
		return nil;
    }
    
    minUniform = [filterProgram uniformIndex:@"levelMinimum"];
    midUniform = [filterProgram uniformIndex:@"levelMiddle"];
    maxUniform = [filterProgram uniformIndex:@"levelMaximum"];
    minOutputUniform = [filterProgram uniformIndex:@"minOutput"];
    maxOutputUniform = [filterProgram uniformIndex:@"maxOutput"];
    
    [self setRedMin:0.0 gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
    [self setGreenMin:0.0 gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
    [self setBlueMin:0.0 gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
    
    return self;
}

#pragma mark -
#pragma mark Helpers

- (void)updateUniforms {
    [self setVec3:minVector forUniform:minUniform program:filterProgram];
    [self setVec3:midVector forUniform:midUniform program:filterProgram];
    [self setVec3:maxVector forUniform:maxUniform program:filterProgram];
    [self setVec3:minOutputVector forUniform:minOutputUniform program:filterProgram];
    [self setVec3:maxOutputVector forUniform:maxOutputUniform program:filterProgram];
}

#pragma mark -
#pragma mark Accessors

- (void)setMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut {
    [self setRedMin:min gamma:mid max:max minOut:minOut maxOut:maxOut];
    [self setGreenMin:min gamma:mid max:max minOut:minOut maxOut:maxOut];
    [self setBlueMin:min gamma:mid max:max minOut:minOut maxOut:maxOut];
}

- (void)setMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max {
    [self setMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

- (void)setRedMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut {
    minVector.one = min;
    midVector.one = mid;
    maxVector.one = max;
    minOutputVector.one = minOut;
    maxOutputVector.one = maxOut;
    
    [self updateUniforms];
}

- (void)setRedMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max {
    [self setRedMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

- (void)setGreenMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut {
    minVector.two = min;
    midVector.two = mid;
    maxVector.two = max;
    minOutputVector.two = minOut;
    maxOutputVector.two = maxOut;
    
    [self updateUniforms];
}

- (void)setGreenMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max {
    [self setGreenMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

- (void)setBlueMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut {
    minVector.three = min;
    midVector.three = mid;
    maxVector.three = max;
    minOutputVector.three = minOut;
    maxOutputVector.three = maxOut;
    
    [self updateUniforms];
}

- (void)setBlueMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max {
    [self setBlueMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

- (float)getRedMin {
    return minVector.one;
}

- (float)getRedMid {
    return midVector.one;
}

- (float)getRedMax {
    return maxVector.one;
}

- (float)getRedMinOut {
    return minOutputVector.one;
}

- (float)getRedMaxOut {
    return maxOutputVector.one;
}

- (float)getGreenMin {
    return minVector.two;
}

- (float)getGreenMid {
    return midVector.two;
}

- (float)getGreenMax {
    return maxVector.two;
}

- (float)getGreenMinOut {
    return minOutputVector.two;
}

- (float)getGreenMaxOut {
    return maxOutputVector.two;
}

- (float)getBlueMin {
    return minVector.three;
}

- (float)getBlueMid {
    return midVector.three;
}

- (float)getBlueMax {
    return maxVector.three;
}

- (float)getBlueMinOut {
    return minOutputVector.three;
}

- (float)getBlueMaxOut {
    return maxOutputVector.three;
}

- (void)setRedMin:(float)value {
    minVector.one = value;
    [self updateUniforms];
}

- (void)setRedMid:(float)value {
    midVector.one = value;
    [self updateUniforms];
}

- (void)setRedMax:(float)value {
    maxVector.one = value;
    [self updateUniforms];
}

- (void)setRedMinOut:(float)value {
    minOutputVector.one = value;
    [self updateUniforms];
}

- (void)setRedMaxOut:(float)value {
    maxOutputVector.one = value;
    [self updateUniforms];
}

- (void)setGreenMin:(float)value {
    minVector.two = value;
    [self updateUniforms];
}

- (void)setGreenMid:(float)value {
    midVector.two = value;
    [self updateUniforms];
}

- (void)setGreenMax:(float)value {
    maxVector.two = value;
    [self updateUniforms];
}

- (void)setGreenMinOut:(float)value {
    minOutputVector.two = value;
    [self updateUniforms];
}

- (void)setGreenMaxOut:(float)value {
    maxOutputVector.two = value;
    [self updateUniforms];
}

- (void)setBlueMin:(float)value {
    minVector.three = value;
    [self updateUniforms];
}

- (void)setBlueMid:(float)value {
    midVector.three = value;
    [self updateUniforms];
}

- (void)setBlueMax:(float)value {
    maxVector.three = value;
    [self updateUniforms];
}

- (void)setBlueMinOut:(float)value {
    minOutputVector.three = value;
    [self updateUniforms];
}

- (void)setBlueMaxOut:(float)value {
    maxOutputVector.three = value;
    [self updateUniforms];
}

@end

