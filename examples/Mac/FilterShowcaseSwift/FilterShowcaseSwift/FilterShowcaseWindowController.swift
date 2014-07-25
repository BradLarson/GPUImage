import Cocoa
import GPUImage

class FilterShowcaseWindowController: NSWindowController {

    @IBOutlet var filterView: GPUImageView?

    var enableSlider:Bool = false
    var minimumSliderValue:CGFloat = 0.0, maximumSliderValue:CGFloat = 1.0
    var currentSliderValue:CGFloat = 0.5 {
        willSet(newSliderValue) {
            switch (currentFilterOperation!.sliderConfiguration) {
                case let .Enabled(_, _, _):
                    currentFilterOperation!.updateBasedOnSliderValue(newSliderValue)
                case .Disabled:
                    break
            }
        }
    }
    
    var currentFilterOperation: FilterOperationInterface?
    var videoCamera: GPUImageAVCamera?
    lazy var blendImage: GPUImagePicture = {
        let inputImage = NSImage(named:"Lambeau.jpg")
        return GPUImagePicture(image: inputImage)
    }()
    var currentlySelectedRow = 1

    override func windowDidLoad() {
        super.windowDidLoad()

        videoCamera = GPUImageAVCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraDevice:nil)
        self.changeSelectedRow(0)
    }
    
    func changeSelectedRow(row:Int) {
        if (currentlySelectedRow == row)
        {
            return
        }
        
        // Clean up everything from the previous filter selection first
        videoCamera!.stopCameraCapture()
        videoCamera!.removeAllTargets()
//        blendImage?.removeAllTargets()
        currentFilterOperation?.filter.removeAllTargets()
        
        currentFilterOperation = filterOperations[row]
        switch currentFilterOperation!.filterOperationType {
            case .SingleInput:
                videoCamera!.addTarget((currentFilterOperation!.filter as GPUImageInput))
                currentFilterOperation!.filter.addTarget(filterView!)
            case .Blend:
                videoCamera!.addTarget((currentFilterOperation!.filter as GPUImageInput))
                self.blendImage.addTarget((currentFilterOperation!.filter as GPUImageInput))
                currentFilterOperation!.filter.addTarget(filterView!)
                self.blendImage.processImage()
            case .Custom:
                let setupFunction = currentFilterOperation!.customFilterSetupFunction!
                let inputToFunction:(GPUImageOutput, GPUImageOutput?) = setupFunction(camera:videoCamera!, outputView:filterView!) // Type inference falls down, for now needs this hard cast
                currentFilterOperation!.configureCustomFilter(inputToFunction)
        }
        
        switch currentFilterOperation!.sliderConfiguration {
        case .Disabled:
            enableSlider = false
            //                case let .Enabled(minimumValue, initialValue, maximumValue, filterSliderCallback):
        case let .Enabled(minimumValue, maximumValue, initialValue):
            minimumSliderValue = CGFloat(minimumValue)
            maximumSliderValue = CGFloat(maximumValue)
            enableSlider = true
            currentSliderValue = CGFloat(initialValue)
        }
        
        videoCamera!.startCameraCapture()
    }

// MARK: -
// MARK: Table view delegate and datasource methods
    
    func numberOfRowsInTableView(aTableView:NSTableView!) -> Int {
        return filterOperations.count
    }
    
    func tableView(aTableView:NSTableView!, objectValueForTableColumn aTableColumn:NSTableColumn!, row rowIndex:Int) -> AnyObject! {
        let filterInList:FilterOperationInterface = filterOperations[rowIndex]
        return filterInList.listName
    }
    
    func tableViewSelectionDidChange(aNotification: NSNotification!) {
        let rowIndex = aNotification.object.selectedRow
        self.changeSelectedRow(rowIndex)
    }
}