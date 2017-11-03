import Cocoa
import CoreMediaIO
import AVFoundation
import CoreImage

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
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
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let o = AVCaptureVideoDataOutput()
        o.setSampleBufferDelegate(self, queue: videoDataQueue)
        return o
    }()
    private let videoDataQueue = DispatchQueue.global(qos: .userInitiated)
    private var movieOutput: AVCaptureMovieFileOutput?

    private let chromaKeyFilter = ChromaKeyFilter.filter()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        fetchScreenRecordingDevice()
        setupPreviewLayer()

        NotificationCenter.default.addObserver(forName: AppDelegate.AppGlobalStateDidChange, object: nil, queue: nil) { [weak self] _ in
            self?.readyCaptureFrameIfNeeded()
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        guard let layer = view.layer else { return }
        previewLayer?.frame = layer.bounds
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        if let w = view.window {
            w.title = ""
            w.isOpaque = false
            w.backgroundColor = .clear
            w.hasShadow = false
//            w.styleMask = .borderless
//            w.titleVisibility = .visible
            w.isMovableByWindowBackground = true
        }
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
            readyCaptureFrameIfNeeded()

            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            view.layerUsesCoreImageFilters = true
            previewLayer?.filters = [chromaKeyFilter]
            self.session = session
            session.startRunning()
        } catch {
            NSLog("%@", "\(error)")
        }
    }

    private var numberOfCapturesNeeded = 0

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard numberOfCapturesNeeded > 0 else {
            return
        }
        numberOfCapturesNeeded -= 1

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let image = CIImage(cvImageBuffer: imageBuffer)
        let bitmap = NSBitmapImageRep(ciImage: image)
        let png = bitmap.representation(using: .png, properties: [:])
        do {
            try png?.write(to: URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Documents")
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("png"))
        } catch {
            NSLog("%@", "\(error)")
        }
    }

    // as addOutput may slow playback performance, capture readiness should be controllable by user
    private func readyCaptureFrameIfNeeded() {
        if appDelegate.enabledCaptureFrame {
            session?.addOutput(videoDataOutput)
        } else {
            session?.removeOutput(videoDataOutput)
        }
    }

    @IBAction func captureCurrentFrame(_ sender: AnyObject?) {
        videoDataQueue.sync {numberOfCapturesNeeded += 1}
    }
}
