//
//  GPUImageColorBlendFilter.m
//  GPUImage
//
//  Created by Mihai Fratu on 9/5/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageColorBlendFilter.h"

NSString *const kGPUImageColorBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
	 highp vec4 baseColor = texture2D(inputImageTexture, textureCoordinate);
	 highp vec4 overlayColor = texture2D(inputImageTexture2, textureCoordinate2);

     // Calculate the lightness of the baseColor
     highp float red = baseColor.r / 255.0;
     highp float green = baseColor.g / 255.0;
     highp float blue = baseColor.b / 255.0;
	 
     highp float minColor = 2.0;
     if (red < minColor) {
         minColor = red;
     }
     if (green < minColor) {
         minColor = green;
     }
     if (blue < minColor) {
         minColor = blue;
     }
     
     highp float maxColor = -1.0;
     if (red > maxColor) {
         maxColor = red;
     }
     if (green > maxColor) {
         maxColor = green;
     }
     if (blue > maxColor) {
         maxColor = blue;
     }
     highp float baseLightness = (minColor + maxColor) / 2.0;
     
     // Calculate the lightness, saturation and hue of the overlayColor
     
     red = overlayColor.r / 255.0;
     green = overlayColor.g / 255.0;
     blue = overlayColor.b / 255.0;
	 
     minColor = 2.0;
     if (red < minColor) {
         minColor = red;
     }
     if (green < minColor) {
         minColor = green;
     }
     if (blue < minColor) {
         minColor = blue;
     }
     
     maxColor = -1.0;
     if (red > maxColor) {
         maxColor = red;
     }
     if (green > maxColor) {
         maxColor = green;
     }
     if (blue > maxColor) {
         maxColor = blue;
     }
     highp float overlayLightness = (minColor + maxColor) / 2.0;
     
     highp float overlaySaturation = 0.0;
     
     if (minColor != maxColor) {
         if (overlayLightness < 0.5) {
             overlaySaturation = (maxColor - minColor) / (maxColor + minColor);
         }
         else {
             overlaySaturation = (maxColor - minColor) / (2.0 - maxColor - minColor);
         }
     }
     
     highp float overlayHue = 0.0;
          
     if (overlaySaturation != 0.0) {
         if (red == maxColor) {
             overlayHue = (overlayColor.g - overlayColor.b) / (maxColor - minColor);
         }
         else if (green == maxColor) {
             overlayHue = 2.0 + (overlayColor.b - overlayColor.r) / (maxColor - minColor);
         }
         else if (blue == maxColor) {
             overlayHue = 4.0 + (overlayColor.r - overlayColor.g) / (maxColor - minColor);
         }
     }
     
     overlayHue = overlayHue * 60.0;
     if (overlayHue < 0.0) {
         overlayHue = overlayHue + 360.0;
     }
     
     //overlayHue = 0.0;
          
     // Calculate the resulting RGB value by using the baseLightness, overlaySaturation and overlayHue
     
     highp float r = 0.0;
     highp float g = 0.0;
     highp float b = 0.0;

     if (overlaySaturation == 0.0) {
         r = g = b = 255.0 * baseLightness;
     }
     else {
         highp float temp1 = 0.0;
         if (baseLightness < 0.5) {
             temp1 = baseLightness * (1.0 + overlaySaturation);
         }
         else {
             temp1 = baseLightness + overlaySaturation - overlaySaturation * baseLightness;
         }
         highp float temp2 = 2.0 * baseLightness - temp1;
         overlayHue = overlayHue / 360.0;
         
         highp float tempR = overlayHue + 0.333;
         if (tempR < 0.0) {
             tempR = tempR + 1.0;
         }
         else if (tempR > 1.0) {
             tempR = tempR - 1.0;
         }
         
         if (6.0 * tempR < 1.0) {
             r = temp2 + (temp1 - temp2) * 6.0 * tempR;
         }
         else if (2.0 * tempR < 1.0) {
             r = temp1;
         }
         else if (3.0 * tempR < 2.0) {
             r = temp2 + (temp1 - temp2) * (0.666 - tempR) * 6.0;
         }
         else {
             r = temp2;
         }
         
         highp float tempG = overlayHue;
         if (tempG < 0.0) {
             tempG = tempG + 1.0;
         }
         else if (tempG > 1.0) {
             tempG = tempG - 1.0;
         }
         
         if (6.0 * tempG < 1.0) {
             g = temp2 + (temp1 - temp2) * 6.0 * tempG;
         }
         else if (2.0 * tempG < 1.0) {
             g = temp1;
         }
         else if (3.0 * tempG < 2.0) {
             g = temp2 + (temp1 - temp2) * (0.666 - tempG) * 6.0;
         }
         else {
             g = temp2;
         }
         
         highp float tempB = overlayHue - 0.333;
         if (tempB < 0.0) {
             tempB = tempB + 1.0;
         }
         else if (tempB > 1.0) {
             tempB = tempB - 1.0;
         }
         
         if (6.0 * tempB < 1.0) {
             b = temp2 + (temp1 - temp2) * 6.0 * tempB;
         }
         else if (2.0 * tempB < 1.0) {
             b = temp1;
         }
         else if (3.0 * tempB < 2.0) {
             b = temp2 + (temp1 - temp2) * (0.666 - tempB) * 6.0;
         }
         else {
             b = temp2;
         }
         
         r = r * 255.0;
         g = g * 255.0;
         b = b * 255.0;
     }
     
	 gl_FragColor = vec4(r, g, b, baseColor.a);
     //gl_FragColor = overlayColor;
 }
 );


@implementation GPUImageColorBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageColorBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end