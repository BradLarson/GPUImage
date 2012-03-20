# GPUImage framework #

Brad Larson

http://www.sunsetlakesoftware.com

[@bradlarson](http://twitter.com/bradlarson)

contact@sunsetlakesoftware.com

## Overview ##

The GPUImage framework is a BSD-licensed iOS library that lets you apply GPU-accelerated filters and other effects to images, live camera video, and movies. In comparison to Core Image (part of iOS 5.0), GPUImage allows you to write your own custom filters, supports deployment to iOS 4.0, and has a simpler interface. However, it currently lacks some of the more advanced features of Core Image, such as facial detection.

For massively parallel operations like processing images or live video frames, GPUs have some significant performance advantages over CPUs. On an iPhone 4, a simple image filter can be over 100 times faster to perform on the GPU than an equivalent CPU-based filter.

However, running custom filters on the GPU requires a lot of code to set up and maintain an OpenGL ES 2.0 rendering target for these filters. I created a sample project to do this:

http://www.sunsetlakesoftware.com/2010/10/22/gpu-accelerated-video-processing-mac-and-ios

and found that there was a lot of boilerplate code I had to write in its creation. Therefore, I put together this framework that encapsulates a lot of the common tasks you'll encounter when processing images and video and made it so that you don't need to care about the OpenGL ES 2.0 underpinnings.

In initial benchmarks, this framework significantly outperforms Core Image when handling video, taking only 2.5 ms on an iPhone 4 to upload a frame from the camera, apply a sepia filter, and display, versus 149 ms for the same operation using Core Image. CPU-based processing takes 460 ms, making GPUImage 60X faster than Core Image on this hardware, and 184X faster than CPU-bound processing. On an iPhone 4S, GPUImage is only 13X faster than Core Image, and 102X faster than CPU-bound processing.

## License ##

BSD-style, with the full license available with the framework in License.txt.

## Technical requirements ##

- OpenGL ES 2.0: Applications using this will not run on the original iPhone, iPhone 3G, and 1st and 2nd generation iPod touches
- iOS 4.0 as a deployment target
- iOS 5.0 SDK to build
- Devices must have a camera to use camera-related functionality (obviously)
- The framework uses automatic reference counting (ARC), but should support projects using both ARC and manual reference counting if added as a subproject as explained below. For manual reference counting applications targeting iOS 4.x, you'll need add -fobjc-arc to the Other Linker Flags for your application project.

## General architecture ##

GPUImage uses OpenGL ES 2.0 shaders to perform image and video manipulation much faster than could be done in CPU-bound routines. However, it hides the complexity of interacting with the OpenGL ES API in a simplified Objective-C interface. This interface lets you define input sources for images and video, attach filters in a chain, and send the resulting processed image or video to the screen, to a UIImage, or to a movie on disk.

Images or frames of video are uploaded from source objects, which are subclasses of GPUImageOutput. These include GPUImageVideoCamera (for live video from an iOS camera), GPUImagePicture (for still images), and GPUImageMovie (for movies). Source objects upload still image frames to OpenGL ES as textures, then hand those textures off to the next objects in the processing chain.

Filters and other subsequent elements in the chain conform to the GPUImageInput protocol, which lets them take in the supplied or processed texture from the previous link in the chain and do something with it. Objects one step further down the chain are considered targets, and processing can be branched by adding multiple targets to a single output or filter.

For example, an application that takes in live video from the camera, converts that video to a sepia tone, then displays the video onscreen would set up a chain looking something like the following:

    GPUImageVideoCamera -> GPUImageSepiaFilter -> GPUImageView

## Built-in filters ##

### Color adjustments ###

- **GPUImageBrightnessFilter**: Adjusts the brightness of the image
  - *brightness*: The adjusted brightness (-1.0 - 1.0, with 0.0 as the default)

- **GPUImageExposureFilter**: Adjusts the exposure of the image
  - *exposure*: The adjusted exposure (-10.0 - 10.0, with 0.0 as the default)

- **GPUImageContrastFilter**: Adjusts the contrast of the image
  - *contrast*: The adjusted contrast (0.0 - 4.0, with 1.0 as the default)

- **GPUImageSaturationFilter**: Adjusts the saturation of an image
  - *saturation*: The degree of saturation or desaturation to apply to the image (0.0 - 2.0, with 1.0 as the default)

- **GPUImageGammaFilter**: Adjusts the gamma of an image
  - *gamma*: The gamma adjustment to apply (0.0 - 3.0, with 1.0 as the default)

- **GPUImageColorMatrixFilter**: Transforms the colors of an image by applying a matrix to them
  - *colorMatrix*: A 4x4 matrix used to transform each color in an image
  - *intensity*: The degree to which the new transformed color replaces the original color for each pixel

- **GPUImageColorInvertFilter**: Inverts the colors of an image

- **GPUImageGrayscaleFilter**: Converts an image to grayscale (a slightly faster implementation of the saturation filter, without the ability to vary the color contribution)

- **GPUImageSepiaFilter**: Simple sepia tone filter
  - *intensity*: The degree to which the sepia tone replaces the normal image color (0.0 - 1.0, with 1.0 as the default)

### Image processing ###

- **GPUImageRotationFilter**: This lets you rotate an image left or right by 90 degrees, or flip it horizontally or vertically

- **GPUImageTransformFilter**: This applies an arbitrary 2-D or 3-D transformation to an image
  - *affineTransform*: This takes in a CGAffineTransform to adjust an image in 2-D
  - *transform3D*: This takes in a CATransform3D to manipulate an image in 3-D

- **GPUImageCropFilter**: This crops an image to a specific region, then passes only that region on to the next stage in the filter
  - *cropRegion*: A rectangular area to crop out of the image, normalized to coordinates from 0.0 - 1.0. The (0.0, 0.0) position is in the upper left of the image.

- **GPUImageSharpenFilter**: Sharpens the image
  - *sharpness*: The sharpness adjustment to apply (-4.0 - 4.0, with 0.0 as the default)

- **GPUImageFastBlurFilter**: A hardware-accelerated 9-hit Gaussian blur of an image
  - *blurPasses*: The number of times to re-apply this blur on an image. More passes lead to a blurrier image, yet they require more processing power. The default is 1.

- **GPUImageGaussianBlurFilter**: A more generalized Gaussian blur filter
  - *blurSize*: The fractional area of the image to blur each pixel over

- **GPUImageGaussianSelectiveBlurFilter**: A Gaussian blur that preserves focus within a circular region
  - *blurSize*: The fractional area of the image to blur each pixel over
  - *excludeCircleRadius*: The radius of the circular area being excluded from the blur
  - *excludeCirclePoint*: The center of the circular area being excluded from the blur
  - *excludeBlurSize*: The size of the area between the blurred portion and the clear circle 

### Blending modes ###

- **GPUImageDissolveBlendFilter**: Applies a dissolve blend of two images
  - *mix*: The degree with which the second image overrides the first (0.0 - 1.0, with 0.5 as the default)

- **GPUImageMultiplyBlendFilter**: Applies a multiply blend of two images

- **GPUImageOverlayBlendFilter**: Applies an overlay blend of two images

- **GPUImageDarkenBlendFilter**: Blends two images by taking the minimum value of each color component between the images

- **GPUImageLightenBlendFilter**: Blends two images by taking the maximum value of each color component between the images

- **GPUImageColorBurnBlendFilter**: Applies a color burn blend of two images

- **GPUImageColorDodgeBlendFilter**: Applies a color dodge blend of two images

- **GPUImageScreenBlendFilter**: Applies a screen blend of two images

- **GPUImageExclusionBlendFilter**: Applies an exclusion blend of two images

- **GPUImageDifferenceBlendFilter**: Applies a difference blend of two images

- **GPUImageHardLightBlendFilter**: Applies a hard light blend of two images

- **GPUImageSoftLightBlendFilter**: Applies a soft light blend of two images

### Visual effects ###

- **GPUImagePixellateFilter**: Applies a pixellation effect on an image or video
  - *fractionalWidthOfAPixel*: How large the pixels are, as a fraction of the width and height of the image (0.0 - 1.0, default 0.05)

- **GPUImageSobelEdgeDetectionFilter**: Sobel edge detection, with edges highlighted in white
  - *intensity*: The degree to which the original image colors are replaced by the detected edges (0.0 - 1.0, with 1.0 as the default)
  - *imageWidthFactor*: 
  - *imageHeightFactor*: These parameters affect the visibility of the detected edges

- **GPUImageSketchFilter**: Converts video to look like a sketch. This is just the Sobel edge detection filter with the colors inverted
  - *intensity*: The degree to which the original image colors are replaced by the detected edges (0.0 - 1.0, with 1.0 as the default)
  - *imageWidthFactor*: 
  - *imageHeightFactor*: These parameters affect the visibility of the detected edges

- **GPUImageToonFilter**: This uses Sobel edge detection to place a black border around objects, and then it quantizes the colors present in the image to give a cartoon-like quality to the image.
  - *imageWidthFactor*: 
  - *imageHeightFactor*: These parameters affect the visibility of the detected edges

- **GPUImageSwirlFilter**: Creates a swirl distortion on the image
  - *radius*: The radius from the center to apply the distortion, with a default of 0.5
  - *center*: The center of the image (in normalized coordinates from 0 - 1.0) about which to twist, with a default of (0.5, 0.5)
  - *angle*: The amount of twist to apply to the image, with a default of 1.0

- **GPUImageVignetteFilter**: Performs a vignetting effect, fading out the image at the edges
  - *x*:
  - *y*: The directional intensity of the vignetting, with a default of x = 0.5, y = 0.75

- **GPUImageKuwaharaFilter**: Kuwahara image abstraction, drawn from the work of Kyprianidis, et. al. in their publication "Anisotropic Kuwahara Filtering on the GPU" within the GPU Pro collection. This produces an oil-painting-like image, but it is extremely computationally expensive, so it can take seconds to render a frame on an iPad 2. This might be best used for still images.
  - *radius*: In integer specifying the number of pixels out from the center pixel to test when applying the filter, with a default of 4. A higher value creates a more abstracted image, but at the cost of much greater processing time.


You can also easily write your own custom filters using the C-like OpenGL Shading Language, as described below.

## Adding the framework to your iOS project ##

Once you have the latest source code for the framework, it's fairly straightforward to add it to your application. Start by dragging the GPUImage.xcodeproj file into your application's Xcode project to embed the framework in your project. Next, go to your application's target and add GPUImage as a Target Dependency. Finally, you'll want to drag the libGPUImage.a library from the GPUImage framework's Products folder to the Link Binary With Libraries build phase in your application's target.

GPUImage needs a few other frameworks to be linked into your application, so you'll need to add the following as linked libraries in your application target:

- CoreMedia
- CoreVideo
- OpenGLES
- AVFoundation
- QuartzCore

You'll also need to find the framework headers, so within your project's build settings set the Header Search Paths to the relative path from your application to the framework/ subdirectory within the GPUImage source directory. Make this header search path recursive.

To use the GPUImage classes within your application, simply include the core framework header using the following:

    #import "GPUImage.h"

As a note: if you run into the error "Unknown class GPUImageView in Interface Builder" or the like when trying to build an interface with Interface Builder, you may need to add -ObjC to your Other Linker Flags in your project's build settings.

Additionally, this is an ARC-enabled framework, so if you want to use this within a manual reference counted application targeting iOS 4.x, you'll need to add -fobjc-arc to your Other Linker Flags as well.

## Performing common tasks ##

### Filtering live video ###

To filter live video from an iOS device's camera, you can use code like the following:

	GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
	GPUImageFilter *customFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"CustomShader"];
	GPUImageView *filteredVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, viewWidth, viewHeight)];

	// Add the view somewhere so it's visible

	[videoCamera addTarget:thresholdFilter];
	[customFilter addTarget:filteredVideoView];

	[videoCamera startCameraCapture];

