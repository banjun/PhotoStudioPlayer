import Cocoa
import AVFoundation

extension UserDefaults {
    var volume: Float {
        get {object(forKey: "volume") as? Float ?? 0.5}
        set {set(newValue, forKey: "volume")}
    }
}

final class CaptureSession: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let input: AVCaptureDeviceInput
    let previewLayer: AVCaptureVideoPreviewLayer
    func setCoreImageFilter(_ filter: CIFilter) {
        previewLayer.filters = [filter.copy()].compactMap {$0}
        coreImageFilterForCapture = filter.copy() as? CIFilter
    }

    init(inputDevice: AVCaptureDevice, captureFolder: URL) throws {
        self.input = try AVCaptureDeviceInput(device: inputDevice)
        self.captureFolder = captureFolder
        self.session.addInput(input)
        self.session.addOutput(audioOutput)
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init()
    }

    func startRunning() {
        session.startRunning()
    }

    // MARK: - Audio preview

    private let audioOutput: AVCaptureAudioPreviewOutput = {
        let audioOutput = AVCaptureAudioPreviewOutput()
        audioOutput.volume = UserDefaults.standard.volume
        return audioOutput
    }()
    var muted = false {
        didSet {
            if !muted && session.canAddOutput(audioOutput) {
                session.addOutput(audioOutput)
            }
            if muted {
                session.removeOutput(audioOutput)
            }
        }
    }

    // MARK: - Capture frame screenshots

    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let o = AVCaptureVideoDataOutput()
        o.setSampleBufferDelegate(self, queue: videoDataQueue)
        return o
    }()
    private let videoDataQueue = DispatchQueue.global(qos: .userInitiated)
    private let captureFolder: URL?
    private var coreImageFilterForCapture: CIFilter?
    var captureEnabled = false {
        didSet {
            if captureEnabled && session.canAddOutput(videoDataOutput) {
                session.addOutput(videoDataOutput)
            }
            if !captureEnabled {
                session.removeOutput(videoDataOutput)
            }
        }
    }
    private var numberOfCapturesNeeded = 0

    func captureCurrentFrame() {
        videoDataQueue.sync {numberOfCapturesNeeded += 1}
    }

    func openCaptureFolder() {
        guard let captureFolder = captureFolder else { return }
        NSWorkspace.shared.open(captureFolder)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let captureFolder = captureFolder else { return }
        guard numberOfCapturesNeeded > 0 else { return }
        numberOfCapturesNeeded -= 1

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let image = CIImage(cvImageBuffer: imageBuffer)
        coreImageFilterForCapture?.setValue(image, forKey: kCIInputImageKey)
        guard let outputImage = coreImageFilterForCapture?.outputImage else { return }
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
}
