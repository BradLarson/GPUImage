//
//  GPUImageVibranceFilter.m
//  
//
//  Created by github.com/r3mus on 8/13/15.
//
//

#import "GPUImageVibranceFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageVibranceFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;
 
    uniform sampler2D inputImageTexture;
    uniform lowp float vibrance;
 
    void main() {
        lowp vec4 color = texture2D(inputImageTexture, textureCoordinate);
        lowp float average = (color.r + color.g + color.b) / 3.0;
        lowp float mx = max(color.r, max(color.g, color.b));
        lowp float amt = (mx - average) * (-vibrance * 3.0);
        color.rgb = mix(color.rgb, vec3(mx), amt);
        gl_FragColor = color;
    }
);
#else
NSString *const kGPUImageVibranceFragmentShaderString = SHADER_STRING
(
    varying vec2 textureCoordinate;
 
    uniform sampler2D inputImageTexture;
    uniform float vibrance;
 
    void main() {
        vec4 color = texture2D(inputImageTexture, textureCoordinate);
        float average = (color.r + color.g + color.b) / 3.0;
        float mx = max(color.r, max(color.g, color.b));
        float amt = (mx - average) * (-vibrance * 3.0);
        color.rgb = mix(color.rgb, vec3(mx), amt);
        gl_FragColor = color;
    }
);
#endif

@implementation GPUImageVibranceFilter

@synthesize vibrance = _vibrance;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageVibranceFragmentShaderString]))
    {
        return nil;
    }
    
    vibranceUniform = [filterProgram uniformIndex:@"vibrance"];
    self.vibrance = 0.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setVibrance:(GLfloat)vibrance;
{
    _vibrance = vibrance;
    
    [self setFloat:_vibrance forUniform:vibranceUniform program:filterProgram];
}

@end

