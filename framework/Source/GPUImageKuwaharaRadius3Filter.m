#import "GPUImageKuwaharaRadius3Filter.h"

// Sourced from Kyprianidis, J. E., Kang, H., and Doellner, J. "Anisotropic Kuwahara Filtering on the GPU," GPU Pro p.247 (2010).
//
// Original header:
//
// Anisotropic Kuwahara Filtering on the GPU
// by Jan Eric Kyprianidis <www.kyprianidis.com>

NSString *const kGPUImageKuwaharaRadius3FragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;

 precision highp float;

 const vec2 src_size = vec2 (1.0 / 768.0, 1.0 / 1024.0);

 void main (void)
 {
     vec2 uv = textureCoordinate;
     float n = float(16); // radius is assumed to be 3
     vec3 m0 = vec3(0.0); vec3 m1 = vec3(0.0); vec3 m2 = vec3(0.0); vec3 m3 = vec3(0.0);
     vec3 s0 = vec3(0.0); vec3 s1 = vec3(0.0); vec3 s2 = vec3(0.0); vec3 s3 = vec3(0.0);
     vec3 c;
     vec3 cSq;

     c = texture2D(inputImageTexture, uv + vec2(-3,-3) * src_size).rgb;
     m0 += c;
     s0 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-3,-2) * src_size).rgb;
     m0 += c;
     s0 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-3,-1) * src_size).rgb;
     m0 += c;
     s0 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-3,0) * src_size).rgb;
     cSq = c * c;
     m0 += c;
     s0 += cSq;
     m1 += c;
     s1 += cSq;

     c = texture2D(inputImageTexture, uv + vec2(-2,-3) * src_size).rgb;
     m0 += c;
     s0 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-2,-2) * src_size).rgb;
     m0 += c;
     s0 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-2,-1) * src_size).rgb;
     m0 += c;
     s0 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-2,0) * src_size).rgb;
     cSq = c * c;
     m0 += c;
     s0 += cSq;
     m1 += c;
     s1 += cSq;

     c = texture2D(inputImageTexture, uv + vec2(-1,-3) * src_size).rgb;
     m0 += c;
     s0 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-1,-2) * src_size).rgb;
     m0 += c;
     s0 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-1,-1) * src_size).rgb;
     m0 += c;
     s0 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-1,0) * src_size).rgb;
     cSq = c * c;
     m0 += c;
     s0 += cSq;
     m1 += c;
     s1 += cSq;

     c = texture2D(inputImageTexture, uv + vec2(0,-3) * src_size).rgb;
     cSq = c * c;
     m0 += c;
     s0 += cSq;
     m3 += c;
     s3 += cSq;
     c = texture2D(inputImageTexture, uv + vec2(0,-2) * src_size).rgb;
     cSq = c * c;
     m0 += c;
     s0 += cSq;
     m3 += c;
     s3 += cSq;
     c = texture2D(inputImageTexture, uv + vec2(0,-1) * src_size).rgb;
     cSq = c * c;
     m0 += c;
     s0 += cSq;
     m3 += c;
     s3 += cSq;
     c = texture2D(inputImageTexture, uv + vec2(0,0) * src_size).rgb;
     cSq = c * c;
     m0 += c;
     s0 += cSq;
     m1 += c;
     s1 += cSq;
     m2 += c;
     s2 += cSq;
     m3 += c;
     s3 += cSq;

     c = texture2D(inputImageTexture, uv + vec2(-3,3) * src_size).rgb;
     m1 += c;
     s1 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-3,2) * src_size).rgb;
     m1 += c;
     s1 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-3,1) * src_size).rgb;
     m1 += c;
     s1 += c * c;

     c = texture2D(inputImageTexture, uv + vec2(-2,3) * src_size).rgb;
     m1 += c;
     s1 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-2,2) * src_size).rgb;
     m1 += c;
     s1 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-2,1) * src_size).rgb;
     m1 += c;
     s1 += c * c;

     c = texture2D(inputImageTexture, uv + vec2(-1,3) * src_size).rgb;
     m1 += c;
     s1 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-1,2) * src_size).rgb;
     m1 += c;
     s1 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(-1,1) * src_size).rgb;
     m1 += c;
     s1 += c * c;

     c = texture2D(inputImageTexture, uv + vec2(0,3) * src_size).rgb;
     cSq = c * c;
     m1 += c;
     s1 += cSq;
     m2 += c;
     s2 += cSq;
     c = texture2D(inputImageTexture, uv + vec2(0,2) * src_size).rgb;
     cSq = c * c;
     m1 += c;
     s1 += cSq;
     m2 += c;
     s2 += cSq;
     c = texture2D(inputImageTexture, uv + vec2(0,1) * src_size).rgb;
     cSq = c * c;
     m1 += c;
     s1 += cSq;
     m2 += c;
     s2 += cSq;

     c = texture2D(inputImageTexture, uv + vec2(3,3) * src_size).rgb;
     m2 += c;
     s2 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(3,2) * src_size).rgb;
     m2 += c;
     s2 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(3,1) * src_size).rgb;
     m2 += c;
     s2 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(3,0) * src_size).rgb;
     cSq = c * c;
     m2 += c;
     s2 += cSq;
     m3 += c;
     s3 += cSq;

     c = texture2D(inputImageTexture, uv + vec2(2,3) * src_size).rgb;
     m2 += c;
     s2 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(2,2) * src_size).rgb;
     m2 += c;
     s2 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(2,1) * src_size).rgb;
     m2 += c;
     s2 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(2,0) * src_size).rgb;
     cSq = c * c;
     m2 += c;
     s2 += cSq;
     m3 += c;
     s3 += cSq;

     c = texture2D(inputImageTexture, uv + vec2(1,3) * src_size).rgb;
     m2 += c;
     s2 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(1,2) * src_size).rgb;
     m2 += c;
     s2 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(1,1) * src_size).rgb;
     m2 += c;
     s2 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(1,0) * src_size).rgb;
     cSq = c * c;
     m2 += c;
     s2 += cSq;
     m3 += c;
     s3 += cSq;

     c = texture2D(inputImageTexture, uv + vec2(3,-3) * src_size).rgb;
     m3 += c;
     s3 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(3,-2) * src_size).rgb;
     m3 += c;
     s3 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(3,-1) * src_size).rgb;
     m3 += c;
     s3 += c * c;

     c = texture2D(inputImageTexture, uv + vec2(2,-3) * src_size).rgb;
     m3 += c;
     s3 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(2,-2) * src_size).rgb;
     m3 += c;
     s3 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(2,-1) * src_size).rgb;
     m3 += c;
     s3 += c * c;

     c = texture2D(inputImageTexture, uv + vec2(1,-3) * src_size).rgb;
     m3 += c;
     s3 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(1,-2) * src_size).rgb;
     m3 += c;
     s3 += c * c;
     c = texture2D(inputImageTexture, uv + vec2(1,-1) * src_size).rgb;
     m3 += c;
     s3 += c * c;

     float min_sigma2 = 1e+2;
     m0 /= n;
     s0 = abs(s0 / n - m0 * m0);

     float sigma2 = s0.r + s0.g + s0.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         gl_FragColor = vec4(m0, 1.0);
     }

     m1 /= n;
     s1 = abs(s1 / n - m1 * m1);

     sigma2 = s1.r + s1.g + s1.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         gl_FragColor = vec4(m1, 1.0);
     }

     m2 /= n;
     s2 = abs(s2 / n - m2 * m2);

     sigma2 = s2.r + s2.g + s2.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         gl_FragColor = vec4(m2, 1.0);
     }

     m3 /= n;
     s3 = abs(s3 / n - m3 * m3);

     sigma2 = s3.r + s3.g + s3.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         gl_FragColor = vec4(m3, 1.0);
     }
 }
 );

@implementation GPUImageKuwaharaRadius3Filter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageKuwaharaRadius3FragmentShaderString]))
    {
		return nil;
    }

    return self;
}

@end
