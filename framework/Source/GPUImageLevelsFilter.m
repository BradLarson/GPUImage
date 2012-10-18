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

#define LevelsControlInputRange(color, minInput, maxInput)				min(max(color - minInput, 0.0) / (maxInput - minInput), 1.0)
#define LevelsControlInput(color, minInput, gamma, maxInput)				GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
#define LevelsControlOutputRange(color, minOutput, maxOutput) 			mix(minOutput, maxOutput, color)
#define LevelsControl(color, minInput, gamma, maxInput, minOutput, maxOutput) 	LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)

NSString *const kGPUImageLevelsFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float red[5];
 uniform lowp float green[5];
 uniform lowp float blue[5];
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(LevelsControl(textureColor.r, red[0], red[1], red[2], red[3], red[4]), LevelsControl(textureColor.g, green[0], green[1], green[2], green[3], green[4]), LevelsControl(textureColor.b, blue[0], blue[1], blue[2], blue[3], blue[4]), textureColor.a); 
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
    
    redUniform = [filterProgram uniformIndex:@"red"];
    greenUniform = [filterProgram uniformIndex:@"green"];
    blueUniform = [filterProgram uniformIndex:@"blue"];
    
    [self setRedMin:0.0 gamma:1.4 max:1.0 minOut:0.0 maxOut:1.0];
    [self setGreenMin:0.0 gamma:0.8 max:1.0 minOut:0.0 maxOut:1.0];
    [self setBlueMin:0.0 gamma:0.4 max:1.0 minOut:0.0 maxOut:1.0];
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setRedMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut {
    [self setFloat:min forUniform:redUniform program:filterProgram];
    [self setFloat:mid forUniform:redUniform + 1 program:filterProgram];
    [self setFloat:max forUniform:redUniform + 2 program:filterProgram];
    [self setFloat:minOut forUniform:redUniform + 3 program:filterProgram];
    [self setFloat:maxOut forUniform:redUniform + 4 program:filterProgram];
}

- (void)setRedMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max {
    [self setRedMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

- (void)setGreenMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut {
    [self setFloat:min forUniform:greenUniform program:filterProgram];
    [self setFloat:mid forUniform:greenUniform + 1 program:filterProgram];
    [self setFloat:max forUniform:greenUniform + 2 program:filterProgram];
    [self setFloat:minOut forUniform:greenUniform + 3 program:filterProgram];
    [self setFloat:maxOut forUniform:greenUniform + 4 program:filterProgram];
}

- (void)setGreenMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max {
    [self setGreenMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

- (void)setBlueMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max minOut:(CGFloat)minOut maxOut:(CGFloat)maxOut {
    [self setFloat:min forUniform:blueUniform program:filterProgram];
    [self setFloat:mid forUniform:blueUniform + 1 program:filterProgram];
    [self setFloat:max forUniform:blueUniform + 2 program:filterProgram];
    [self setFloat:minOut forUniform:blueUniform + 3 program:filterProgram];
    [self setFloat:maxOut forUniform:blueUniform + 4 program:filterProgram];
}

- (void)setBlueMin:(CGFloat)min gamma:(CGFloat)mid max:(CGFloat)max {
    [self setBlueMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

@end

