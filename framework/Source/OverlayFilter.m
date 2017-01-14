//
//  OverlayFilter.m
//  GPUImage
//
//  Created by Shi Yan on 4/27/16.
//  Copyright © 2016 Brad Larson. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OverlayFilter.h"

//#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kOverlayFragmentShaderString = SHADER_STRING
(
 //uniform sampler2D textureMask;
 //varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D textureMask;
 
 void main() {
     //gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
    // gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
     lowp vec4 color = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 color2 = texture2D(textureMask, textureCoordinate);
     gl_FragColor.xyz = color2.xyz * color2.w + (1.0 - color2.w) * color.xyz;
     gl_FragColor.w = 1.0;

 }
 );
/*#else
NSString *const kOverlayFragmentShaderString = SHADER_STRING
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
*/
@implementation OverlayFilter

@synthesize overlayTexture = _overlayTexture;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kOverlayFragmentShaderString]))
    {
        return nil;
    }
    
    overlayTextureUniform = [filterProgram uniformIndex:@"textureMask"];
    
    //printf("init ...")
    
    return self;
}


#pragma mark -
#pragma mark Accessors

- (void)setOverlayTexture:(GLint)texture;
{
    _overlayTexture = texture;
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    [self setInteger:4 forUniform:overlayTextureUniform program:filterProgram];
}

@end