This sets up a video source coming from the iOS device's back-facing camera, using a preset that tries to capture at 640x480. A custom filter, using code from the file CustomShader.fsh, is then set as the target for the video frames from the camera. These filtered video frames are finally displayed onscreen with the help of a UIView subclass that can present the filtered OpenGL ES texture that results from this pipeline.

For blending filters and others that take in more than one image, you can create multiple outputs and add a single filter as a target for both of these outputs. The order with which the outputs are added as targets will affect the order in which the input images are blended or otherwise processed.

### Processing a still image ###

There are a couple of ways to process a still image and create a result. The first way you can do this is by creating a still image source object and manually creating a filter chain:

	UIImage *inputImage = [UIImage imageNamed:@"Lambeau.jpg"];

	GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:inputImage];
	GPUImageSepiaFilter *stillImageFilter = [[GPUImageSepiaFilter alloc] init];

	[stillImageSource addTarget:stillImageFilter];
	[stillImageSource processImage];

	UIImage *currentFilteredVideoFrame = [stillImageFilter imageFromCurrentlyProcessedOutput];

For single filters that you wish to apply to an image, you can simply do the following:

	GPUImageSepiaFilter *stillImageFilter2 = [[GPUImageSepiaFilter alloc] init];
	UIImage *quickFilteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];

