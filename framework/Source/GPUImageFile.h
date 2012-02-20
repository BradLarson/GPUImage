//
//  GPUImageFile.h
//  GPUImage
//
//  Created by Hugues Lismonde on 20/02/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageOutput.h"

@interface GPUImageFile : GPUImageOutput {
  CVPixelBufferRef _currentBuffer;
}

@property (readwrite, retain) NSURL *url;

-(id)initWithURL:(NSURL *)url;
-(void)startProcessing;
-(void)endProcessing;

@end
