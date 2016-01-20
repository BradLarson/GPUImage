
#import "GPUImageGradientFilter.h"

#define DEGREES_TO_RADIANS(degrees)((M_PI * degrees)/180)

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#define FTCColor UIColor
#else
#define FTCColor NSColor
#endif

@implementation GPUImageFilter (Float4Array)

- (void)setFloat4Array:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(GLProgram *)shaderProgram {
   // Make a copy of the data, so it doesn't get overwritten before async call executes
   NSData *arrayData = [NSData dataWithBytes:arrayValue length:arrayLength * sizeof(arrayValue[0])];
   
   runAsynchronouslyOnVideoProcessingQueue(^{
      [GPUImageContext setActiveShaderProgram:shaderProgram];
      
      [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
         glUniform4fv(uniform, arrayLength/4, [arrayData bytes]);
      }];
   });
}

@end

#pragma mark

GLfloat * CreateFloatArrayWithSteps(NSArray *steps);
GLfloat * CreateFloatArrayWithSteps(NSArray *steps) {
   GLsizei stepCount = (GLsizei)[steps count];
   GLfloat *cSteps = malloc(stepCount * sizeof(GLfloat));
   for (int i=0; i<stepCount; i++) {
      cSteps[i] = [steps[i] floatValue];
   }
   return cSteps;
}

GLfloat * CreateFloatArrayWithColors(NSArray *colors);
GLfloat * CreateFloatArrayWithColors(NSArray *colors) {
   GLfloat *cColors = malloc((GLsizei)[colors count] * 4 * sizeof(GLfloat));
   GLsizei j = 0;
   for (FTCColor *color in colors) {
      const CGFloat *aColor = CGColorGetComponents(color.CGColor);
      cColors[j] = aColor[0];
      cColors[j+1] = aColor[1];
      cColors[j+2] = aColor[2];
      cColors[j+3] = aColor[3];
      j += 4;
   }
   return cColors;
}

#pragma mark - GPUImageGradientRadialFilter

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageGradientRadialFilterVertexShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform vec2 aspect;
 
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
    textureCoordinate = inputTextureCoordinate * aspect;
    //textureCoordinate = (inputTextureCoordinate - vec2(0.5,0.5)) * aspect;
    gl_Position = position;
 }
 );

NSString *const kGPUImageGradientRadialFilterFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform vec2 center; // center of gradient
 
 uniform int count; // the number of gradation points
 uniform float steps[100];
 uniform vec4 colors[100];
 
 varying vec2 textureCoordinate;
 
 void main()
 {
    float dist = 2.0 * distance(textureCoordinate, center);
    vec4 col = colors[0];
    for (int i=1; i<count; ++i) {
       col = mix(col, colors[i], smoothstep(steps[i-1], steps[i], dist));
    }
    gl_FragColor = col; //texture2D(inputImageTexture, textureCoordinate) * col;
 }
 );

#else

NSString *const kGPUImageGradientRadialFilterVertexShaderString = SHADER_STRING
(
 uniform vec2 aspect;
 
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
    textureCoordinate = inputTextureCoordinate * aspect;
    //textureCoordinate = (inputTextureCoordinate - vec2(0.5,0.5)) * aspect;
    gl_Position = position;
 }
 );

NSString *const kGPUImageGradientRadialFilterFragmentShaderString = SHADER_STRING
(
 uniform vec2 center; // center of gradient
 
 uniform int count; // the number of gradation points
 uniform float steps[100];
 uniform vec4 colors[100];
 
 varying vec2 textureCoordinate;
 
 void main()
 {
    float dist = 2.0 * distance(textureCoordinate, center);
    vec4 col = colors[0];
    for (int i=1; i<count; ++i) {
       col = mix(col, colors[i], smoothstep(steps[i-1], steps[i], dist));
    }
    gl_FragColor = col; //texture2D(inputImageTexture, textureCoordinate) * col;
 }
 );
#endif
@interface GPUImageGradientRadialFilter() {
   GLint aspectUniform, centerUniform, countUniform, stepsUniform, colorsUniform;
}
@end

@implementation GPUImageGradientRadialFilter

- (id)init {
   self = [super initWithVertexShaderFromString:kGPUImageGradientRadialFilterVertexShaderString fragmentShaderFromString:kGPUImageGradientRadialFilterFragmentShaderString];
   if (!self) {
      return nil;
   }
   
   aspectUniform = [filterProgram uniformIndex:@"aspect"];
   centerUniform = [filterProgram uniformIndex:@"center"];
   countUniform = [filterProgram uniformIndex:@"count"];
   stepsUniform = [filterProgram uniformIndex:@"steps"];
   colorsUniform = [filterProgram uniformIndex:@"colors"];
   
   _aspect = CGPointZero; self.aspect = CGPointMake(1.0, 1.0);
   _center = CGPointZero; self.center = CGPointMake(0.5, 0.5);
   self.colors = @[[FTCColor redColor], [FTCColor greenColor], [FTCColor blueColor], [FTCColor whiteColor]];
   
   return self;
}

#pragma mark - Accessors

- (void)setAspect:(CGPoint)aspect {
   if (!CGPointEqualToPoint(_aspect, aspect)) {
      _aspect = aspect;
      [self setPoint:aspect forUniform:aspectUniform program:filterProgram];
   }
}

- (void)setCenter:(CGPoint)center {
   if (!CGPointEqualToPoint(_center, center)) {
      _center = center;
      [self setPoint:center forUniform:centerUniform program:filterProgram];
   }
}