### Writing a custom filter ###

One significant advantage of this framework over Core Image on iOS (as of iOS 5.0) is the ability to write your own custom image and video processing filters. These filters are supplied as OpenGL ES 2.0 fragment shaders, written in the C-like OpenGL Shading Language. 

A custom filter is initialized with code like

	GPUImageFilter *customFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"CustomShader"];

where the extension used for the fragment shader is .fsh. Additionally, you can use the -initWithFragmentShaderFromString: initializer to provide the fragment shader as a string, if you would not like to ship your fragment shaders in your application bundle.

Fragment shaders perform their calculations for each pixel to be rendered at that filter stage. They do this using the OpenGL Shading Language (GLSL), a C-like language with additions specific to 2-D and 3-D graphics. An example of a fragment shader is the following sepia-tone filter:

	varying highp vec2 textureCoordinate;

	uniform sampler2D inputImageTexture;

	void main()
	{
	    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
	    lowp vec4 outputColor;
	    outputColor.r = (textureColor.r * 0.393) + (textureColor.g * 0.769) + (textureColor.b * 0.189);
	    outputColor.g = (textureColor.r * 0.349) + (textureColor.g * 0.686) + (textureColor.b * 0.168);    
	    outputColor.b = (textureColor.r * 0.272) + (textureColor.g * 0.534) + (textureColor.b * 0.131);
    
		gl_FragColor = outputColor;
	}

