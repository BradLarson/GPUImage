#import "GPUImageOutput.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

extern NSString *const kGPUImageVertexShaderString;
extern NSString *const kGPUImagePassthroughFragmentShaderString;

struct GPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
};
typedef struct GPUVector4 GPUVector4;

struct GPUMatrix4x4 {
    GPUVector4 one;
    GPUVector4 two;
    GPUVector4 three;
    GPUVector4 four;
};
typedef struct GPUMatrix4x4 GPUMatrix4x4;

@interface GPUImageFilter : GPUImageOutput <GPUImageInput>
{
    GLuint filterSourceTexture, filterSourceTexture2;

    GLuint filterFramebuffer;

    GLProgram *filterProgram;
    GLint filterPositionAttribute, filterTextureCoordinateAttribute;
    GLint filterInputTextureUniform, filterInputTextureUniform2;
    GLfloat backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha;
    
    CGSize currentFilterSize;
}

// Initialization and teardown
- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;
- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
- (id)initWithFragmentShaderFromFile:(NSString *)fragmentShaderFilename;
- (void)initializeAttributes;
- (void)setupFilterForSize:(CGSize)filterFrameSize;

- (void)recreateFilterFBO;

// Managing the display FBOs
- (CGSize)sizeOfFBO;
- (void)createFilterFBOofSize:(CGSize)currentFBOSize;
- (void)destroyFilterFBO;
- (void)setFilterFBO;
- (void)setOutputFBO;

// Rendering
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;

// Input parameters
- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
- (void)setInteger:(GLint)newInteger forUniform:(NSString *)uniformName;
- (void)setFloat:(GLfloat)newFloat forUniform:(NSString *)uniformName;
- (void)setSize:(CGSize)newSize forUniform:(NSString *)uniformName;
- (void)setPoint:(CGPoint)newPoint forUniform:(NSString *)uniformName;
- (void)setFloatVec3:(GLfloat *)newVec3 forUniform:(NSString *)uniformName;
- (void)setFloatVec4:(GLfloat *)newVec4 forUniform:(NSString *)uniformName;
- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName;

@end