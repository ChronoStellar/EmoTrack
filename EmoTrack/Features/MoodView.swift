import SwiftUI

struct MoodView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var viewModel: MoodViewModel
    @State private var isCameraActive = false
    
    init() {
        let cameraManager = CameraManager()
        self._cameraManager = StateObject(wrappedValue: cameraManager)
        self._viewModel = StateObject(wrappedValue: MoodViewModel(cameraManager: cameraManager))
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Display predicted emotion with dynamic background color
                Text("Mood: \(viewModel.emotion)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(viewModel.backgroundColor.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top)
                
                // Display captured image or camera feed
                if cameraManager.isAuthorized {
                    if let capturedImage = cameraManager.capturedImage {
                        Image(nsImage: capturedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    } else if isCameraActive {
                        CameraView(session: cameraManager.session)
                            .frame(maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    } else {
                        Image(systemName: "video.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    }
                } else if let errorMessage = cameraManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView("Requesting camera access...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Bottom Bar
                HStack {
                    Button(action: {
                        cameraManager.capturePhoto()
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if cameraManager.capturedImage != nil {
                        Button(action: {
                            cameraManager.clearCapturedImage()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Debug buttons to test emotions
//                    Button(action: {
//                        viewModel.setEmotion("Happy")
//                    }) {
//                        Text("Test Happy")
//                            .padding()
//                            .background(Color.gray)
//                            .foregroundColor(.white)
//                            .clipShape(Capsule())
//                    }
//                    
//                    Button(action: {
//                        viewModel.setEmotion("Angry")
//                    }) {
//                        Text("Test Angry")
//                            .padding()
//                            .background(Color.gray)
//                            .foregroundColor(.white)
//                            .clipShape(Capsule())
//                    }
                }
                .padding()
            }
        }
        .navigationTitle("Mood")
        .task {
            await cameraManager.setUpCaptureSession()
            isCameraActive = true
            cameraManager.startSession()
        }
        .onDisappear {
            isCameraActive = false
            cameraManager.stopSession()
        }
    }
}