- (void)setSteps:(NSArray<NSNumber *> *)steps withColors:(NSArray<FTCColor *> *)colors {
   assert([steps count] == [colors count]);
   
   // Count
   GLsizei count = (GLsizei)[steps count];
   [self setInteger:count forUniform:countUniform program:filterProgram];
   
   // Steps
   GLfloat *cSteps = CreateFloatArrayWithSteps(steps);
   [self setFloatArray:cSteps length:count forUniform:stepsUniform program:filterProgram];
   free(cSteps);
   
   // Colors
   GLfloat *cColors = CreateFloatArrayWithColors(colors);
   [self setFloat4Array:cColors length:(GLsizei)[colors count]*4 forUniform:colorsUniform program:filterProgram];
   free(cColors);
}

- (void)setColors:(NSArray<FTCColor *> *)colors {
   NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:[colors count]];
   CGFloat step = 1.0/(CGFloat)[colors count];
   for (NSUInteger i=0; i<[colors count]; i++) {
      [mutableArray addObject:@((CGFloat)i * step)];
   }
   [self setSteps:[mutableArray copy] withColors:colors];
}

@end

#pragma mark - GPUImageGradientLinearFilter

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageGradientLinearFilterFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform vec2 center; // center of gradient
 uniform float angle;
 
 uniform int count; // the number of gradation points
 uniform float steps[100];
 uniform vec4 colors[100];
 
 varying vec2 textureCoordinate;
 
 void main()
 {
    vec2 deltaUv = (textureCoordinate - center);
    float uvAngle = atan(deltaUv.y, deltaUv.x);
    float newAngle = uvAngle - angle;
    
    float dist = distance(textureCoordinate, center);
    vec2 newUv = vec2(dist * cos(newAngle)/2.0, dist * sin(newAngle)/2.0);
    float ratio = 2.0 * ((center.x-newUv.x) - 0.25);
    
    vec4 col = colors[0];
    for (int i=1; i<count; ++i) {
       float smooth = smoothstep(steps[i-1], steps[i], ratio);
       col = mix(col, colors[i], smooth);
    }
    
    gl_FragColor = col; //texture2D(inputImageTexture, textureCoordinate) * col;
 }
 );

#else

// https://github.com/cacheflowe/haxademic/blob/master/data/shaders/textures/gradient-line.glsl
NSString *const kGPUImageGradientLinearFilterFragmentShaderString = SHADER_STRING
(
 uniform vec2 center; // center of gradient
 uniform float angle;
 
 uniform int count; // the number of gradation points
 uniform float steps[100];
 uniform vec4 colors[100];
 
 varying vec2 textureCoordinate;
 
 void main()
 {
    vec2 deltaUv = (textureCoordinate - center);
    float uvAngle = atan(deltaUv.y, deltaUv.x);
    float newAngle = uvAngle - angle;
    
    float dist = distance(textureCoordinate, center);
    vec2 newUv = vec2(dist * cos(newAngle)/2.0, dist * sin(newAngle)/2.0);
    float ratio = 2.0 * ((center.x-newUv.x) - 0.25);
    
    vec4 col = colors[0];
    for (int i=1; i<count; ++i) {
       float smooth = smoothstep(steps[i-1], steps[i], ratio);
       col = mix(col, colors[i], smooth);
    }
    
    gl_FragColor = col; //texture2D(inputImageTexture, textureCoordinate) * col;
 }
 );
#endif

@interface GPUImageGradientLinearFilter() {
   GLint centerUniform, angleUniform, countUniform, stepsUniform, colorsUniform;
}
@end

@implementation GPUImageGradientLinearFilter

- (id)init {
   self = [super initWithFragmentShaderFromString:kGPUImageGradientLinearFilterFragmentShaderString];
   if (!self) {
      return nil;
   }
   
   centerUniform = [filterProgram uniformIndex:@"center"];
   angleUniform = [filterProgram uniformIndex:@"angle"];
   countUniform = [filterProgram uniformIndex:@"count"];
   stepsUniform = [filterProgram uniformIndex:@"steps"];
   colorsUniform = [filterProgram uniformIndex:@"colors"];
   
   _center = CGPointZero; self.center = CGPointMake(0.5, 0.5);
   _angle = -1.0; self.angle = 0.0;
   self.colors = @[[FTCColor blackColor], [FTCColor whiteColor]];
   
   return self;
}

#pragma mark - Accessors

- (void)setCenter:(CGPoint)center {
   if (!CGPointEqualToPoint(_center, center)) {
      _center = center;
      [self setPoint:center forUniform:centerUniform program:filterProgram];
   }
}

- (void)setAngle:(CGFloat)angle {
   if (_angle != angle) {
      _angle = angle;
      CGFloat angleInRad = DEGREES_TO_RADIANS(angle) - M_PI;
      [self setFloat:angleInRad forUniform:angleUniform program:filterProgram];
   }
}

- (void)setSteps:(NSArray<NSNumber *> *)steps withColors:(NSArray<FTCColor *> *)colors {
   assert([steps count] == [colors count]);
   
   // Count
   GLsizei count = (GLsizei)[steps count];
   [self setInteger:count forUniform:countUniform program:filterProgram];
   
   // Steps
   GLfloat *cSteps = CreateFloatArrayWithSteps(steps);
   [self setFloatArray:cSteps length:count forUniform:stepsUniform program:filterProgram];
   free(cSteps);
   
   // Colors
   GLfloat *cColors = CreateFloatArrayWithColors(colors);
   [self setFloat4Array:cColors length:(GLsizei)[colors count]*4 forUniform:colorsUniform program:filterProgram];
   free(cColors);
}

- (void)setColors:(NSArray<FTCColor *> *)colors {
   NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:[colors count]];
   CGFloat step = 1.0/(CGFloat)([colors count]-1);
   for (NSUInteger i=0; i<[colors count]; i++) {
      [mutableArray addObject:@((CGFloat)i * step)];
   }
   [self setSteps:[mutableArray copy] withColors:colors];
}

@end
