
// TranscriptionView.swift
import SwiftUI
import UIKit

struct TranscriptionView: UIViewControllerRepresentable {
    @Binding var fontSize: CGFloat
    @Binding var customName: String
    @ObservedObject var speechService: SpeechService
    @ObservedObject var notificationService: NotificationService

    func makeUIViewController(context: Context) -> TranscriptionViewController {
        let controller = TranscriptionViewController(speechService: speechService, notificationService: notificationService)
        controller.fontSize = fontSize
        controller.customName = customName
        return controller
    }

    func updateUIViewController(_ uiViewController: TranscriptionViewController, context: Context) {
        uiViewController.updateFontSize(fontSize)
        uiViewController.customName = customName
    }
}
