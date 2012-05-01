//
//  GPUImageMosaicFilter.h
//
//  Created by Jacob Gundersen on 3/29/12.
//  
//  This filter takes an input tileset, the tiles must ascend in luminance
//  It looks at the input image and replaces each display tile with an input tile 
//  according to the luminance of that tile.  The idea was to replicate the ASCII
//  video filters seen in other apps, but the tileset can be anything.

#import "GPUImageFilter.h"

@interface GPUImageMosaicFilter : GPUImageFilter {
    GLint inputTileSizeUniform, numTilesUniform, displayTileSizeUniform;
}

@property(readwrite, nonatomic) CGSize inputTileSize;
@property(readwrite, nonatomic) float numTiles;
@property(readwrite, nonatomic) CGSize displayTileSize;

-(void)setNumTiles:(float)numTiles;
-(void)setDisplayTileSize:(CGSize)displayTileSize;
-(void)setInputTileSize:(CGSize)inputTileSize;
-(void)addTileSet:(NSString *)tileSet;

@end
