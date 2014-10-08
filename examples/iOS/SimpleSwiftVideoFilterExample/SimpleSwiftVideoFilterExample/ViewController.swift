import UIKit
import GPUImage

class ViewController: UIViewController {
    
    var videoCamera:GPUImageVideoCamera?
    var filter:GPUImagePixellateFilter?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
        videoCamera!.outputImageOrientation = .Portrait;
        filter = GPUImagePixellateFilter()
        videoCamera?.addTarget(filter)
        filter?.addTarget(self.view as GPUImageView)
        videoCamera?.startCameraCapture()
    }
}