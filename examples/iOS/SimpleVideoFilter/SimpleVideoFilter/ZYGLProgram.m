//
// Created by zhangyun on 2017/11/27.
// Copyright (c) 2017 Cell Phone. All rights reserved.
//

#import "ZYGLProgram.h"
#import <OpenGLES/ES2/gl.h>
#import <AVFoundation/AVFoundation.h>

@interface ZYGLProgram()
{
    NSMutableArray *attributesAry,*uniformsAry;
    GLuint programId,vertexShaderId,fragShaderId;
}
@end

@implementation ZYGLProgram

- (instancetype)init{
    if(self = [super init]){
        attributesAry = [NSMutableArray array];
        uniformsAry = [NSMutableArray array];
        programId = vertexShaderId = fragShaderId = 0;
    }
    return self;
}

- (instancetype)initWithVertexShaderFile:(NSString *)filePath fragShaderFile:(NSString *)fileP{
    if(self = [super init]){

        NSString *vertexSource = [NSString stringWithContentsOfFile:filePath];
        NSString *fragSource = [NSString stringWithContentsOfFile:fileP];
        if(vertexSource && fragSource){
            if([self compileShader:&vertexShaderId type:GL_VERTEX_SHADER source:vertexSource]
                    && [self compileShader:&fragShaderId type:GL_FRAGMENT_SHADER source:fragSource]){

                programId = glCreateProgram();
                glAttachShader(programId, vertexShaderId);
                glAttachShader(programId, fragShaderId);
            }
        }
    }
    return self;
}

- (BOOL)link {

    glLinkProgram(programId);
    GLint status;
    glGetProgramiv(programId,GL_LINK_STATUS, &status);
    if(status != GL_TRUE){
        return NO;
    }else{

    }

    return YES;
}

- (BOOL)validate {
    GLint len;
    glGetProgramiv(programId, GL_INFO_LOG_LENGTH, &len);
    if(len > 0){
        GLchar *info = (GLchar *) malloc(sizeof(GLchar) * len);
        glGetProgramInfoLog(programId, len, len, &info);
        self.programLog = [NSString stringWithUTF8String:info];
        free(info);
        return NO;
    }
    return YES;
}

- (void)use{
    glUseProgram(programId);
}


- (GLuint)attributeIndex:(NSString *)name {
    return (GLuint)[attributesAry indexOfObject:name];
}

- (void)addAttribute:(NSString *)name {
    if(!name){
        return;
    }

    if(![attributesAry containsObject:name]){
        [attributesAry addObject:name];
        glBindAttribLocation(programId, [attributesAry indexOfObject:name], [name UTF8String]);
    }
}

- (GLuint)uniformIndex:(NSString *)name {
    return (GLuint)[uniformsAry indexOfObject:name];
}

// 编译shader 代码
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)source{
    const  GLchar *str;
    str = (GLchar *)[source UTF8String];
    if(!str){
        NSLog(@"---shader source failed !");
        return  NO;
    }

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &str, NULL);
    glCompileShader(*shader);
    GLint  status;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if(status != GL_TRUE){
        GLint len;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH,&len);
        if(len > 0){
            GLchar *info = (GLchar *)malloc(sizeof(GLchar) * len);
            glGetShaderInfoLog(*shader, len, &len, info);
            if(type == GL_VERTEX_SHADER){
                self.vertexShaderLog = [NSString stringWithUTF8String:info];
            }else{
                self.fragShaderLog = [NSString stringWithUTF8String:info];
            }
            free(info);
        }

        return NO;
    }
    return YES;
}
@end