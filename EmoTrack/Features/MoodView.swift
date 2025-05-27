//
//  MoodView.swift
//  EmoTrack
//
//  Created by Hendrik Nicolas Carlo on 27/05/25.
//

import SwiftUI

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
                
                Text(cameraManager.predictedEmotion)
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
