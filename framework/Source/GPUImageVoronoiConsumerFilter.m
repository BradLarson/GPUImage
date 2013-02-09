#import "GPUImageVoronoiConsumerFilter.h"

NSString *const kGPUImageVoronoiConsumerFragmentShaderString = SHADER_STRING
(
 
 precision highp float;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform vec2 size;
 varying vec2 textureCoordinate;
 
 vec2 getCoordFromColor(vec4 color)
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

@implementation GPUImageVoronoiConsumerFilter

@synthesize sizeInPixels = _sizeInPixels;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageVoronoiConsumerFragmentShaderString]))
    {
		return nil;
    }
    
    sizeUniform = [filterProgram uniformIndex:@"size"];
    
    return self;
}

-(void)setSizeInPixels:(CGSize)sizeInPixels {
    _sizeInPixels = sizeInPixels;
    
    //validate that it's a power of 2 and square
    
    float width = log2(sizeInPixels.width);
    float height = log2(sizeInPixels.height);
    
    if (width != height) {
        NSLog(@"Voronoi point texture must be square");
        return;
    }
    if (width != floor(width) || height != floor(height)) {
        NSLog(@"Voronoi point texture must be a power of 2.  Texture size %f, %f", sizeInPixels.width, sizeInPixels.height);
        return;
    }
    glUniform2f(sizeUniform, _sizeInPixels.width, _sizeInPixels.height);
}

@end
