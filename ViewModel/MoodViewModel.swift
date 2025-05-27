import SwiftUI
import Combine

class MoodViewModel: ObservableObject {
    @Published var emotion: String
    private var cancellables = Set<AnyCancellable>()
    
    // Map emotions to background colors (case-insensitive keys)
    private let emotionColors: [String: Color] = [
        "happy": .yellow,
        "angry": .red,
        "disgust": .green,
        "fear": .purple,
        "sad": .blue,
        "surprise": .orange,
        "neutral": .gray,
        "unknown": .gray
    ]
    
    init(cameraManager: CameraManager) {
        self.emotion = cameraManager.predictedEmotion
        // Subscribe to changes in cameraManager.predictedEmotion
        cameraManager.$predictedEmotion
            .sink { [weak self] newEmotion in
                print("MoodViewModel received emotion: \(newEmotion)")
                self?.emotion = newEmotion
            }
            .store(in: &cancellables)
    }
    
    // Get the background color for the current emotion
    var backgroundColor: Color {
        let lowercaseEmotion = emotion.lowercased()
        let color = emotionColors[lowercaseEmotion] ?? .gray
        print("Emotion: \(emotion), Background color: \(color.description)")
        return color
    }
    
    // For debugging: Manually set an emotion
    func setEmotion(_ emotion: String) {
        self.emotion = emotion
        print("Manually set emotion: \(emotion)")
    }
}
