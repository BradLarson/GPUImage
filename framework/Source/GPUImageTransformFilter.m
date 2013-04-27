#import "GPUImageTransformFilter.h"

NSString *const kGPUImageTransformVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform mat4 transformMatrix;
 uniform mat4 orthographicMatrix;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = transformMatrix * vec4(position.xyz, 1.0) * orthographicMatrix;
     textureCoordinate = inputTextureCoordinate.xy;
 }
);

@implementation GPUImageTransformFilter

@synthesize affineTransform;
@synthesize transform3D = _transform3D;
@synthesize ignoreAspectRatio = _ignoreAspectRatio;
@synthesize anchorTopLeft = _anchorTopLeft;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageTransformVertexShaderString fragmentShaderFromString:kGPUImagePassthroughFragmentShaderString]))
    {
        return nil;
    }
    
    transformMatrixUniform = [filterProgram uniformIndex:@"transformMatrix"];
    orthographicMatrixUniform = [filterProgram uniformIndex:@"orthographicMatrix"];
    
    self.transform3D = CATransform3DIdentity;
    
    return self;
}

#pragma mark -
#pragma mark Conversion from matrix formats

- (void)loadOrthoMatrix:(GLfloat *)matrix left:(GLfloat)left right:(GLfloat)right bottom:(GLfloat)bottom top:(GLfloat)top near:(GLfloat)near far:(GLfloat)far;
{
    GLfloat r_l = right - left;
    GLfloat t_b = top - bottom;
    GLfloat f_n = far - near;
    GLfloat tx = - (right + left) / (right - left);
    GLfloat ty = - (top + bottom) / (top - bottom);
    GLfloat tz = - (far + near) / (far - near);
    
	float scale = 2.0f;
	if (_anchorTopLeft)
	{
		scale = 4.0f;
		tx=-1.0f;
		ty=-1.0f;
	}
	
    matrix[0] = scale / r_l;
    matrix[1] = 0.0f;
    matrix[2] = 0.0f;
    matrix[3] = tx;
    
    matrix[4] = 0.0f;
    matrix[5] = scale / t_b;
    matrix[6] = 0.0f;
    matrix[7] = ty;
    
    matrix[8] = 0.0f;
    matrix[9] = 0.0f;
    matrix[10] = scale / f_n;
    matrix[11] = tz;
    
    matrix[12] = 0.0f;
    matrix[13] = 0.0f;
    matrix[14] = 0.0f;
    matrix[15] = 1.0f;
}

//- (void)convert3DTransform:(CATransform3D *)transform3D toMatrix:(GLfloat *)matrix;
//{
//	//	struct CATransform3D
//	//	{
//	//		CGFloat m11, m12, m13, m14;
//	//		CGFloat m21, m22, m23, m24;
//	//		CGFloat m31, m32, m33, m34;
//	//		CGFloat m41, m42, m43, m44;
//	//	};
//	
//	matrix[0] = (GLfloat)transform3D->m11;
//	matrix[1] = (GLfloat)transform3D->m12;
//	matrix[2] = (GLfloat)transform3D->m13;
//	matrix[3] = (GLfloat)transform3D->m14;
//	matrix[4] = (GLfloat)transform3D->m21;
//	matrix[5] = (GLfloat)transform3D->m22;
//	matrix[6] = (GLfloat)transform3D->m23;
//	matrix[7] = (GLfloat)transform3D->m24;
//	matrix[8] = (GLfloat)transform3D->m31;
//	matrix[9] = (GLfloat)transform3D->m32;
//	matrix[10] = (GLfloat)transform3D->m33;
//	matrix[11] = (GLfloat)transform3D->m34;
//	matrix[12] = (GLfloat)transform3D->m41;
//	matrix[13] = (GLfloat)transform3D->m42;
//	matrix[14] = (GLfloat)transform3D->m43;
//	matrix[15] = (GLfloat)transform3D->m44;
//}

