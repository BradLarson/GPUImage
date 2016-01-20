
#import "GPUImageSolidColorFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#define FTCColor UIColor
#else
#define FTCColor NSColor
#endif

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageSolidColorFilterFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform vec4 color;
 
 void main()
 {
    gl_FragColor = color;
 }
 );
#else
NSString *const kGPUImageSolidColorFilterFragmentShaderString = SHADER_STRING
(
 uniform vec4 color;
 
 void main()
 {
    gl_FragColor = color;
 }
 );
#endif

@interface GPUImageSolidColorFilter() {
   GLint colorUniform;
}
@end

@implementation GPUImageSolidColorFilter

@synthesize color = _color;

- (id)init {
   self = [super initWithFragmentShaderFromString:kGPUImageSolidColorFilterFragmentShaderString];
   if (!self) {
      return nil;
   }

   colorUniform = [filterProgram uniformIndex:@"color"];
   
   self.color = [FTCColor redColor];
   
   return self;
}

#pragma mark - Accessors

- (void)setColor:(FTCColor *)color {
   _color = color;
   const CGFloat *colors = CGColorGetComponents(color.CGColor);
   CGFloat correction = 0.5;
   CGFloat r, g, b, a;
   if (correction != 0.0) {
      r = colors[0] - colors[0]*correction;
      g = colors[1] - colors[1]*correction;
      b = colors[2] - colors[2]*correction;
      a = colors[3];
   } else {
      r = colors[0];
      g = colors[1];
      b = colors[2];
      a = colors[3];
   }
   
   [self setVec4:(GPUVector4){r,g,b,a} forUniform:colorUniform program:filterProgram];
}

@end