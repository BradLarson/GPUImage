//
//  GPUImagePerlinNoiseFilter.h
//  Face Esplode
//
//  Created by Jacob Gundersen on 5/15/12.
//  
//

#import "GPUImageFilter.h"

@interface GPUImagePerlinNoiseFilter : GPUImageFilter {
    GLint scaleUniform, colorStartUniform, colorFinishUniform;
}

@property (readwrite, nonatomic) GPUVector4 colorStart;
@property (readwrite, nonatomic) GPUVector4 colorFinish;

@property (readwrite, nonatomic) float scale;

@end
