
// TranscriptionView.swift
import SwiftUI
import UIKit
import Speech

struct TranscriptionView: UIViewControllerRepresentable {
    @Binding var fontSize: CGFloat
    @Binding var customName: String
    @ObservedObject var services: SharedServices

    func makeUIViewController(context: Context) -> TranscriptionViewController {
        let controller = TranscriptionViewController(speechService: services.speechService, notificationService: services.notificationService)
        controller.fontSize = fontSize
        controller.customName = customName
        controller.transcriptionLabel.font = UIFont.systemFont(ofSize: fontSize)
        return controller
    }

    func updateUIViewController(_ uiViewController: TranscriptionViewController, context: Context) {
        uiViewController.updateFontSize(fontSize)
        uiViewController.customName = customName
        uiViewController.updateTranscriptionHandler()  // Update the transcription handler to bind new settings
    }
}
