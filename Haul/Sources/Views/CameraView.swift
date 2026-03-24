import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onCapture = { image in
            onCapture(image)
            dismiss()
        }
        controller.onCancel = {
            dismiss()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var onCapture: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private lazy var captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor(HaulTheme.accent).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()

    private lazy var flashButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        return button
    }()

    private var flashMode: AVCaptureDevice.FlashMode = .auto

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermissionAndSetup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showPermissionDenied()
                    }
                }
            }
        default:
            showPermissionDenied()
        }
    }

    private func showPermissionDenied() {
        let label = UILabel()
        label.text = "Camera access denied.\nEnable in Settings."
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        cancelButton.setTitle("Go Back", for: .normal)
        setupUI()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            return
        }

        photoOutput = AVCapturePhotoOutput()

        if let captureSession = captureSession,
           captureSession.canAddInput(input),
           let photoOutput = photoOutput,
           captureSession.canAddOutput(photoOutput) {

            captureSession.addInput(input)
            captureSession.addOutput(photoOutput)

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds

            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }

            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
        }

        setupUI()
    }

    private func setupUI() {
        view.addSubview(captureButton)
        view.addSubview(cancelButton)
        view.addSubview(flashButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            flashButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }

    @objc private func capturePhoto() {
        guard let photoOutput = photoOutput else { return }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)

        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            self.captureButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.captureButton.transform = .identity
            }
        }
    }

    @objc private func cancel() {
        captureSession?.stopRunning()
        onCancel?()
    }

    @objc private func toggleFlash() {
        switch flashMode {
        case .auto:
            flashMode = .on
            flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
            flashButton.tintColor = .systemYellow
        case .on:
            flashMode = .off
            flashButton.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
            flashButton.tintColor = .white
        default:
            flashMode = .auto
            flashButton.setImage(UIImage(systemName: "bolt.badge.a.fill"), for: .normal)
            flashButton.tintColor = .white
        }
    }
}

extension CameraViewController: @preconcurrency AVCapturePhotoCaptureDelegate {
    @MainActor
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }

        captureSession?.stopRunning()

        // Correct orientation
        let correctedImage = image.fixedOrientation()
        onCapture?(correctedImage)
    }
}

extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}
