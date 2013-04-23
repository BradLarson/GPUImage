#import "ES2Renderer.h"

// uniform index
enum {
    UNIFORM_MODELVIEWMATRIX,
    UNIFORM_TEXTURE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// attribute index
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITION,
    NUM_ATTRIBUTES
};

@interface ES2Renderer (PrivateMethods)
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation ES2Renderer

@synthesize outputTexture;
@synthesize newFrameAvailableBlock;

- (id)initWithSize:(CGSize)newSize;
{
    if ((self = [super init]))
    {
        // Need to use a share group based on the GPUImage context to share textures with the 3-D scene
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:[[[GPUImageContext sharedImageProcessingContext] context] sharegroup]];

        if (!context || ![EAGLContext setCurrentContext:context] || ![self loadShaders])
        {
            [self release];
            return nil;
        }
        
        backingWidth = (int)newSize.width;
        backingHeight = (int)newSize.height;
		
		currentCalculatedMatrix = CATransform3DIdentity;
		currentCalculatedMatrix = CATransform3DScale(currentCalculatedMatrix, 0.5, 0.5 * (320.0/480.0), 0.5);
        
        glActiveTexture(GL_TEXTURE0);
        glGenTextures(1, &outputTexture);
        glBindTexture(GL_TEXTURE_2D, outputTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        // This is necessary for non-power-of-two textures
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glBindTexture(GL_TEXTURE_2D, 0);

        glActiveTexture(GL_TEXTURE1);
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        glBindTexture(GL_TEXTURE_2D, outputTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, backingWidth, backingHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputTexture, 0);
        
//        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
//        
//        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        

        videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
        videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        inputFilter = [[GPUImageSepiaFilter alloc] init];
        textureOutput = [[GPUImageTextureOutput alloc] init];
        textureOutput.delegate = self;
        
        [videoCamera addTarget:inputFilter];
        [inputFilter addTarget:textureOutput];
    }

    return self;
}

- (void)renderByRotatingAroundX:(float)xRotation rotatingAroundY:(float)yRotation;
{
    if (!newFrameAvailableBlock)
    {
        return;
    }
    
    static const GLfloat cubeVertices[] = { 
        -1.0, -1.0, -1.0, // 0
        1.0,  1.0, -1.0, // 2
        1.0, -1.0, -1.0, // 1

        -1.0, -1.0, -1.0, // 0
        -1.0,  1.0, -1.0, // 3
        1.0,  1.0, -1.0, // 2

        1.0, -1.0, -1.0, // 1
        1.0,  1.0, -1.0, // 2
        1.0,  1.0,  1.0, // 6

        1.0,  1.0,  1.0, // 6
        1.0, -1.0,  1.0, // 5
        1.0, -1.0, -1.0, // 1

        -1.0, -1.0,  1.0, // 4
        1.0, -1.0,  1.0, // 5
        1.0,  1.0,  1.0, // 6

        1.0,  1.0,  1.0, // 6
        -1.0,  1.0,  1.0,  // 7
        -1.0, -1.0,  1.0, // 4

        1.0,  1.0, -1.0, // 2
        -1.0,  1.0, -1.0, // 3
        1.0,  1.0,  1.0, // 6

        1.0,  1.0,  1.0, // 6
        -1.0,  1.0, -1.0, // 3
        -1.0,  1.0,  1.0,  // 7

        -1.0, -1.0, -1.0, // 0
        -1.0,  1.0,  1.0,  // 7
        -1.0,  1.0, -1.0, // 3

        -1.0, -1.0, -1.0, // 0
        -1.0, -1.0,  1.0, // 4
        -1.0,  1.0,  1.0,  // 7

        -1.0, -1.0, -1.0, // 0
        1.0, -1.0, -1.0, // 1
        1.0, -1.0,  1.0, // 5

        -1.0, -1.0, -1.0, // 0
        1.0, -1.0,  1.0, // 5
        -1.0, -1.0,  1.0 // 4
    };  

	const GLfloat cubeTexCoords[] = {
        0.0, 0.0,
        1.0, 1.0,
        1.0, 0.0,
        
        0.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
        
        0.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
        
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0,

        1.0, 0.0,
        0.0, 0.0,
        0.0, 1.0,
        
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        
        0.0, 1.0,
        1.0, 1.0,
        0.0, 0.0,
        
        0.0, 0.0,
        1.0, 1.0,
        1.0, 0.0,
        
        1.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
        
        1.0, 0.0,
        0.0, 0.0,
        0.0, 1.0,
        
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        
        0.0, 1.0,
        1.0, 0.0,
        0.0, 0.0
        

    };
	
    [EAGLContext setCurrentContext:context];

    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
	
	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);

    glViewport(0, 0, backingWidth, backingHeight);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
	
    glUseProgram(program);	
	    
	// Perform incremental rotation based on current angles in X and Y	
	if ((xRotation != 0.0) || (yRotation != 0.0))
	{
		GLfloat totalRotation = sqrt(xRotation*xRotation + yRotation*yRotation);
		
		CATransform3D temporaryMatrix = CATransform3DRotate(currentCalculatedMatrix, totalRotation * M_PI / 180.0, 
															((xRotation/totalRotation) * currentCalculatedMatrix.m12 + (yRotation/totalRotation) * currentCalculatedMatrix.m11),
															((xRotation/totalRotation) * currentCalculatedMatrix.m22 + (yRotation/totalRotation) * currentCalculatedMatrix.m21),
															((xRotation/totalRotation) * currentCalculatedMatrix.m32 + (yRotation/totalRotation) * currentCalculatedMatrix.m31));
		if ((temporaryMatrix.m11 >= -100.0) && (temporaryMatrix.m11 <= 100.0))
			currentCalculatedMatrix = temporaryMatrix;
	}
	else
	{
	}
	
	GLfloat currentModelViewMatrix[16];
	

	[self convert3DTransform:&currentCalculatedMatrix toMatrix:currentModelViewMatrix];
    
    glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, textureForCubeFace);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
    // Update uniform value
	glUniform1i(uniforms[UNIFORM_TEXTURE], 4);
	glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWMATRIX], 1, 0, currentModelViewMatrix);

    // Update attribute values
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, cubeVertices);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_TEXTUREPOSITION, 2, GL_FLOAT, 0, 0, cubeTexCoords);
	glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITION);

	glDrawArrays(GL_TRIANGLES, 0, 36);

    // The flush is required at the end here to make sure the FBO texture is written to before passing it back to GPUImage
    glFlush();

	newFrameAvailableBlock();
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;

    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);

