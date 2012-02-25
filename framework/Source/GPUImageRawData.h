#import <Foundation/Foundation.h>
#import "GPUImageOpenGLESContext.h"

struct GPUByteColorVector {
    GLubyte red;
    GLubyte green;
    GLubyte blue;
    GLubyte alpha;
};
typedef struct GPUByteColorVector GPUByteColorVector;

@protocol GPUImageRawDataProcessor;

@interface GPUImageRawData : NSObject <GPUImageInput>

@property(readwrite, unsafe_unretained, nonatomic) id<GPUImageRawDataProcessor> delegate;
@property(readonly) GLubyte *rawBytesForImage;

// Initialization and teardown
- (id)initWithImageSize:(CGSize)newImageSize;

// Data access
- (GPUByteColorVector)colorAtLocation:(CGPoint)locationInImage;

@end

@protocol GPUImageRawDataProcessor
- (void)newImageFrameAvailableFromDataSource:(GPUImageRawData *)rawDataSource;
@end