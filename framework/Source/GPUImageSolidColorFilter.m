
#import "GPUImageSolidColorFilter.h"

NSString *const kGPUImageSolidColorFilterFragmentShaderString = SHADER_STRING
(
 uniform vec4 color;
 
 void main()
 {
    gl_FragColor = color;
 }
 );

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
   
   self.color = [NSColor redColor];
   
   return self;
}

#pragma mark - Accessors

- (void)setColor:(NSColor *)color {
   _color = color;
   NSColorSpace *colorSpace = [NSColorSpace sRGBColorSpace];
   NSColor *aColor = [color colorUsingColorSpace:colorSpace];
   CGFloat r = [aColor redComponent];
   CGFloat g = [aColor greenComponent];
   CGFloat b = [aColor blueComponent];
   CGFloat a = [aColor alphaComponent];
   
   [self setVec4:(GPUVector4){r,g,b,a} forUniform:colorUniform program:filterProgram];
}

@end