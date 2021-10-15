import Cocoa
import AVFoundation

extension UserDefaults {
    var volume: Float {
        get {object(forKey: "volume") as? Float ?? 0.5}
        set {set(newValue, forKey: "volume")}
    }
}

final class CaptureSession: NSObject, AVCapturePhotoCaptureDelegate {
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

    private lazy var photoOutput: AVCapturePhotoOutput = {
        let o = AVCapturePhotoOutput()
        return o
    }()
    private let captureFolder: URL?
    private var coreImageFilterForCapture: CIFilter?
    var captureEnabled = false {
        didSet {
            if captureEnabled && session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            if !captureEnabled {
                session.removeOutput(photoOutput)
            }
        }
    }
    private var numberOfCapturesNeeded = 0

    func captureCurrentFrame() {
        let settings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]) // populates AVCapturePhoto.pixelBuffer
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func openCaptureFolder() {
        guard let captureFolder = captureFolder else { return }
        NSWorkspace.shared.open(captureFolder)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let captureFolder = captureFolder else { return }
        guard let pixelBuffer = photo.pixelBuffer else { return }
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        coreImageFilterForCapture?.setValue(image, forKey: kCIInputImageKey)
        // TODO: apply rotation when the view is rotated on the ViewController
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
