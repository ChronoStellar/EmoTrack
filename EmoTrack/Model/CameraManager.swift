import Foundation
import AVFoundation
import CoreML
import Vision
import AppKit

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published var isAuthorized = false
    @Published var errorMessage: String? = nil
    @Published var predictedEmotion: String = "" // Default emotion
    @Published var capturedImage: NSImage? = nil // Store captured image
    private var photoOutput = AVCapturePhotoOutput()
    
    override init() {
        super.init()
    }
    
    func checkAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            await MainActor.run {
                self.isAuthorized = true
            }
            return true
        } else if status == .notDetermined {
            let authorized = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                self.isAuthorized = authorized
            }
            return authorized
        } else {
            await MainActor.run {
                self.errorMessage = "Camera access denied. Please enable it in System Preferences."
            }
            return false
        }
    }
    
    func setUpCaptureSession() async {
        guard await checkAuthorization() else { return }
        do {
            session.sessionPreset = .photo
            guard let device = AVCaptureDevice.default(for: .video) else {
                await MainActor.run {
                    self.errorMessage = "No camera available."
                }
                return
            }
            guard let input = try? AVCaptureDeviceInput(device: device) else {
                await MainActor.run {
                    self.errorMessage = "Failed to create camera input."
                }
                return
            }
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                await MainActor.run {
                    self.errorMessage = "Could not add camera input to session."
                }
                return
            }
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            } else {
                await MainActor.run {
                    self.errorMessage = "Could not add photo output to session."
                }
                return
            }
            await MainActor.run {
                self.isAuthorized = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to set up camera: \(error.localizedDescription)"
            }
        }
    }
    
    func startSession() {
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func clearCapturedImage() {
        DispatchQueue.main.async {
            self.capturedImage = nil
            self.predictedEmotion = "" // Reset emotion
            self.startSession() // Resume camera session
        }
    }
    
    private func predictEmotion(from image: CGImage) async {
        do {
            let model = try fer2013_acc37(configuration: MLModelConfiguration())
            let vnModel = try VNCoreMLModel(for: model.model)
            let request = VNCoreMLRequest(model: vnModel) { request, error in
                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    print("Prediction failed: No results or error: \(error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async {
                        self.predictedEmotion = "Unknown"
                    }
                    return
                }
                print("Raw model output: \(results.map { "\($0.identifier) (\($0.confidence))" })")
                DispatchQueue.main.async {
                    self.predictedEmotion = topResult.identifier
                    print("Updated predictedEmotion: \(self.predictedEmotion)")
                }
            }
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to predict emotion: \(error.localizedDescription)"
                print("Prediction error: \(error.localizedDescription)")
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to capture photo: \(error.localizedDescription)"
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to process captured image."
            }
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = nsImage // Store the captured image
            self.stopSession() // Stop the camera session
        }
        
        Task {
            await predictEmotion(from: cgImage)
        }
    }
}
