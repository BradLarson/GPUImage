import Foundation
import GPUImage

// Use of this causes LLVM to faceplant, so have to split out the closures for now
//enum FilterSliderSetting {
//    case Disabled
//    case Enabled(minimumValue:Float, initialValue:Float, maximumValue:Float, stringValue:String)
//}

enum FilterSliderSetting {
    case Disabled
    case Enabled(minimumValue:Float, initialValue:Float, maximumValue:Float)
}

// Use of this causes LLVM to faceplant, so have to split out the closures for now
//enum FilterOperationType {
//    case SingleInput(filter:GPUImageOutput)
//    case Blend(filter:GPUImageOutput, blendImage:UIImage)
//    case Custom(setupFunction:(camera:GPUImageVideoCamera, outputView:GPUImageView, blendImage:UIImage?) -> (filter:GPUImageOutput))
//}

enum FilterOperationType {
    case SingleInput(filter:GPUImageOutput)
    case Blend(filter:GPUImageOutput, blendImage:UIImage)
    case Custom
}

class FilterOperation {
    let test:FilterSliderSetting = .Enabled(minimumValue:0.0, initialValue:1.0, maximumValue:1.0)
    let listName: String
    let titleName: String
    let sliderConfiguration: FilterSliderSetting
    let filterOperationType: FilterOperationType
    let sliderUpdateCallback: ((filter:GPUImageOutput, sliderValue:Float) -> ())?
    let customFilterSetupFunction: ((camera:GPUImageVideoCamera, outputView:GPUImageView, blendImage:UIImage?) -> (filter:GPUImageOutput))?
    
    init(listName: String, titleName: String, sliderConfiguration: FilterSliderSetting, sliderUpdateCallback:((filter:GPUImageOutput, sliderValue:Float) -> ())?, filterOperationType: FilterOperationType, customFilterSetupFunction:((camera:GPUImageVideoCamera, outputView:GPUImageView, blendImage:UIImage?) -> (filter:GPUImageOutput))?) {
        self.listName = listName
        self.titleName = titleName
        self.sliderConfiguration = sliderConfiguration
        self.filterOperationType = filterOperationType
        self.sliderUpdateCallback = sliderUpdateCallback
        self.customFilterSetupFunction = customFilterSetupFunction
    }
}