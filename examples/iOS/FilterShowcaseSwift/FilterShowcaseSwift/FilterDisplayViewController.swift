import UIKit
import GPUImage

class FilterDisplayViewController: UIViewController, UISplitViewControllerDelegate {

    @IBOutlet var filterSlider: UISlider?
    @IBOutlet var filterView: GPUImageView?
    
    let videoCamera: GPUImageVideoCamera
    var filter: GPUImageOutput?
    var blendImage: GPUImagePicture?

    init(coder aDecoder: NSCoder!)
    {
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
        videoCamera.outputImageOrientation = .Portrait;

        super.init(coder: aDecoder)
    }
    
    var filterOperation: FilterOperation? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        if let currentFilter = self.filterOperation {
            self.title = currentFilter.titleName
            
            // Configure the filter chain, ending with the view
            if let view = self.filterView {
                switch currentFilter.filterOperationType {
                case .SingleInput(let filter):
                    self.filter = filter
                    videoCamera.addTarget((self.filter! as GPUImageInput))
                    self.filter?.addTarget(view)
                case .Custom:
                    if let customFilterSetupFunction = currentFilter.customFilterSetupFunction
                    {
                        self.filter = customFilterSetupFunction(camera:videoCamera, outputView:view, blendImage:nil)
                    }
                case .Blend(let filter, let blendImage):
                    self.filter = filter
                    videoCamera.addTarget((self.filter! as GPUImageInput))
                    self.blendImage = GPUImagePicture(image: blendImage)
                    self.blendImage?.addTarget((self.filter! as GPUImageInput))
                    filter.addTarget(view)
                }
                
                videoCamera.startCameraCapture()
            }

            // Hide or display the slider, based on whether the filter needs it
            if let slider = self.filterSlider {
                switch currentFilter.sliderConfiguration {
                case .Disabled:
                    slider.hidden = true
//                case let .Enabled(minimumValue, initialValue, maximumValue, filterSliderCallback):
                case let .Enabled(minimumValue, initialValue, maximumValue):
                    slider.minimumValue = minimumValue
                    slider.maximumValue = maximumValue
                    slider.value = initialValue
                    slider.hidden = false
                    self.updateSliderValue()
                }
            }
            
        }
    }
    
    @IBAction func updateSliderValue() {
        if let currentFilter = self.filterOperation {
            switch (currentFilter.sliderConfiguration) {
            case let .Enabled(minimumValue, initialValue, maximumValue):
                if let sliderUpdateCallback = currentFilter.sliderUpdateCallback
                {
                    if let slider = self.filterSlider {
                        sliderUpdateCallback(filter: self.filter!, sliderValue: slider.value)
                    }
                }
            case .Disabled:
                break
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

