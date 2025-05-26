import SwiftUI
import AVFoundation

// Camera Manager to handle authorization and session
class CameraManager: ObservableObject {
    let session = AVCaptureSession()
    @Published var isAuthorized = false
    @Published var errorMessage: String? = nil
    
    func checkAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            isAuthorized = true
            return true
        } else if status == .notDetermined {
            let authorized = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = authorized
            return authorized
        } else {
            errorMessage = "Camera access denied. Please enable it in System Preferences."
            return false
        }
    }
    
    func setUpCaptureSession() async {
        guard await checkAuthorization() else { return }
        do {
            session.sessionPreset = .photo
            guard let device = AVCaptureDevice.default(for: .video) else {
                errorMessage = "No camera available."
                return
            }
            guard let input = try? AVCaptureDeviceInput(device: device) else {
                errorMessage = "Failed to create camera input."
                return
            }
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                errorMessage = "Could not add camera input to session."
                return
            }
            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
            } else {
                errorMessage = "Could not add photo output to session."
                return
            }
            isAuthorized = true
        } catch {
            errorMessage = "Failed to set up camera: \(error.localizedDescription)"
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
}

// Mood View with Camera
struct MoodView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isCameraActive = false
    
    var body: some View {
        VStack {
            if cameraManager.isAuthorized {
                if isCameraActive {
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
                Spacer()
                Button(action: {
                    // Action for taking photo
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Confused")
                    .foregroundColor(.gray)
                Image(systemName: "questionmark")
                    .foregroundColor(.yellow)
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.2))
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

// Camera View Representable
struct CameraView: NSViewRepresentable {
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer = CALayer()
        view.layer?.addSublayer(previewLayer)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update the layer if needed
    }
}

// Main Content View
struct ContentView: View {
    @State private var selectedTab = 0 // Default to Mood View (index 0)
    
    var body: some View {
        NavigationView {
            // Sidebar
            List(selection: $selectedTab) {
                NavigationLink(destination: MoodView()) {
                    Label("Mood", systemImage: "face.smiling")
                }
                .tag(0)
                
                NavigationLink(destination: Text("Journal View")) {
                    Label("Journal", systemImage: "book")
                }
                .tag(1)
                
                NavigationLink(destination: Text("History View")) {
                    Label("History", systemImage: "clock")
                }
                .tag(2)
                
                NavigationLink(destination: Text("Settings View")) {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            
            // Default View (shown before any selection)
            Text("Select an option from the sidebar")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
