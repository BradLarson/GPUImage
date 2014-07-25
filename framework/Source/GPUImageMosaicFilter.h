
// This needs a little more work, it's rotating the input tileset and there are some artifacts (I think from GL_LINEAR interpolation), but it's working

#import "GPUImageTwoInputFilter.h"
#import "GPUImagePicture.h"

@interface GPUImageMosaicFilter : GPUImageTwoInputFilter {
    GLint inputTileSizeUniform, numTilesUniform, displayTileSizeUniform, colorOnUniform;
    GPUImagePicture *pic;
}

//  This filter takes an input tileset, the tiles must ascend in luminance
//  It looks at the input image and replaces each display tile with an input tile 
//  according to the luminance of that tile.  The idea was to replicate the ASCII
//  video filters seen in other apps, but the tileset can be anything.
@property(readwrite, nonatomic) CGSize inputTileSize;
@property(readwrite, nonatomic) float numTiles;
@property(readwrite, nonatomic) CGSize displayTileSize;
@property(readwrite, nonatomic) BOOL colorOn;
@property(readwrite, nonatomic, copy) NSString *tileSet;

@end
