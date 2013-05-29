//
//  GPUImageMosaicFilter.m


#import "GPUImageMosaicFilter.h"
#import "GPUImagePicture.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageMosaicFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform vec2 inputTileSize;
 uniform vec2 displayTileSize;
 uniform float numTiles;
 uniform int colorOn;
 
 void main()
 {
     vec2 xy = textureCoordinate;
     xy = xy - mod(xy, displayTileSize);
     
     vec4 lumcoeff = vec4(0.299,0.587,0.114,0.0);
     
     vec4 inputColor = texture2D(inputImageTexture2, xy);
     float lum = dot(inputColor,lumcoeff);
     lum = 1.0 - lum;
     
     float stepsize = 1.0 / numTiles;
     float lumStep = (lum - mod(lum, stepsize)) / stepsize; 
  
     float rowStep = 1.0 / inputTileSize.x;
     float x = mod(lumStep, rowStep);
     float y = floor(lumStep / rowStep);
     
     vec2 startCoord = vec2(float(x) *  inputTileSize.x, float(y) * inputTileSize.y);
     vec2 finalCoord = startCoord + ((textureCoordinate - xy) * (inputTileSize / displayTileSize));
     
     vec4 color = texture2D(inputImageTexture, finalCoord);   
     if (colorOn == 1) {
         color = color * inputColor;
     }
     gl_FragColor = color; 
     
 }  
);
#else
NSString *const kGPUImageMosaicFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform vec2 inputTileSize;
 uniform vec2 displayTileSize;
 uniform float numTiles;
 uniform int colorOn;
 
 void main()
 {
     vec2 xy = textureCoordinate;
     xy = xy - mod(xy, displayTileSize);
     
     vec4 lumcoeff = vec4(0.299,0.587,0.114,0.0);
     
     vec4 inputColor = texture2D(inputImageTexture2, xy);
     float lum = dot(inputColor,lumcoeff);
     lum = 1.0 - lum;
     
     float stepsize = 1.0 / numTiles;
     float lumStep = (lum - mod(lum, stepsize)) / stepsize;
     
     float rowStep = 1.0 / inputTileSize.x;
     float x = mod(lumStep, rowStep);
     float y = floor(lumStep / rowStep);
     
     vec2 startCoord = vec2(float(x) *  inputTileSize.x, float(y) * inputTileSize.y);
     vec2 finalCoord = startCoord + ((textureCoordinate - xy) * (inputTileSize / displayTileSize));
     
     vec4 color = texture2D(inputImageTexture, finalCoord);
     if (colorOn == 1) {
         color = color * inputColor;
     }
     gl_FragColor = color;
 }
);
#endif

@implementation GPUImageMosaicFilter

@synthesize inputTileSize = _inputTileSize, numTiles = _numTiles, displayTileSize = _displayTileSize, colorOn = _colorOn;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageMosaicFragmentShaderString]))
    {
		return nil;
    }
    
    inputTileSizeUniform = [filterProgram uniformIndex:@"inputTileSize"];
    displayTileSizeUniform = [filterProgram uniformIndex:@"displayTileSize"];
    numTilesUniform = [filterProgram uniformIndex:@"numTiles"];
    colorOnUniform = [filterProgram uniformIndex:@"colorOn"];
    
    CGSize its = CGSizeMake(0.125, 0.125);
    CGSize dts = CGSizeMake(0.025, 0.025);
    [self setDisplayTileSize:dts];
    [self setInputTileSize:its];
    [self setNumTiles:64.0];
    [self setColorOn:YES];
    //[self setTileSet:@"squares.png"];
    return self;
}

- (void)setColorOn:(BOOL)yes
{
    glUniform1i(colorOnUniform, yes);
}

- (void)setNumTiles:(float)numTiles
{

    _numTiles = numTiles;
    [self setFloat:_numTiles forUniformName:@"numTiles"];
}

- (void)setInputTileSize:(CGSize)inputTileSize
{
    if (inputTileSize.width > 1.0) {
        _inputTileSize.width = 1.0;
    } 
    if (inputTileSize.height > 1.0) {
        _inputTileSize.height = 1.0;
    }
    if (inputTileSize.width < 0.0) {
        _inputTileSize.width = 0.0;
    }
    if (inputTileSize.height < 0.0) {
        _inputTileSize.height = 0.0;
    }
    
    
    _inputTileSize = inputTileSize;
    
    [self setSize:_inputTileSize forUniform:inputTileSizeUniform program:filterProgram];    
}

-(void)setDisplayTileSize:(CGSize)displayTileSize
{
    if (displayTileSize.width > 1.0) {
        _displayTileSize.width = 1.0;
    } 
    if (displayTileSize.height > 1.0) {
        _displayTileSize.height = 1.0;
    }
    if (displayTileSize.width < 0.0) {
        _displayTileSize.width = 0.0;
    }
    if (displayTileSize.height < 0.0) {
        _displayTileSize.height = 0.0;
    }
    
    
    _displayTileSize = displayTileSize;
    
    [self setSize:_displayTileSize forUniform:displayTileSizeUniform program:filterProgram];
}

-(void)setTileSet:(NSString *)tileSet
{
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *img = [UIImage imageNamed:tileSet];
#else
    NSImage *img = [NSImage imageNamed:tileSet];
#endif
    pic = [[GPUImagePicture alloc] initWithImage:img smoothlyScaleOutput:YES];
    [pic addTarget:self];
    [pic processImage];
}

@end
