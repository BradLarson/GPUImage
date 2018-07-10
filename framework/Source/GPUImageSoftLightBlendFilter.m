#import "GPUImageSoftLightBlendFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageSoftLightBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 mediump vec4 unpremultiply(mediump vec4 s) {
     return vec4(s.rgb/max(s.a,0.00001), s.a);
 }
 
 mediump vec4 premultiply(mediump vec4 s) {
     return vec4(s.rgb * s.a, s.a);
 }
 
 mediump vec4 normalBlend(mediump vec4 Cb, mediump vec4 Cs) {
     mediump vec4 dst = premultiply(Cb);
     mediump vec4 src = premultiply(Cs);
     return unpremultiply(src + dst * (1.0 - src.a));
 }
 
 mediump vec4 blendBaseAlpha(mediump vec4 Cb, mediump vec4 Cs, mediump vec4 B) {
     mediump vec4 Cr = vec4((1.0 - Cb.a) * Cs.rgb + Cb.a * clamp(B.rgb, 0.0,  1.0), Cs.a);
     return normalBlend(Cb, Cr);
 }
 
 //  softLight, w3c
 mediump float softLightBlendSingleChannelD(mediump float b) {
     return b <= 0.25? (((16.0 * b - 12.0) * b + 4.0) * b): sqrt(b);
 }
 
 mediump float softLightBlendSingleChannel(mediump float b,mediump float s) {
     return s < 0.5? (b - (1.0 - 2.0 * s) * b * (1.0 - b)) : (b + (2.0 * s - 1.0) * (softLightBlendSingleChannelD(b) - b));
 }
 
 void main()
 {
     mediump vec4 Cb = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 Cs = texture2D(inputImageTexture2, textureCoordinate2);
     mediump vec4 B = vec4(softLightBlendSingleChannel(Cb.r, Cs.r), softLightBlendSingleChannel(Cb.g, Cs.g), softLightBlendSingleChannel(Cb.b, Cs.b), Cs.a);
     gl_FragColor = blendBaseAlpha(Cb, Cs, B);
 }
 
 );
#else
NSString *const kGPUImageSoftLightBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 vec4 unpremultiply(vec4 s) {
     return vec4(s.rgb/max(s.a,0.00001), s.a);
 }
 
 vec4 premultiply(vec4 s) {
     return vec4(s.rgb * s.a, s.a);
 }
 
 vec4 normalBlend(vec4 Cb, vec4 Cs) {
     mediump vec4 dst = premultiply(Cb);
     mediump vec4 src = premultiply(Cs);
     return unpremultiply(src + dst * (1.0 - src.a));
 }
 
 vec4 blendBaseAlpha(vec4 Cb, vec4 Cs,  vec4 B) {
     mediump vec4 Cr = vec4((1.0 - Cb.a) * Cs.rgb + Cb.a * clamp(B.rgb, 0.0,  1.0), Cs.a);
     return normalBlend(Cb, Cr);
 }
 
 //  softLight
 float softLightBlendSingleChannelD(float b) {
     return b <= 0.25? (((16.0 * b - 12.0) * b + 4.0) * b): sqrt(b);
 }
 
 float softLightBlendSingleChannel(float b, float s) {
     return s < 0.5? (b - (1.0 - 2.0 * s) * b * (1.0 - b)) : (b + (2.0 * s - 1.0) * (softLightBlendSingleChannelD(b) - b));
 }
 
 void main()
 {
     vec4 Cb = texture2D(inputImageTexture, textureCoordinate);
     vec4 Cs = texture2D(inputImageTexture2, textureCoordinate2);
     vec4 B = vec4(softLightBlendSingleChannel(Cb.r, Cs.r), softLightBlendSingleChannel(Cb.g, Cs.g), softLightBlendSingleChannel(Cb.b, Cs.b), Cs.a);
     gl_FragColor = blendBaseAlpha(Cb, Cs, B);
 }
 );
#endif

@implementation GPUImageSoftLightBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSoftLightBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