- (void)convert3DTransform:(CATransform3D *)transform3D toMatrix:(GPUMatrix4x4 *)matrix;
{
	//	struct CATransform3D
	//	{
	//		CGFloat m11, m12, m13, m14;
	//		CGFloat m21, m22, m23, m24;
	//		CGFloat m31, m32, m33, m34;
	//		CGFloat m41, m42, m43, m44;
	//	};
    
    GLfloat *mappedMatrix = (GLfloat *)matrix;
	
	mappedMatrix[0] = (GLfloat)transform3D->m11;
	mappedMatrix[1] = (GLfloat)transform3D->m12;
	mappedMatrix[2] = (GLfloat)transform3D->m13;
	mappedMatrix[3] = (GLfloat)transform3D->m14;
	mappedMatrix[4] = (GLfloat)transform3D->m21;
	mappedMatrix[5] = (GLfloat)transform3D->m22;
	mappedMatrix[6] = (GLfloat)transform3D->m23;
	mappedMatrix[7] = (GLfloat)transform3D->m24;
	mappedMatrix[8] = (GLfloat)transform3D->m31;
	mappedMatrix[9] = (GLfloat)transform3D->m32;
	mappedMatrix[10] = (GLfloat)transform3D->m33;
	mappedMatrix[11] = (GLfloat)transform3D->m34;
	mappedMatrix[12] = (GLfloat)transform3D->m41;
	mappedMatrix[13] = (GLfloat)transform3D->m42;
	mappedMatrix[14] = (GLfloat)transform3D->m43;
	mappedMatrix[15] = (GLfloat)transform3D->m44;
}

#pragma mark -
#pragma mark GPUImageInput

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    outputTextureRetainCount = [targets count];

    CGSize currentFBOSize = [self sizeOfFBO];
    CGFloat normalizedHeight = currentFBOSize.height / currentFBOSize.width;
    
    GLfloat adjustedVertices[] = {
        -1.0f, -normalizedHeight,
        1.0f, -normalizedHeight,
        -1.0f,  normalizedHeight,
        1.0f,  normalizedHeight,
    };
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };

	GLfloat adjustedVerticesAnchorTL[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f,  normalizedHeight,
        1.0f,  normalizedHeight,
    };

    static const GLfloat squareVerticesAnchorTL[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f,  1.0f,
        1.0f,  1.0f,
    };

    if (_ignoreAspectRatio)
    {
		if (_anchorTopLeft)
		{
			[self renderToTextureWithVertices:squareVerticesAnchorTL textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation] sourceTexture:filterSourceTexture];
		}
		else
		{
			[self renderToTextureWithVertices:squareVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation] sourceTexture:filterSourceTexture];
		}
    }
    else
    {
		if (_anchorTopLeft)
		{
			[self renderToTextureWithVertices:adjustedVerticesAnchorTL textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation] sourceTexture:filterSourceTexture];
		}
		else
		{
			[self renderToTextureWithVertices:adjustedVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation] sourceTexture:filterSourceTexture];
		}
    }
    
    [self informTargetsAboutNewFrameAtTime:frameTime];
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    if (!_ignoreAspectRatio)
    {
        [self loadOrthoMatrix:(GLfloat *)&orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * filterFrameSize.height / filterFrameSize.width) top:(1.0 * filterFrameSize.height / filterFrameSize.width) near:-1.0 far:1.0];
        //     [self loadOrthoMatrix:orthographicMatrix left:-1.0 right:1.0 bottom:(-1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) top:(1.0 * (GLfloat)backingHeight / (GLfloat)backingWidth) near:-2.0 far:2.0];

        [self setMatrix4f:orthographicMatrix forUniform:orthographicMatrixUniform program:filterProgram];
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setAffineTransform:(CGAffineTransform)newValue;
{
    self.transform3D = CATransform3DMakeAffineTransform(newValue);
}

- (CGAffineTransform)affineTransform;
{
    return CATransform3DGetAffineTransform(self.transform3D);
}

- (void)setTransform3D:(CATransform3D)newValue;
{
    _transform3D = newValue;
        
    GPUMatrix4x4 temporaryMatrix;
    
    [self convert3DTransform:&_transform3D toMatrix:&temporaryMatrix];
    [self setMatrix4f:temporaryMatrix forUniform:transformMatrixUniform program:filterProgram];
}

- (void)setIgnoreAspectRatio:(BOOL)newValue;
{
    _ignoreAspectRatio = newValue;
    
    if (_ignoreAspectRatio)
    {
        [self loadOrthoMatrix:(GLfloat *)&orthographicMatrix left:-1.0 right:1.0 bottom:-1.0 top:1.0 near:-1.0 far:1.0];
        [self setMatrix4f:orthographicMatrix forUniform:orthographicMatrixUniform program:filterProgram];
    }
    else
    {
        [self setupFilterForSize:[self sizeOfFBO]];
    }
}

- (void)setAnchorTopLeft:(BOOL)newValue
{
	_anchorTopLeft = newValue;
	[self setIgnoreAspectRatio:_ignoreAspectRatio];
}

@end
