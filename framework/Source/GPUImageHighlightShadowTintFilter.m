//
//  GPUImageHighlightShadowTintFilter.m
//
//  Created by github.com/r3mus on 8/14/15.
//
//

#import "GPUImageHighlightShadowTintFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUHighlightShadowTintFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float shadowTintIntensity;
 uniform lowp float highlightTintIntensity;
 uniform highp vec4 shadowTintColor;
 uniform highp vec4 highlightTintColor;
 
 const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    highp float luminance = dot(textureColor.rgb, luminanceWeighting);
     
    highp vec4 shadowResult = mix(textureColor, max(textureColor, vec4( mix(shadowTintColor.rgb, textureColor.rgb, luminance), textureColor.a)), shadowTintIntensity);
    highp vec4 highlightResult = mix(textureColor, min(shadowResult, vec4( mix(shadowResult.rgb, highlightTintColor.rgb, luminance), textureColor.a)), highlightTintIntensity);

    gl_FragColor = vec4( mix(shadowResult.rgb, highlightResult.rgb, luminance), textureColor.a);
 }
 );
#else
NSString *const kGPUHighlightShadowTintFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float shadowTintIntensity;
 uniform float highlightTintIntensity;
 uniform vec3 shadowTintColor;
 uniform vec3 highlightTintColor;
 
 const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
     
    vec4 shadowResult = mix(textureColor, max(textureColor, vec4( mix(shadowTintColor.rgb, textureColor.rgb, luminance), textureColor.a)), shadowTintIntensity);
    vec4 highlightResult = mix(textureColor, min(shadowResult, vec4( mix(shadowResult.rgb, highlightTintColor.rgb, luminance), textureColor.a)), highlightTintIntensity);
     
    gl_FragColor = vec4( mix(shadowResult.rgb, highlightResult.rgb, luminance), textureColor.a);
 }
 );
#endif


@implementation GPUImageHighlightShadowTintFilter

@synthesize shadowTintIntensity = _shadowTintIntensity;
@synthesize highlightTintIntensity = _highlightTintIntensity;
@synthesize shadowTintColor = _shadowTintColor;
@synthesize highlightTintColor = _highlightTintColor;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUHighlightShadowTintFragmentShaderString]))
    {
        return nil;
    }
    
    shadowTintIntensityUniform = [filterProgram uniformIndex:@"shadowTintIntensity"];
    highlightTintIntensityUniform = [filterProgram uniformIndex:@"highlightTintIntensity"];
    shadowTintColorUniform = [filterProgram uniformIndex:@"shadowTintColor"];
    highlightTintColorUniform = [filterProgram uniformIndex:@"highlightTintColor"];
    
    self.shadowTintIntensity = 0.0f;
    self.highlightTintIntensity = 0.0f;
    self.shadowTintColor = (GPUVector4){1.0f, 0.0f, 0.0f, 1.0f};
    self.highlightTintColor = (GPUVector4){0.0f, 0.0f, 1.0f, 1.0f};
    
    return self;
}


#pragma mark -
#pragma mark Accessors

- (void)setShadowTintIntensity:(GLfloat)newValue
{
    _shadowTintIntensity = newValue;
    
    [self setFloat:_shadowTintIntensity forUniform:shadowTintIntensityUniform program:filterProgram];
}

- (void)setHighlightTintIntensity:(GLfloat)newValue
{
    _highlightTintIntensity = newValue;
    
    [self setFloat:_highlightTintIntensity forUniform:highlightTintIntensityUniform program:filterProgram];
}

- (void)setShadowTintColor:(GPUVector4)newValue;
{
    _shadowTintColor = newValue;
    
    [self setShadowTintColorRed:_shadowTintColor.one green:_shadowTintColor.two blue:_shadowTintColor.three alpha:_shadowTintColor.four];
}

- (void)setHighlightTintColor:(GPUVector4)newValue;
{
    _highlightTintColor = newValue;
    
    [self setHighlightTintColorRed:_highlightTintColor.one green:_highlightTintColor.two blue:_highlightTintColor.three alpha:_highlightTintColor.four];
}

- (void)setShadowTintColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
{
    GPUVector4 shadowTintColor = {redComponent, greenComponent, blueComponent, alphaComponent};
    
    [self setVec4:shadowTintColor forUniform:shadowTintColorUniform program:filterProgram];
}

- (void)setHighlightTintColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
{
    GPUVector4 highlightTintColor = {redComponent, greenComponent, blueComponent, alphaComponent};
    
    [self setVec4:highlightTintColor forUniform:highlightTintColorUniform program:filterProgram];
}

@end