For an image filter to be usable within the GPUImage framework, the first two lines that take in the textureCoordinate varying (for the current coordinate within the texture, normalized to 1.0) and the inputImageTexture uniform (for the actual input image frame texture) are required.

The remainder of the shader grabs the color of the pixel at this location in the passed-in texture, manipulates it in such a way as to produce a sepia tone, and writes that pixel color out to be used in the next stage of the processing pipeline.

One thing to note when adding fragment shaders to your Xcode project is that Xcode thinks they are source code files. To work around this, you'll need to manually move your shader from the Compile Sources build phase to the Copy Bundle Resources one in order to get the shader to be included in your application bundle.


### Filtering and re-encoding a movie ###

Movies can be loaded into the framework via the GPUImageMovie class, filtered, and then written out using a GPUImageMovieWriter. GPUImageMovieWriter is also fast enough to record video in realtime from an iPhone 4's camera at 640x480, so a direct filtered video source can be fed into it.

The following is an example of how you would load a sample movie, pass it through a pixellation and rotation filter, then record the result to disk as a 480 x 640 h.264 movie:

	movieFile = [[GPUImageMovie alloc] initWithURL:sampleURL];
	pixellateFilter = [[GPUImagePixellateFilter alloc] init];
	GPUImageRotationFilter *rotationFilter = [[GPUImageRotationFilter alloc] initWithRotation:kGPUImageRotateRight];

	[movieFile addTarget:rotationFilter];
	[rotationFilter addTarget:pixellateFilter];

	NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
	unlink([pathToMovie UTF8String]);
	NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];

	movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
	[pixellateFilter addTarget:movieWriter];

	[movieWriter startRecording];
	[movieFile startProcessing];

Once recording is finished, you need to remove the movie recorder from the filter chain and close off the recording using code like the following:

	[pixellateFilter removeTarget:movieWriter];
	[movieWriter finishRecording];

A movie won't be usable until it has been finished off, so if this is interrupted before this point, the recording will be lost.

## Sample applications ##

Several sample applications are bundled with the framework source. Most are compatible with both iPhone and iPad-class devices. They attempt to show off various aspects of the framework and should be used as the best examples of the API while the framework is under development. These include:

### SimpleImageFilter ###

A bundled JPEG image is loaded into the application at launch, a filter is applied to it, and the result rendered to the screen. Additionally, this sample shows two ways of taking in an image, filtering it, and saving it to disk.

### SimpleVideoFilter ###

A pixellate filter is applied to a live video stream, with a UISlider control that lets you adjust the pixel size on the live video.

### MultiViewFilterExample ###

From a single camera feed, four views are populated with realtime filters applied to camera. One is just the straight camera video, one is a preprogrammed sepia tone, and two are custom filters based on shader programs.

### FilterShowcase ###

This demonstrates every filter supplied with GPUImage.

### BenchmarkSuite ###

This is used to test the performance of the overall framework by testing it against CPU-bound routines and Core Image. Benchmarks involving still images and video are run against all three, with results displayed in-application.

### ColorObjectTracking ###

A version of my ColorTracking example from http://www.sunsetlakesoftware.com/2010/10/22/gpu-accelerated-video-processing-mac-and-ios ported across to use GPUImage, this application uses color in a scene to track objects from a live camera feed. The four views you can switch between include the raw camera feed, the camera feed with pixels matching the color threshold in white, the processed video where positions are encoded as colors within the pixels passing the threshold test, and finally the live video feed with a dot that tracks the selected color. Tapping the screen changes the color to track to match the color of the pixels under your finger. Tapping and dragging on the screen makes the color threshold more or less forgiving. This is most obvious on the second, color thresholding view.

Currently, all processing for the color averaging in the last step is done on the CPU, so this is part is extremely slow.

## Things that need work ##

- Images that exceed 2048 pixels wide or high currently can't be processed on devices older than the iPad 2 or iPhone 4S.
- Many common filters aren't built into the framework yet.
- Video capture and processing should be done on a background GCD serial queue.
- I'm sure that there are many optimizations that can be made on the rendering pipeline.
- The aspect ratio of the input video is not maintained, but stretched to fill the final image.
