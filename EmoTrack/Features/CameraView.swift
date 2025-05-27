//
//  CameraView.swift
//  EmoTrack
//
//  Created by Hendrik Nicolas Carlo on 27/05/25.
//
import SwiftUI
import AVFoundation

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
