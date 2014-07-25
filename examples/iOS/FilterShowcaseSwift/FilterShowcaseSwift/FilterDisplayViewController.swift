import UIKit
import GPUImage

class FilterDisplayViewController: UIViewController, UISplitViewControllerDelegate {

    @IBOutlet var filterSlider: UISlider?
    @IBOutlet var filterView: GPUImageView?
    
    let videoCamera: GPUImageVideoCamera
    var blendImage: GPUImagePicture?

    init(coder aDecoder: NSCoder!)
    {
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
        videoCamera.outputImageOrientation = .Portrait;

        super.init(coder: aDecoder)
    }
    
    var filterOperation: FilterOperationInterface? {
        didSet {
            self.configureView()
        }
    }

    func configureView() {
        if let currentFilterConfiguration = self.filterOperation {
            self.title = currentFilterConfiguration.titleName
            
            // Configure the filter chain, ending with the view
            if let view = self.filterView {
                switch currentFilterConfiguration.filterOperationType {
                case .SingleInput:
                    videoCamera.addTarget((currentFilterConfiguration.filter as GPUImageInput))
                    currentFilterConfiguration.filter.addTarget(view)
                case .Blend:
                    videoCamera.addTarget((currentFilterConfiguration.filter as GPUImageInput))
                    let inputImage = UIImage(named:"WID-small.jpg")
                    self.blendImage = GPUImagePicture(image: inputImage)
                    self.blendImage?.addTarget((currentFilterConfiguration.filter as GPUImageInput))
                    self.blendImage?.processImage()
                    currentFilterConfiguration.filter.addTarget(view)
                case .Custom:
                    let setupFunction = currentFilterConfiguration.customFilterSetupFunction!
                    let inputToFunction:(GPUImageOutput, GPUImageOutput?) = setupFunction(camera:videoCamera, outputView:view) // Type inference falls down, for now needs this hard cast
                    currentFilterConfiguration.configureCustomFilter(inputToFunction)
                }
                
                videoCamera.startCameraCapture()
            }

            // Hide or display the slider, based on whether the filter needs it
            if let slider = self.filterSlider {
                switch currentFilterConfiguration.sliderConfiguration {
                case .Disabled:
                    slider.hidden = true
//                case let .Enabled(minimumValue, initialValue, maximumValue, filterSliderCallback):
                case let .Enabled(minimumValue, maximumValue, initialValue):
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
        if let currentFilterConfiguration = self.filterOperation {
            switch (currentFilterConfiguration.sliderConfiguration) {
            case let .Enabled(minimumValue, maximumValue, initialValue):
                currentFilterConfiguration.updateBasedOnSliderValue(CGFloat(self.filterSlider!.value)) // If the UISlider isn't wired up, I want this to throw a runtime exception
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

