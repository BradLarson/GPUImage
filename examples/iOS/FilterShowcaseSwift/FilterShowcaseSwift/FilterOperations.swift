import Foundation
import GPUImage
import QuartzCore

let filterOperations: Array<FilterOperationInterface> = [
    FilterOperation <GPUImageSepiaFilter>(
        listName:"Sepia tone",
        titleName:"Sepia Tone",
        sliderConfiguration:.Enabled(minimumValue:0.0, initialValue:1.0, maximumValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.intensity = CGFloat(sliderValue) // Why do I need to cast this for non-Simulator builds? That seems broken
        },
        filterOperationType:.SingleInput,
        customFilterSetupFunction: nil
    ),
    FilterOperation <GPUImagePixellateFilter>(
        listName:"Pixellate",
        titleName:"Pixellate",
        sliderConfiguration:.Enabled(minimumValue:0.0, initialValue:0.05, maximumValue:0.3),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.fractionalWidthOfAPixel = CGFloat(sliderValue)
        },
        filterOperationType:.SingleInput,
        customFilterSetupFunction: nil
    ),
    FilterOperation <GPUImageColorInvertFilter>(
        listName:"Color invert",
        titleName:"Color Invert",
        sliderConfiguration:.Disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.SingleInput,
        customFilterSetupFunction: nil
    ),
    FilterOperation <GPUImageTransformFilter>(
        listName:"Transform (3-D)",
        titleName:"Transform (3-D)",
        sliderConfiguration:.Enabled(minimumValue:0.0, initialValue:0.75, maximumValue:6.28),
        sliderUpdateCallback:{(filter, sliderValue) in
            var perspectiveTransform = CATransform3DIdentity
            perspectiveTransform.m34 = 0.4
            perspectiveTransform.m33 = 0.4
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75)
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, CGFloat(sliderValue), 0.0, 1.0, 0.0)
            filter.transform3D = perspectiveTransform
        },
        filterOperationType:.SingleInput,
        customFilterSetupFunction: nil
    ),
    FilterOperation <GPUImageSphereRefractionFilter>(
        listName:"Sphere refraction",
        titleName:"Sphere Refraction",
        sliderConfiguration:.Enabled(minimumValue:0.0, initialValue:0.15, maximumValue:1.0),
        sliderUpdateCallback:{(filter, sliderValue) in
            filter.radius = CGFloat(sliderValue)
        },
        filterOperationType:.Custom,
        customFilterSetupFunction:{(camera, outputView, blendImage) in
            let filter = GPUImageSphereRefractionFilter()
            camera.addTarget(filter)
            
            // Provide a blurred image for a cool-looking background
            let gaussianBlur = GPUImageGaussianBlurFilter()
            camera.addTarget(gaussianBlur)
            gaussianBlur.blurRadiusInPixels = 5.0

            let blendFilter = GPUImageAlphaBlendFilter()
            blendFilter.mix = 1.0
            gaussianBlur.addTarget(blendFilter)
            filter.addTarget(blendFilter)
            
            blendFilter.addTarget(outputView)

            return filter
        }
    ),
]

// Corner detector would use this: http://stackoverflow.com/questions/24051395/how-to-go-from-cmutablepointercgfloat-to-cgfloat-in-swift/24414058#24414058
