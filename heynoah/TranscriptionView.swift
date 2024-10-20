


// TranscriptionView.swift
import SwiftUI
import UIKit
import Speech

struct TranscriptionView: UIViewControllerRepresentable {
    @ObservedObject var settingsManager: SettingsManager

    func makeUIViewController(context: Context) -> TranscriptionViewController {
        let controller = TranscriptionViewController(
            speechService: SpeechService(),
            notificationService: NotificationService(),
            settingsManager: settingsManager  // Pass settingsManager to the controller
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: TranscriptionViewController, context: Context) {
        uiViewController.updateAppearance() // Update appearance for dark mode
        uiViewController.updateFontSize(settingsManager.fontSize)  // Update font size based on settingsManager
    }
}