#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif

    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }

    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;

    glLinkProgram(prog);

#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif

    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;

    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;

    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }

    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;

    return TRUE;
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;

    // Create shader program
    program = glCreateProgram();

    // Create and compile vertex shader
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }

    // Create and compile fragment shader
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }

    // Attach vertex shader to program
    glAttachShader(program, vertShader);

    // Attach fragment shader to program
    glAttachShader(program, fragShader);

    // Bind attribute locations
    // this needs to be done prior to linking
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_TEXTUREPOSITION, "inputTextureCoordinate");

    // Link program
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);

        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }

    // Get uniform locations
    uniforms[UNIFORM_MODELVIEWMATRIX] = glGetUniformLocation(program, "modelViewProjMatrix");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(program, "texture");

    // Release vertex and fragment shaders
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);

    return TRUE;
}

- (void)dealloc
{
    // Tear down GL
    if (defaultFramebuffer)
    {
        glDeleteFramebuffers(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }

    if (colorRenderbuffer)
    {
        glDeleteRenderbuffers(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }

    if (program)
    {
        glDeleteProgram(program);
        program = 0;
    }

    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];

    [context release];
    context = nil;

    [super dealloc];
}

- (void)convert3DTransform:(CATransform3D *)transform3D toMatrix:(GLfloat *)matrix;
{
	//	struct CATransform3D
	//	{
	//		CGFloat m11, m12, m13, m14;
	//		CGFloat m21, m22, m23, m24;
	//		CGFloat m31, m32, m33, m34;
	//		CGFloat m41, m42, m43, m44;
	//	};
	
	matrix[0] = (GLfloat)transform3D->m11;
	matrix[1] = (GLfloat)transform3D->m12;
	matrix[2] = (GLfloat)transform3D->m13;
	matrix[3] = (GLfloat)transform3D->m14;
	matrix[4] = (GLfloat)transform3D->m21;
	matrix[5] = (GLfloat)transform3D->m22;
	matrix[6] = (GLfloat)transform3D->m23;
	matrix[7] = (GLfloat)transform3D->m24;
	matrix[8] = (GLfloat)transform3D->m31;
	matrix[9] = (GLfloat)transform3D->m32;
	matrix[10] = (GLfloat)transform3D->m33;
	matrix[11] = (GLfloat)transform3D->m34;
	matrix[12] = (GLfloat)transform3D->m41;
	matrix[13] = (GLfloat)transform3D->m42;
	matrix[14] = (GLfloat)transform3D->m43;
	matrix[15] = (GLfloat)transform3D->m44;
}

- (void)startCameraCapture;
{
    [videoCamera startCameraCapture];
}

#pragma mark -
#pragma mark GPUImageTextureOutputDelegate delegate method

- (void)newFrameReadyFromTextureOutput:(GPUImageTextureOutput *)callbackTextureOutput;
{
    // Rotation in response to touch events is handled on the main thread, so to be safe we dispatch this on the main queue as well
    // Nominally, I should create a dispatch queue just for the rendering within this application, but not today
    dispatch_async(dispatch_get_main_queue(), ^{
        textureForCubeFace = callbackTextureOutput.texture;
        
        [self renderByRotatingAroundX:0.0 rotatingAroundY:0.0];
    });
}

@end
