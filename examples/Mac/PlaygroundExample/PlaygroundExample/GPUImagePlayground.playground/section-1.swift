import Cocoa
import GPUImage

let sourceImage = NSImage(named: "ChairTest.png")
let filter = GPUImageSobelEdgeDetectionFilter()
let outputImage = filter.imageByFilteringImage(sourceImage)

let customFilter = GPUImageFilter(fragmentShaderFromFile: "CustomFilter")

let outputImage2 = customFilter.imageByFilteringImage(sourceImage)
