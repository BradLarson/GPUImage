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

NSString *const kGPUImageLevelsFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp vec3 min;
 uniform lowp vec3 mid;
 uniform lowp vec3 max;
 uniform lowp vec3 minOutput;
 uniform lowp vec3 maxOutput;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(LevelsControl(textureColor.rgb, min, mid, max, minOutput, maxOutput), textureColor.a);
 }
 );

@implementation GPUImageLevelsFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageLevelsFragmentShaderString]))
    {
		return nil;
    }
    
    minUniform = [filterProgram uniformIndex:@"min"];
    midUniform = [filterProgram uniformIndex:@"mid"];
    maxUniform = [filterProgram uniformIndex:@"max"];
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

@end

