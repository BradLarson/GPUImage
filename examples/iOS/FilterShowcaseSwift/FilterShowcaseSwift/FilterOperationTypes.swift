import Foundation
import GPUImage

// Use of this causes LLVM to faceplant, so have to split out the closures for now
//enum FilterSliderSetting {
//    case Disabled
//    case Enabled(minimumValue:Float, initialValue:Float, maximumValue:Float, sliderUpdateCallback:((filter:GPUImageOutput, sliderValue:Float) -> ())?)
//}

enum FilterSliderSetting {
    case Disabled
    case Enabled(minimumValue:Float, initialValue:Float, maximumValue:Float)
}

// Use of this causes LLVM to faceplant, so have to split out the closures for now
//enum FilterOperationType {
//    case SingleInput
//    case Blend(blendImage:UIImage)
//    case Custom(setupFunction:(camera:GPUImageVideoCamera, outputView:GPUImageView, blendImage:UIImage?) -> (filter:GPUImageOutput))
//}

enum FilterOperationType {
    case SingleInput
    case Blend(blendImage:UIImage)
    case Custom
}

protocol FilterOperationInterface {
    var filter: GPUImageOutput { get }
    var listName: String { get }
    var titleName: String { get }
    var sliderConfiguration: FilterSliderSetting  { get }
    var filterOperationType: FilterOperationType  { get }
    var customFilterSetupFunction: ((camera:GPUImageVideoCamera, outputView:GPUImageView, blendImage:UIImage?) -> (filter:GPUImageOutput))? { get }

    func configureCustomFilter(filter:GPUImageOutput)
    func updateBasedOnSliderValue(sliderValue:Float)
}

class FilterOperation<FilterClass: GPUImageOutput where FilterClass: GPUImageInput>: FilterOperationInterface {
    var internalFilter: FilterClass?
    let listName: String
    let titleName: String
    let sliderConfiguration: FilterSliderSetting
    let filterOperationType: FilterOperationType
    let sliderUpdateCallback: ((filter:FilterClass, sliderValue:Float) -> ())?
    let customFilterSetupFunction: ((camera:GPUImageVideoCamera, outputView:GPUImageView, blendImage:UIImage?) -> (filter:GPUImageOutput))?
    
    init(listName: String, titleName: String, sliderConfiguration: FilterSliderSetting, sliderUpdateCallback:((filter:FilterClass, sliderValue:Float) -> ())?, filterOperationType: FilterOperationType, customFilterSetupFunction:((camera:GPUImageVideoCamera, outputView:GPUImageView, blendImage:UIImage?) -> (filter:GPUImageOutput))?) {
        self.listName = listName
        self.titleName = titleName
        self.sliderConfiguration = sliderConfiguration
        self.filterOperationType = filterOperationType
        self.sliderUpdateCallback = sliderUpdateCallback
        self.customFilterSetupFunction = customFilterSetupFunction
        switch (filterOperationType) {
            case .Custom:
                break
            default:
                self.internalFilter = FilterClass()
        }
        
//        if (!customFilterSetupFunction) {
//            self.internalFilter = FilterClass()
//        }
    }
    
    var filter: GPUImageOutput {
        return internalFilter!
    }

    func configureCustomFilter(filter:GPUImageOutput) {
        self.internalFilter = (filter as FilterClass)
    }

    func updateBasedOnSliderValue(sliderValue:Float) {
        if let updateFunction = sliderUpdateCallback
        {
            updateFunction(filter:internalFilter!, sliderValue:sliderValue)
        }
    }
}