//
//  GPUVoroniConsumerFilter.m
//  Face Esplode
//
//  Created by Jacob Gundersen on 4/28/12.
//  Copyright (c) 2012 Interrobang Software LLC. All rights reserved.
//

#import "GPUImageVoroniConsumerFilter.h"

NSString *const kGPUImageVoroniConsumerFragmentShaderString = SHADER_STRING
(
 
 precision highp float;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 varying vec2 textureCoordinate;
 
 vec2 getCoordFromColor(vec4 color, vec2 size)
{
    float z = color.z * 256.0;
    float yoff = floor(z / 8.0);
    float xoff = mod(z, 8.0);
    float x = color.x*256.0 + xoff*256.0;
    float y = color.y*256.0 + yoff*256.0;
    return vec2(x,y) / size;
}

 void main(void) {
     vec4 colorLoc = texture2D(inputImageTexture2, textureCoordinate);
     vec4 color = texture2D(inputImageTexture, getCoordFromColor(colorLoc));
     gl_FragColor = color;	
 }

 
 );

@implementation GPUImageVoroniConsumerFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageVoroniConsumerFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

-(CGSize)sizeOfFBO {
    return CGSizeMake(256, 256);
}

@end
