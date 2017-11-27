//
// Created by zhangyun on 2017/11/27.
// Copyright (c) 2017 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 面向对象的gl program
 */
@interface ZYGLProgram : NSObject
@property (nonatomic, strong) NSString *vertexShaderLog;
@property (nonatomic, strong) NSString *fragShaderLog;
@property (nonatomic, strong) NSString *programLog;

- (instancetype)initWithVertexShaderFile:(NSString *)filePath fragShaderFile:(NSString *)fileP;

- (void)addAttribute:(NSString *)name;
- (GLuint)attributeIndex:(NSString *)name;
- (GLuint)uniformIndex:(NSString *)name;

- (BOOL)link;
- (void)use;
- (BOOL)validate;
@end