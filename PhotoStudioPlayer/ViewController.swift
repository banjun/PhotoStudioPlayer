import Cocoa
import AVFoundation

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var device: AVCaptureDevice? = nil {
        didSet { setupPreviewLayer() }
    }
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true

        NotificationCenter.default.addObserver(forName: AppDelegate.AppGlobalStateDidChange, object: nil, queue: nil) { [weak self] _ in
            self?.readyCaptureFrameIfNeeded()
            self?.changeWindowLevelIfNeeded()
        }

        NotificationCenter.default.addObserver(forName: .AVCaptureSessionRuntimeError, object: nil, queue: nil) { n in
            if n.object as? AVCaptureSession != self.session {
                return
            }
            if let error = n.userInfo?["AVCaptureSessionErrorKey"] as? Error {
                if let window = self.view.window {
                    self.presentError(error, modalFor: window, delegate: self, didPresent: #selector(self.closeWindow(_:)), contextInfo: nil)
                } else {
                    self.presentError(error)
                }
            }
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
            switchToCoolStage(nil)
            self.session = session
            session.startRunning()
        } catch {
            NSLog("%@", "\(error)")
        }
    }

    private var sampleBufferChromaKeyFilter: CIFilter? = nil
    private var numberOfCapturesNeeded = 0
    private let captureFolder = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard numberOfCapturesNeeded > 0 else {
            return
        }
        numberOfCapturesNeeded -= 1

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let image = CIImage(cvImageBuffer: imageBuffer)
        sampleBufferChromaKeyFilter?.setValue(image, forKey: kCIInputImageKey)
        guard let outputImage = sampleBufferChromaKeyFilter?.outputImage else { return }
        let bitmap = NSBitmapImageRep(ciImage: outputImage)
        let png = bitmap.representation(using: .png, properties: [:])
        do {
            try png?.write(to: captureFolder
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

    private func changeWindowLevelIfNeeded() {
        if appDelegate.viewerAboveOtherApps {
            // use .popUpMenu instead of .floating to show on fullscreen app(e.g. Keynote)
            view.window?.level = .popUpMenu
        } else {
            view.window?.level = .normal
        }
    }

    @IBAction func captureCurrentFrame(_ sender: AnyObject?) {
        videoDataQueue.sync {numberOfCapturesNeeded += 1}
    }

    @IBAction func openCaptureFolder(_ sender: AnyObject?) {
        NSWorkspace.shared.open(captureFolder)
    }

    @objc private func closeWindow(_ sender: Any) {
        view.window?.close()
    }

    @objc private func switchToCoolStage(_ sender: AnyObject?) {
        sampleBufferChromaKeyFilter = ChromaKeyFilter.filter(0.15, green: 0.48, blue: 1, threshold: 0.4)
        previewLayer?.filters = [ChromaKeyFilter.filter(0.15, green: 0.48, blue: 1, threshold: 0.4)]
    }

    @objc private func switchToCuteStage(_ sender: AnyObject?) {
        sampleBufferChromaKeyFilter = ChromaKeyFilter.filter(1, green: 3/255.0, blue: 102/255.0, threshold: 0.3)
        previewLayer?.filters = [ChromaKeyFilter.filter(1, green: 3/255.0, blue: 102/255.0, threshold: 0.3)]
    }

    @objc private func switchToPassionStage(_ sender: AnyObject?) {
        sampleBufferChromaKeyFilter = ChromaKeyFilter.filter(251/255.0, green: 179/255.0, blue: 2/255.0, threshold: 0.3)
        previewLayer?.filters = [ChromaKeyFilter.filter(251/255.0, green: 179/255.0, blue: 2/255.0, threshold: 0.3)]
    }
}
