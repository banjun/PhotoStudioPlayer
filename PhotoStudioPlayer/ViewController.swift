import Cocoa
import AVFoundation

#if DEBUG
import SwiftHotReload
import Combine
#endif

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate, NSMenuItemValidation {
#if DEBUG
    private var cancellables: Set<AnyCancellable> = []
#endif

    private var session: CaptureSession? {
        didSet {
            oldValue?.previewLayer.removeFromSuperlayer()
            session?.previewLayer.videoGravity = .resizeAspect
            guard let layer = view.layer, let newValue = session?.previewLayer else { return }
            newValue.frame = layer.bounds
            newValue.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            layer.addSublayer(newValue)
        }
    }

    private let rotations: [CGFloat] = [0, -.pi / 2, .pi, +.pi / 2]
    private var rotation: CGFloat = 0 {
        didSet {
            session?.previewLayer.transform = CATransform3DMakeRotation(rotation, 0, 0, 1)
            guard let layer = view.layer else { return }
            session?.previewLayer.frame = layer.bounds
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layerUsesCoreImageFilters = true

        NotificationCenter.default.addObserver(forName: AppDelegate.AppGlobalStateDidChange, object: nil, queue: nil) { [weak self] _ in
            self?.readyCaptureFrameIfNeeded()
            self?.changeWindowLevelIfNeeded()
        }

        NotificationCenter.default.addObserver(forName: .AVCaptureSessionRuntimeError, object: nil, queue: nil) { [weak self] n in
            guard let self = self, n.object as? AVCaptureSession == self.session?.session else { return }
            if let error = n.userInfo?[AVCaptureSessionErrorKey] as? Error {
                if let window = self.view.window {
                    self.presentError(error, modalFor: window, delegate: self, didPresent: #selector(self.closeWindow(_:)), contextInfo: nil)
                } else {
                    self.presentError(error)
                }
            }
        }

        #if DEBUG
        AppDelegate.reloader.$dateReloaded.sink { [weak self] _ in self?.reload() }.store(in: &cancellables)
        #endif
    }

    private func reload() {
        // for AppDelegate.reloader
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        guard let layer = view.layer,
              let previewLayer = session?.previewLayer,
              let window = view.window else {
            view.window?.contentAspectRatio = .zero
            return
        }
        previewLayer.frame = layer.bounds

        let previewSize = previewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1)).applying(.init(rotationAngle: rotation)).size
        let previewRatio = previewSize.height / max(1, previewSize.width)
        let windowRatio = window.contentAspectRatio.height / max(1, window.contentAspectRatio.width)
        // window resize does not work if always set new value
        if abs(windowRatio - previewRatio) >= 0.01 {
            window.contentAspectRatio = previewSize
        }
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

    func setDevice(_ device: AVCaptureDevice) {
        do {
            session = try CaptureSession(inputDevice: device, captureFolder: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents"))
            switchToCoolStage(nil)
            session?.startRunning()
            readyCaptureFrameIfNeeded()
        } catch {
            NSLog("%@", "error during CaptureSession.init: \(String(describing: error))")
        }
    }

    private var sampleBufferChromaKeyFilter: CIFilter? = nil

    // as addOutput may slow playback performance, capture readiness should be controllable by user
    private func readyCaptureFrameIfNeeded() {
        session?.captureEnabled = appDelegate.enabledCaptureFrame
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
        session?.captureCurrentFrame()
    }

    @IBAction func openCaptureFolder(_ sender: AnyObject?) {
        session?.openCaptureFolder()
    }

    @objc private func closeWindow(_ sender: Any) {
        view.window?.close()
    }

    @objc private func switchToCoolStage(_ sender: AnyObject?) {
        session?.setCoreImageFilter(ChromaKeyFilter.filter(0.15, green: 0.48, blue: 1, threshold: 0.4))
    }

    @objc private func switchToCuteStage(_ sender: AnyObject?) {
        session?.setCoreImageFilter(ChromaKeyFilter.filter(1, green: 3/255.0, blue: 102/255.0, threshold: 0.3))
    }
    
    @objc private func switchToPassionStage(_ sender: AnyObject?) {
        session?.setCoreImageFilter(ChromaKeyFilter.filter(251/255.0, green: 179/255.0, blue: 2/255.0, threshold: 0.3))
    }
    
    @IBAction private func switchToRedStage(_ sender: AnyObject?) {
        session?.setCoreImageFilter(ChromaKeyFilter.filter(254/255.0, green: 1/255.0, blue: 0/255.0, threshold: 0.4))
    }
    
    @IBAction private func switchToGreenStage(_ sender: AnyObject?) {
        session?.setCoreImageFilter(ChromaKeyFilter.filter(2/255.0, green: 255/255.0, blue: 0/255.0, threshold: 0.4))
    }
    
    @IBAction private func switchToBlueStage(_ sender: AnyObject?) {
        session?.setCoreImageFilter(ChromaKeyFilter.filter(1/255.0, green: 1/255.0, blue: 253/255.0, threshold: 0.4))
    }

    @IBAction func toggleMuted(_ sender: AnyObject?) {
        session?.muted.toggle()
    }

    @IBAction func rotateLeft(_ sender: AnyObject?) {
        rotation = rotations[((rotations.firstIndex(of: rotation)?.advanced(by: -1) ?? 0) + rotations.count) % rotations.count]
    }

    @IBAction func rotateRight(_ sender: AnyObject?) {
        rotation = rotations[(rotations.firstIndex(of: rotation)?.advanced(by: 1) ?? 0) % rotations.count]
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(toggleMuted(_:)):
            guard let session = session else { return false }
            menuItem.state = session.muted ? .on : .off
            return true
        default:
            return responds(to: menuItem.action)
        }
    }
}
