import Cocoa
import CoreMediaIO
import AVFoundation
import CoreImage

class ViewController: NSViewController {
    private var device: AVCaptureDevice?
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            previewLayer?.videoGravity = .resizeAspect
            guard let layer = view.layer, let newValue = previewLayer else { return }
            newValue.frame = layer.bounds
            newValue.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            layer.addSublayer(newValue)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        fetchScreenRecordingDevice()
        setupPreviewLayer()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        guard let layer = view.layer else { return }
        previewLayer?.frame = layer.bounds
    }

    func fetchScreenRecordingDevice() {
        var prop = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster))
        var allow: UInt32 = 1;
        CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop,
                                  0, nil,
                                  UInt32(MemoryLayout.size(ofValue: allow)), &allow)

        let devices = AVCaptureDevice.devices().filter {$0.hasMediaType(.muxed)}
        NSLog("%@", "devices = \(devices)")
        device = devices.first {$0.hasMediaType(.muxed)}
    }

    func setupPreviewLayer() {
        guard let device = device else { return }
        self.session?.stopRunning()
        let session = AVCaptureSession()

        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            self.session = session
            session.startRunning()
        } catch {
            NSLog("%@", "\(error)")
        }
    }
}
