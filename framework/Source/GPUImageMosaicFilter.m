//
//  GPUImageMosaicFilter.m
//  Face Esplode
//
//  Created by Jacob Gundersen on 3/29/12.
//  Copyright (c) 2012 Interrobang Software LLC. All rights reserved.
//

#import "GPUImageMosaicFilter.h"
#import "GPUImagePicture.h"

NSString *const kGPUImageMosaicFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform vec2 inputTileSize;
 uniform vec2 displayTileSize;
 uniform float numTiles;
 
 void main()
 {
     vec2 xy = textureCoordinate;
     xy = xy - mod(xy, displayTileSize);
     
     vec4 lumcoeff = vec4(0.299,0.587,0.114,0.0);
     
     float lum = dot(texture2D(inputImageTexture, xy),lumcoeff);
     lum = 1.0 - lum;
     
     float stepsize = 1.0 / numTiles;
     float lumStep = (lum - mod(lum, stepsize)) / stepsize; 
  
     float rowStep = 1.0 / inputTileSize.x;
     float x = mod(lumStep, rowStep);
     float y = floor(lumStep / rowStep);
     
     vec2 startCoord = vec2(float(x) *  inputTileSize.x, float(y) * inputTileSize.y);
     vec2 finalCoord = startCoord + ((textureCoordinate - xy) * (inputTileSize / displayTileSize));
     
     vec4 color = texture2D(inputImageTexture2, finalCoord);     
     gl_FragColor = color; 
     
 }  
 );

@implementation GPUImageMosaicFilter

@synthesize inputTileSize = _inputTileSize, numTiles = _numTiles, displayTileSize = _displayTileSize;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageMosaicFragmentShaderString]))
    {
		return nil;
    }
    
    inputTileSizeUniform = [filterProgram uniformIndex:@"inputTileSize"];
    displayTileSizeUniform = [filterProgram uniformIndex:@"displayTileSize"];
    numTilesUniform = [filterProgram uniformIndex:@"numTiles"];
    
    CGSize its = CGSizeMake(0.125, 0.125);
    CGSize dts = CGSizeMake(0.025, 0.025);
    [self setDisplayTileSize:dts];
    [self setInputTileSize:its];
    [self setNumTiles:64.0];
    //[self addTileSet:@"squares.png"];
    return self;
}

-(void)setNumTiles:(float)numTiles {

    _numTiles = numTiles;
    [self setFloat:_numTiles forUniform:@"numTiles"];
}

-(void)setInputTileSize:(CGSize)inputTileSize {
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
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    GLfloat inputTS[2];
    inputTS[0] = _inputTileSize.width;
    inputTS[1] = _inputTileSize.height;
    glUniform2fv(inputTileSizeUniform, 1, inputTS);
}

-(void)setDisplayTileSize:(CGSize)displayTileSize {
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
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    GLfloat displayTS[2];
    displayTS[0] = _displayTileSize.width;
    displayTS[1] = _displayTileSize.height;
    glUniform2fv(displayTileSizeUniform, 1, displayTS);
}

//I'd like to add this method, but I can't get it to work.  The same set of commands works if they are called from my view controller class
-(void)addTileSet:(NSString *)tileSet {
    UIImage *img = [UIImage imageNamed:tileSet];
    GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:img smoothlyScaleOutput:YES];
    [pic addTarget:self];

}

@end
