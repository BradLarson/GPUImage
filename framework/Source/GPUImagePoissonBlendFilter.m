#import "GPUImagePoissonBlendFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImagePoissonBlendFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 varying vec2 topTextureCoordinate;
 varying vec2 bottomTextureCoordinate;
 
 varying vec2 textureCoordinate2;
 varying vec2 leftTextureCoordinate2;
 varying vec2 rightTextureCoordinate2;
 varying vec2 topTextureCoordinate2;
 varying vec2 bottomTextureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform lowp float mixturePercent;

 void main()
 {
     vec4 centerColor = texture2D(inputImageTexture, textureCoordinate);
     vec3 bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
     vec3 leftColor = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
     vec3 rightColor = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
     vec3 topColor = texture2D(inputImageTexture, topTextureCoordinate).rgb;

     vec4 centerColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     vec3 bottomColor2 = texture2D(inputImageTexture2, bottomTextureCoordinate2).rgb;
     vec3 leftColor2 = texture2D(inputImageTexture2, leftTextureCoordinate2).rgb;
     vec3 rightColor2 = texture2D(inputImageTexture2, rightTextureCoordinate2).rgb;
     vec3 topColor2 = texture2D(inputImageTexture2, topTextureCoordinate2).rgb;

     vec3 meanColor = (bottomColor + leftColor + rightColor + topColor) / 4.0;
     vec3 diffColor = centerColor.rgb - meanColor;

     vec3 meanColor2 = (bottomColor2 + leftColor2 + rightColor2 + topColor2) / 4.0;
     vec3 diffColor2 = centerColor2.rgb - meanColor2;
     
     vec3 gradColor = (meanColor + diffColor2);
     
	 gl_FragColor = vec4(mix(centerColor.rgb, gradColor, centerColor2.a * mixturePercent), centerColor.a);
 }
);
#else
NSString *const kGPUImagePoissonBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 varying vec2 topTextureCoordinate;
 varying vec2 bottomTextureCoordinate;
 
 varying vec2 textureCoordinate2;
 varying vec2 leftTextureCoordinate2;
 varying vec2 rightTextureCoordinate2;
 varying vec2 topTextureCoordinate2;
 varying vec2 bottomTextureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform float mixturePercent;
 
 void main()
 {
     vec4 centerColor = texture2D(inputImageTexture, textureCoordinate);
     vec3 bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
     vec3 leftColor = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
     vec3 rightColor = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
     vec3 topColor = texture2D(inputImageTexture, topTextureCoordinate).rgb;
     
     vec4 centerColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     vec3 bottomColor2 = texture2D(inputImageTexture2, bottomTextureCoordinate2).rgb;
     vec3 leftColor2 = texture2D(inputImageTexture2, leftTextureCoordinate2).rgb;
     vec3 rightColor2 = texture2D(inputImageTexture2, rightTextureCoordinate2).rgb;
     vec3 topColor2 = texture2D(inputImageTexture2, topTextureCoordinate2).rgb;
     
     vec3 meanColor = (bottomColor + leftColor + rightColor + topColor) / 4.0;
     vec3 diffColor = centerColor.rgb - meanColor;
     
     vec3 meanColor2 = (bottomColor2 + leftColor2 + rightColor2 + topColor2) / 4.0;
     vec3 diffColor2 = centerColor2.rgb - meanColor2;
     
     vec3 gradColor = (meanColor + diffColor2);
     
	 gl_FragColor = vec4(mix(centerColor.rgb, gradColor, centerColor2.a * mixturePercent), centerColor.a);
 }
);
#endif

@implementation GPUImagePoissonBlendFilter

@synthesize mix = _mix;
@synthesize numIterations = _numIterations;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImagePoissonBlendFragmentShaderString]))
    {
		return nil;
    }
    
    mixUniform = [filterProgram uniformIndex:@"mixturePercent"];
    self.mix = 0.5;
    
    self.numIterations = 10;
    
    return self;
}

- (void)setMix:(CGFloat)newValue;
{
    _mix = newValue;
    
    [self setFloat:_mix forUniform:mixUniform program:filterProgram];
}

//- (void)setOutputFBO;
//{
//    if (self.numIterations % 2 == 1) {
//        [self setSecondFilterFBO];
//    } else {
//        [self setFilterFBO];
//    }
//}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    // Run the first stage of the two-pass filter
    [GPUImageContext setActiveShaderProgram:filterProgram];
    
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates];
    
    for (int pass = 1; pass < self.numIterations; pass++) {
        
        if (pass % 2 == 0) {
            
            [GPUImageContext setActiveShaderProgram:filterProgram];
            
            // TODO: This will over-unlock the incoming framebuffer
            [super renderToTextureWithVertices:vertices textureCoordinates:[[self class] textureCoordinatesForRotation:kGPUImageNoRotation]];
        } else {
            // Run the second stage of the two-pass filter
            secondOutputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
            [secondOutputFramebuffer activateFramebuffer];
            
            [GPUImageContext setActiveShaderProgram:filterProgram];
            
            glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
            glClear(GL_COLOR_BUFFER_BIT);
            
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, [outputFramebuffer texture]);
            glUniform1i(filterInputTextureUniform, 2);
            
            glActiveTexture(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_2D, [secondInputFramebuffer texture]);
            glUniform1i(filterInputTextureUniform2, 3);
            
            glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
            glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [[self class] textureCoordinatesForRotation:kGPUImageNoRotation]);
            glVertexAttribPointer(filterSecondTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [[self class] textureCoordinatesForRotation:inputRotation2]);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);            
        }
    }
}

@end